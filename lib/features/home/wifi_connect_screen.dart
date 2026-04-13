import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/text_styles.dart';
import '../../core/models/session_models.dart';
import '../../core/models/transaction_models.dart';
import '../../core/repositories/session_repository.dart';
import '../../core/repositories/transaction_repository.dart';
import '../../core/services/api_client.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/token_manager.dart';

/// Two-phase screen for the WiFi QR flow:
///
/// Phase 1 (internet required — runs immediately on open, before WiFi switch):
///   POST /sessions/start with nozzle_id → get session_id from backend
///
/// Phase 2 (FuelMonitor WiFi required — runs after user switches WiFi):
///   Poll 192.168.4.1/info every 2 s until ESP32 responds →
///   navigate to /live-session
///
/// This split ensures the backend call never runs while the phone is on the
/// FuelMonitor AP (which has no internet).
class WifiConnectScreen extends StatefulWidget {
  const WifiConnectScreen({super.key});

  @override
  State<WifiConnectScreen> createState() => _WifiConnectScreenState();
}

enum _Phase { creatingSession, waitingForWifi, error }

class _WifiConnectScreenState extends State<WifiConnectScreen> {
  static const String _deviceBase   = 'http://192.168.4.1';
  static const String _wifiSsid     = 'FuelMonitor';
  static const String _wifiPassword = '12345678';

  late final Dio                    _deviceDio;
  late final SessionRepository      _sessionRepository;
  late final TransactionRepository  _transactionRepository;
  late final TokenManager           _tokenManager;
  late final ApiClient              _apiClient;

  _Phase  _phase    = _Phase.creatingSession;
  String  _errorMsg = '';

  // Set after phase 1 succeeds
  String?   _sessionId;
  String?   _nozzleId;

  // Backend data fetched in Phase 1 (before WiFi switch) — forwarded to live session
  String    _userId        = '';
  FuelType  _fuelType      = FuelType.petrol;
  double    _pricePerLitre = 0.0;

