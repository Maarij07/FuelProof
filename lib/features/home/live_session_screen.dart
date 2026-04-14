import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/text_styles.dart';
import '../../core/models/transaction_models.dart';
import '../../core/repositories/transaction_repository.dart';
import '../../core/services/api_client.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/hardware_service.dart';
import '../../core/services/token_manager.dart';
import '../../core/services/transaction_sync_service.dart';

class LiveSessionScreen extends StatefulWidget {
  const LiveSessionScreen({super.key});

  @override
  State<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

class _LiveSessionScreenState extends State<LiveSessionScreen> {
  // ── Dependencies ────────────────────────────────────────────────────────────
  late final ApiClient _apiClient;
  late final TokenManager _tokenManager;
  late final TransactionRepository _transactionRepository;
  HardwareService? _hardware;

  // ── Route args ──────────────────────────────────────────────────────────────
  String? _sessionId;
  String? _nozzleId;

  // ── Init state ──────────────────────────────────────────────────────────────
  bool _initialized = false;
  bool _isInitializing = true;
  bool _backendDataReady = false;
  String _initPhaseLabel = 'Preparing session...';
  String? _initError;

  // ── Live sensor data ─────────────────────────────────────────────────────────
  SensorReading? _lastReading;
  bool _tamperDetected = false;

  // ── Session result ───────────────────────────────────────────────────────────
  bool _isProcessing = false;
  bool _syncPending = false;        // saved locally, sync in progress
  HardwareSessionResult? _result;
  String? _processingError;
  Timer? _wifiSwitchTimer;          // 1-min countdown to WiFi switch prompt
  bool _showWifiSwitchPrompt = false;

  // ── Cached metadata fetched at init ──────────────────────────────────────────
  FuelType _fuelType = FuelType.petrol;
  double _pricePerLitre = 0.0;
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _tokenManager = TokenManager();
    _apiClient = ApiClient(tokenManager: _tokenManager);
    _transactionRepository = TransactionRepository(apiClient: _apiClient);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _sessionId = args['sessionId'] as String?;
      _nozzleId  = args['nozzleId']  as String?;

      // Pre-loaded by wifi_connect_screen Phase 1 (before WiFi switch).
      // If all three are present and valid, skip the backend fetch in Phase 1.
      final userId       = args['userId']       as String?;
      final fuelTypeName = args['fuelType']     as String?;
      final price        = args['pricePerLitre'] as double?;

      if (userId != null && userId.isNotEmpty &&
          fuelTypeName != null && price != null && price > 0) {
        _userId = userId;
        _fuelType = FuelType.values.firstWhere(
          (e) => e.name == fuelTypeName,
          orElse: () => FuelType.petrol,
        );
        _pricePerLitre  = price;
        _backendDataReady = true;
        AppLogger.log(
          'Session',
          'Backend data pre-loaded — skipping Phase 1 '
          '(fuel=${_fuelType.name} price=$_pricePerLitre)',
        );
      }
    }

    if (_sessionId == null || _nozzleId == null) {
      AppLogger.error('Session', 'Missing sessionId or nozzleId in route args');
      setState(() {
        _initError = 'Session data missing. Please scan a QR code again.';
        _isInitializing = false;
      });
      return;
    }