  Timer? _pollTimer;
  Timer? _pollTimeoutTimer;
  static const Duration _pollTimeout = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    _deviceDio = Dio(
      BaseOptions(
        baseUrl:        _deviceBase,
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 3),
      ),
    );
    _tokenManager = TokenManager();
    _apiClient    = ApiClient(tokenManager: _tokenManager);
    _sessionRepository     = SessionRepository(apiClient: _apiClient);
    _transactionRepository = TransactionRepository(apiClient: _apiClient);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Read nozzle_id from route args and kick off phase 1 immediately.
    // didChangeDependencies fires after initState, once context is available.
    if (_nozzleId == null && _phase == _Phase.creatingSession) {
      final args = ModalRoute.of(context)?.settings.arguments;
      final nozzleId = args is Map<String, dynamic>
          ? args['nozzleId'] as String?
          : null;

      if (nozzleId == null || nozzleId.isEmpty) {
        setState(() {
          _phase    = _Phase.error;
          _errorMsg = 'Nozzle ID missing. Please scan the QR code again.';
        });
        return;
      }

      _nozzleId = nozzleId;
      _createSession(nozzleId);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pollTimeoutTimer?.cancel();
    _deviceDio.close();
    super.dispose();
  }

  // ── Phase 1: create session while still on internet ───────────────────────

  Future<void> _createSession(String nozzleId) async {
    AppLogger.log('WiFi', 'Phase 1: creating session for nozzle=$nozzleId');
    setState(() => _phase = _Phase.creatingSession);

    try {
      // Fetch everything while we still have internet — session creation,
      // nozzle metadata, fuel price, and user ID all run in parallel.
      final results = await Future.wait([
        _sessionRepository.startDeviceSession(nozzleId),
        _tokenManager.getUserId(),
        _apiClient.get<Map<String, dynamic>>('/nozzles/$nozzleId'),
        _transactionRepository.getCurrentPrices(),
      ]);

      final sessionResult = results[0] as SessionScanResponse;
      final userId        = results[1] as String?;
      final nozzleData    = results[2] as Map<String, dynamic>;
      final prices        = results[3] as List<FuelPrice>;

      _sessionId = sessionResult.sessionId;

      // Parse fuel type from nozzle data
      final fuelTypeStr = nozzleData['fuel_type'] as String? ?? 'petrol';
      _fuelType = FuelType.values.firstWhere(
        (e) => e.name == fuelTypeStr,
        orElse: () => FuelType.petrol,
      );

      // Find matching price
      final match = prices.where((p) => p.fuelType == _fuelType).toList();
      _pricePerLitre = match.isNotEmpty ? match.first.pricePerLitre : 0.0;
      _userId        = userId ?? '';

      AppLogger.log(
        'WiFi',
        'Session created: ${sessionResult.sessionId} — '
        'fuel=${_fuelType.name} price=$_pricePerLitre — now waiting for WiFi',
      );

      if (!mounted) return;
      setState(() => _phase = _Phase.waitingForWifi);
      _startPolling();
    } catch (e) {
      AppLogger.error('WiFi', 'Session creation failed: $e');
      if (!mounted) return;
      setState(() {
        _phase    = _Phase.error;
        _errorMsg = 'Could not create session. Check your internet and try again.';
      });
    }
  }

  // ── Phase 2: poll ESP32 until reachable ───────────────────────────────────

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimeoutTimer?.cancel();

    _pollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _checkDevice(),
    );
    _checkDevice();

    // Give up after 5 minutes — device probably isn't on or WiFi wasn't switched.
    _pollTimeoutTimer = Timer(_pollTimeout, () {
      if (!mounted) return;
      _pollTimer?.cancel();
      setState(() {
        _phase    = _Phase.error;
        _errorMsg =
            'Could not detect the device after 5 minutes.\n'
            'Make sure the phone is connected to the FuelMonitor WiFi and '
            'the device is powered on, then try again.';
      });
    });
  }

  Future<void> _checkDevice() async {
    try {
      AppLogger.debug('WiFi', 'Polling 192.168.4.1/info …');
      await _deviceDio.get<Map<String, dynamic>>('/info');
      // Any successful response means the phone is on FuelMonitor WiFi.
      _pollTimer?.cancel();
      _pollTimeoutTimer?.cancel();
      AppLogger.log('WiFi', 'ESP32 reachable — navigating to live session');

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        '/live-session',
        arguments: {
          'sessionId':    _sessionId!,
          'nozzleId':     _nozzleId!,
          // Pre-loaded during Phase 1 (while internet was available).
          // live_session_screen uses these to skip its own backend fetch.
          'userId':       _userId,
          'fuelType':     _fuelType.name,
          'pricePerLitre': _pricePerLitre,
        },
      );
    } catch (_) {
      AppLogger.debug('WiFi', 'Device not reachable yet');
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Connect to Device', style: AppTextStyles.sectionHeading),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case _Phase.creatingSession:
        return _buildPhase1();
      case _Phase.waitingForWifi:
        return _buildPhase2();
      case _Phase.error:
        return _buildError();
    }
  }

  Widget _buildPhase1() {
    return Column(
      children: [
        SizedBox(height: AppSpacing.xl),
        _iconCircle(Icons.cloud_sync_rounded),
        SizedBox(height: AppSpacing.lg),
        Text('Preparing Session', style: AppTextStyles.sectionHeading, textAlign: TextAlign.center),
        SizedBox(height: AppSpacing.md),
        Text(
          'Setting up your fueling session on the server…',
          style: AppTextStyles.body.copyWith(color: AppColors.secondaryText),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppSpacing.xl),
        CircularProgressIndicator(color: AppColors.accentTeal),
      ],
    );
  }

  Widget _buildPhase2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: AppSpacing.xl),
        _iconCircle(Icons.wifi_rounded),
        SizedBox(height: AppSpacing.lg),
        Text(
          'Connect to FuelMonitor WiFi',
          style: AppTextStyles.sectionHeading,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppSpacing.md),
        Text(
          'Open your phone\'s WiFi settings and connect to the network below. '
          'The session will start automatically once connected.',
          style: AppTextStyles.body.copyWith(color: AppColors.secondaryText),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppSpacing.xl),

        // Credentials card
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppBorderRadius.card),
            boxShadow: AppShadows.subtleList,
          ),
          child: Column(
            children: [
              _credentialRow(Icons.wifi_rounded, 'Network Name', _wifiSsid),
              Divider(height: AppSpacing.lg),
              _credentialRow(Icons.lock_outline_rounded, 'Password', _wifiPassword),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.xl),

        // Waiting indicator
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.accentTeal.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppBorderRadius.card),
            border: Border.all(color: AppColors.accentTeal.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.accentTeal,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Waiting for device connection…',
                  style: AppTextStyles.caption.copyWith(color: AppColors.accentTeal),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      children: [
        SizedBox(height: AppSpacing.xl),
        Icon(Icons.error_outline_rounded, color: AppColors.alert, size: 48),
        SizedBox(height: AppSpacing.lg),
        Text(_errorMsg, style: AppTextStyles.body, textAlign: TextAlign.center),
        SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _nozzleId != null
                ? () => _createSession(_nozzleId!)
                : () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentTeal,
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.button),
              ),
              elevation: 0,
            ),
            child: Text(
              _nozzleId != null ? 'Retry' : 'Go Back',
              style: AppTextStyles.cardTitle.copyWith(color: AppColors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _iconCircle(IconData icon) {
    return Container(
      width: 80, height: 80,
      decoration: BoxDecoration(
        color: AppColors.accentTeal.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.accentTeal, size: 40),
    );
  }

  Widget _credentialRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accentTeal, size: 20),
        SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.secondaryText)),
            Text(value,  style: AppTextStyles.cardTitle.copyWith(color: AppColors.primaryText)),
          ],
        ),
      ],
    );
  }
}