    AppLogger.log('Session', 'Starting — sessionId=$_sessionId nozzleId=$_nozzleId');
    _initialize();
  }

  Future<void> _initialize() async {
    // ── Phase 1: fetch backend data (needs internet, not FuelMonitor WiFi) ────
    // Skipped on retry if data was already fetched successfully.
    if (!_backendDataReady) {
      AppLogger.log('Session', 'Phase 1: fetching backend data');
      if (mounted) setState(() => _initPhaseLabel = 'Preparing session...');
      try {
        final results = await Future.wait([
          _tokenManager.getUserId(),
          _apiClient.get<Map<String, dynamic>>('/nozzles/$_nozzleId'),
          _transactionRepository.getCurrentPrices(),
        ]);

        final userId = results[0] as String?;
        final nozzleData = results[1] as Map<String, dynamic>;
        final prices = results[2] as List<FuelPrice>;

        if (userId == null || userId.isEmpty) {
          throw Exception('User session expired. Please log in again.');
        }

        // Parse fuel type from nozzle data
        final fuelTypeStr = nozzleData['fuel_type'] as String? ?? 'petrol';
        _fuelType = FuelType.values.firstWhere(
          (e) => e.name == fuelTypeStr,
          orElse: () => FuelType.petrol,
        );

        // Find matching price for this fuel type
        final matchingPrice = prices
            .where((p) => p.fuelType == _fuelType)
            .toList();
        _pricePerLitre =
            matchingPrice.isNotEmpty ? matchingPrice.first.pricePerLitre : 0.0;

        // Guard: backend rejects price_per_litre <= 0 with a 422 error.
        if (_pricePerLitre <= 0.0) {
          throw Exception(
            'No fuel price configured for ${_fuelType.name}. '
            'Please contact station management.',
          );
        }

        _userId = userId;
        _backendDataReady = true;
        AppLogger.log(
          'Session',
          'Phase 1 OK — userId=$userId fuel=${_fuelType.name} price=$_pricePerLitre',
        );
      } catch (e) {
        AppLogger.error('Session', 'Phase 1 failed: $e');
        if (mounted) {
          setState(() {
            _initError = e.toString().replaceFirst('Exception: ', '');
            _isInitializing = false;
          });
        }
        return;
      }
    }

    // ── Phase 2: connect to ESP32 device (needs FuelMonitor WiFi) ─────────────
    // Retrying after a device-unreachable error re-enters here directly.
    AppLogger.log('Session', 'Phase 2: connecting to ESP32 at 192.168.4.1');
    if (mounted) setState(() => _initPhaseLabel = 'Connecting to device...');

    // Dispose any previous instance before creating a new one.
    _hardware?.dispose();
    _hardware = HardwareService(
      apiClient: _apiClient,
      sessionId: _sessionId!,
      nozzleId: _nozzleId!,
      userId: _userId,
      fuelType: _fuelType,
      pricePerLitre: _pricePerLitre,
      onReading: _onReading,
      onTamperDetected: _onTamperDetected,
      onComplete: _onComplete,
      onError: _onHardwareError,
    );

    if (mounted) setState(() => _isInitializing = false);

    await _hardware!.start();
  }

  void _onReading(SensorReading reading) {
    if (!mounted) return;
    setState(() {
      _lastReading = reading;
      // When the device signals finished, show the processing indicator
      // immediately. _finalise() in HardwareService is called right after this
      // callback returns, so the spinner is visible during backend calls.
      if (reading.state == DeviceState.finished && _result == null) {
        _isProcessing = true;
      }
    });
  }

  void _onTamperDetected() {
    if (!mounted) return;
    setState(() => _tamperDetected = true);
  }

  void _onComplete(HardwareSessionResult result) {
    if (!mounted) return;

    // Show result immediately (photo + readings are already local).
    setState(() {
      _isProcessing = false;
      _result = result;
      _syncPending = true;
    });

    // Start 1-min timer — after which we prompt the user to switch back.
    _wifiSwitchTimer?.cancel();
    _wifiSwitchTimer = Timer(const Duration(minutes: 1), () {
      if (mounted && _syncPending) {
        setState(() => _showWifiSwitchPrompt = true);
      }
    });

    // Save locally + try to sync immediately (may succeed via mobile data).
    _saveAndSync(result);
  }

  Future<void> _saveAndSync(HardwareSessionResult result) async {
    AppLogger.log('Session', 'Saving to local queue and attempting sync');
    final transactionId = await TransactionSyncService.instance.save(
      sessionId:       _sessionId!,
      nozzleId:        _nozzleId!,
      userId:          _userId,
      fuelType:        _fuelType,
      flowmeterLitres: result.flowmeterLitres,
      dispenserLitres: result.dispenserLitres,
      pricePerLitre:   _pricePerLitre,
      tamperDetected:  result.tamperDetected,
      photo:           result.capturedImage,
    );

    if (!mounted) return;

    if (transactionId != null) {
      // Immediate sync succeeded — update result with backend transaction ID.
      AppLogger.log('Session', 'Sync complete — transactionId=$transactionId');
      _wifiSwitchTimer?.cancel();
      setState(() {
        _syncPending = false;
        _showWifiSwitchPrompt = false;
        _result = result.withSyncResult(
          transactionId: transactionId,
          fraudFlagged: result.tamperDetected ||
              result.discrepancy.abs() > 0.05,
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session recorded successfully.'),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      // Queued for background sync — keep _syncPending = true.
      AppLogger.log('Session', 'Queued for background sync (no internet yet)');
    }
  }

  void _onHardwareError(String error) {
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _processingError = error;
    });
  }

  @override
  void dispose() {
    _wifiSwitchTimer?.cancel();
    _hardware?.dispose();
    super.dispose();
  }

  // ── Computed helpers ─────────────────────────────────────────────────────────

  double get _estimatedCost {
    final r = _lastReading;
    if (r == null || _pricePerLitre == 0) return 0;
    return r.dispenser * _pricePerLitre;
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  // ── Back-button guard ─────────────────────────────────────────────────────────

  Future<bool> _onWillPop() async {
    // Allow back freely when session hasn't started or is fully done.
    final sessionActive = !_isInitializing &&
        _initError == null &&
        _result == null &&
        _lastReading != null;

    if (!sessionActive) return true;

    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave session?'),
        content: const Text(
          'Fuel is still being dispensed. Leaving now will not record this session.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Leave',
              style: TextStyle(color: AppColors.alert),
            ),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        if (await _onWillPop()) nav.pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.primaryBackground,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text('Live Session', style: AppTextStyles.sectionHeading),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppSpacing.md),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isInitializing) {
      return _buildCenteredMessage(
        icon: Icons.sensors,
        label: _initPhaseLabel,
        isLoading: true,
      );
    }

    if (_initError != null) {
      return _buildErrorCard(_initError!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tamper warning — shows instantly when detected
        if (_tamperDetected) ...[
          _buildTamperBanner(),
          SizedBox(height: AppSpacing.md),
        ],

        // Processing error
        if (_processingError != null) ...[
          _buildErrorCard(_processingError!),
          SizedBox(height: AppSpacing.md),
        ],

        // Status chip
        _buildStatusChip(),
        SizedBox(height: AppSpacing.lg),

        // Dual reading cards
        _buildDualReadings(),
        SizedBox(height: AppSpacing.lg),

        // Estimated cost (live, updates every second)
        if (_result == null) _buildEstimatedCost(),

        // Discrepancy result card (after finished)
        if (_result != null) ...[
          _buildDiscrepancyCard(_result!),
          SizedBox(height: AppSpacing.lg),
          if (_result!.capturedImage != null) ...[
            _buildEvidencePhoto(_result!.capturedImage!),
            SizedBox(height: AppSpacing.lg),
          ],
          // Sync status / WiFi prompt
          if (_syncPending) ...[
            _showWifiSwitchPrompt
                ? _buildWifiSwitchPrompt()
                : _buildSyncingBanner(),
            SizedBox(height: AppSpacing.lg),
          ],
          // Primary CTA — always shown once result is available
          if (_result!.transactionId != null)
            _buildViewTransactionButton(_result!.transactionId!)
          else
            _buildGoHomeButton(),
        ],

        if (_isProcessing) ...[
          SizedBox(height: AppSpacing.lg),
          _buildCenteredMessage(
            icon: Icons.sensors_rounded,
            label: 'Capturing session data...',
            isLoading: true,
          ),
        ],

        SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  // ── Sub-widgets ──────────────────────────────────────────────────────────────

  Widget _buildTamperBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Tamper alert detected — dispenser reading may be inflated. '
              'A fraud alert has been sent.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    final reading = _lastReading;
    final result = _result;

    String label;
    Color color;
    IconData icon;

    if (result != null) {
      label = 'Session Complete';
      color = AppColors.success;
      icon = Icons.check_circle_outline_rounded;
    } else if (reading == null || reading.state == DeviceState.idle) {
      label = 'Waiting for flow...';
      color = AppColors.warning;
      icon = Icons.hourglass_empty_rounded;
    } else if (reading.state == DeviceState.running) {
      label = 'Dispensing';
      color = AppColors.accentTeal;
      icon = Icons.local_gas_station_rounded;
    } else {
      label = 'Processing...';
      color = AppColors.accentTeal;
      icon = Icons.sync_rounded;
    }

    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppBorderRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDualReadings() {
    final r = _lastReading;
    final result = _result;

    final flowmeter = result?.flowmeterLitres ?? r?.flowmeter ?? 0.0;
    final dispenser = result?.dispenserLitres ?? r?.dispenser ?? 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildReadingCard(
            label: 'Flowmeter',
            sublabel: 'Actual dispensed',
            value: flowmeter,
            color: AppColors.accentTeal,
            icon: Icons.water_drop_outlined,
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildReadingCard(
            label: 'Dispenser',
            sublabel: 'Station claims',
            value: dispenser,
            color: AppColors.brandNavy,
            icon: Icons.speed_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildReadingCard({
    required String label,
    required String sublabel,
    required double value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        boxShadow: AppShadows.subtleList,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            value.toStringAsFixed(3),
            style: AppTextStyles.liveDataHero.copyWith(
              fontSize: 36,
              color: color,
            ),
          ),
          Text(
            'Litres',
            style: AppTextStyles.caption.copyWith(color: color),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            sublabel,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.secondaryText,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstimatedCost() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        boxShadow: AppShadows.subtleList,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Estimated Cost',
            style: AppTextStyles.body.copyWith(color: AppColors.secondaryText),
          ),
          Text(
            'PKR ${_estimatedCost.toStringAsFixed(2)}',
            style: AppTextStyles.cardTitle.copyWith(
              color: AppColors.brandNavy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscrepancyCard(HardwareSessionResult result) {
    final diff = result.discrepancy;
    final withinTolerance = diff.abs() <= 0.05;

    final Color bgColor;
    final Color borderColor;
    final Color textColor;
    final IconData iconData;
    final String title;
    final String subtitle;

    if (withinTolerance && !result.tamperDetected) {
      bgColor = AppColors.successLight;
      borderColor = AppColors.success.withValues(alpha: 0.4);
      textColor = AppColors.success;
      iconData = Icons.verified_outlined;
      title = 'No discrepancy detected';
      subtitle = 'Readings are within tolerance (±0.05 L).';
    } else {
      bgColor = AppColors.alertLight;
      borderColor = AppColors.alert.withValues(alpha: 0.4);
      textColor = AppColors.alert;
      iconData = Icons.gpp_bad_outlined;
      title = result.tamperDetected ? 'Tamper + Discrepancy' : 'Discrepancy Detected';

      if (diff > 0.05) {
        subtitle =
            'Dispenser over-reported by ${diff.toStringAsFixed(3)} L '
            '(PKR ${(diff * _pricePerLitre).toStringAsFixed(2)} extra).';
      } else if (diff < -0.05) {
        subtitle =
            'Dispenser under-reported by ${(-diff).toStringAsFixed(3)} L.';
      } else {
        subtitle = 'Tamper flag was active during this session.';
      }
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(iconData, color: textColor, size: 22),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.cardTitle.copyWith(color: textColor),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(color: textColor),
                ),
                if (result.fraudFlagged) ...[
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    'Fraud alert filed with station management.',
                    style: AppTextStyles.caption.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidencePhoto(Uint8List bytes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dispenser Snapshot', style: AppTextStyles.cardTitle),
        SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppBorderRadius.card),
          child: Image.memory(
            bytes,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }

  Widget _buildViewTransactionButton(String transactionId) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pushReplacementNamed(
          '/transaction-detail',
          arguments: {'transactionId': transactionId},
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentTeal,
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.button),
          ),
          elevation: 0,
        ),
        child: Text(
          'View Transaction Detail',
          style: AppTextStyles.cardTitle.copyWith(color: AppColors.white),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        boxShadow: AppShadows.subtleList,
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.alert, size: 36),
          SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: AppTextStyles.body,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.md),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _initError = null;
                _processingError = null;
                _isInitializing = true;
              });
              _initialize();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentTeal,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncingBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.accentTeal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        border: Border.all(color: AppColors.accentTeal.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.accentTeal,
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Session saved. Syncing to server...',
              style: AppTextStyles.caption.copyWith(color: AppColors.accentTeal),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWifiSwitchPrompt() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.wifi_off_rounded, color: AppColors.warning, size: 20),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Switch back to mobile data',
                  style: AppTextStyles.cardTitle.copyWith(
                    color: AppColors.warning,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'Session saved locally. Please disconnect from FuelMonitor WiFi — '
                  'the transaction will sync automatically.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoHomeButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentTeal,
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.button),
          ),
          elevation: 0,
        ),
        child: Text(
          'Done',
          style: AppTextStyles.cardTitle.copyWith(color: AppColors.white),
        ),
      ),
    );
  }

  Widget _buildCenteredMessage({
    required IconData icon,
    required String label,
    bool isLoading = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            CircularProgressIndicator(color: AppColors.accentTeal)
          else
            Icon(icon, size: 40, color: AppColors.accentTeal),
          SizedBox(height: AppSpacing.md),
          Text(
            label,
            style: AppTextStyles.body,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
