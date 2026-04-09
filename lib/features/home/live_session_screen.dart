import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/text_styles.dart';
import '../../core/models/error_models.dart';
import '../../core/models/session_models.dart';
import '../../core/repositories/session_repository.dart';
import '../../core/services/api_client.dart';
import '../../core/services/token_manager.dart';

class LiveSessionScreen extends StatefulWidget {
  const LiveSessionScreen({super.key});

  @override
  State<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

class _LiveSessionScreenState extends State<LiveSessionScreen> {
  late final SessionRepository _sessionRepository;

  bool _initialized = false;
  String? _sessionId;
  Session? _session;
  Timer? _pollingTimer;
  bool _isLoading = true;
  bool _isClosing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final tokenManager = TokenManager();
    final apiClient = ApiClient(tokenManager: tokenManager);
    _sessionRepository = SessionRepository(apiClient: apiClient);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic> && args['sessionId'] is String) {
      _sessionId = args['sessionId'] as String;
      _fetchSessionData();
    } else {
      setState(() {
        _errorMessage = 'No active session found. Please scan a QR code first.';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchSessionData() async {
    final id = _sessionId;
    if (id == null || id.isEmpty) return;

    try {
      final session = await _sessionRepository.getSession(id);

      if (!mounted) return;

      setState(() {
        _session = session;
        _isLoading = false;
        _errorMessage = null;
      });

      _configurePolling(session);
    } catch (e) {
      if (!mounted) return;

      var message = 'Unable to load session details.';
      if (e is AppError && e.detail != null && e.detail!.trim().isNotEmpty) {
        message = e.detail!;
      }

      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    }
  }

  void _configurePolling(Session session) {
    _pollingTimer?.cancel();
    if (session.status == SessionStatus.active &&
        session.transactionId == null) {
      _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        _fetchSessionData();
      });
    }
  }

  String _formatDateTime(String? iso) {
    if (iso == null || iso.isEmpty) return '--';
    try {
      final date = DateTime.parse(iso).toLocal();
      final h = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final m = date.minute.toString().padLeft(2, '0');
      final ampm = date.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $ampm';
    } catch (_) {
      return '--';
    }
  }

  String _formatElapsed(String? startIso) {
    if (startIso == null || startIso.isEmpty) return '--:--';
    try {
      final start = DateTime.parse(startIso).toLocal();
      final diff = DateTime.now().difference(start);
      final mins = diff.inMinutes.toString().padLeft(2, '0');
      final secs = (diff.inSeconds % 60).toString().padLeft(2, '0');
      return '$mins:$secs';
    } catch (_) {
      return '--:--';
    }
  }

  String _formatExpiry(String? expiryIso) {
    if (expiryIso == null || expiryIso.isEmpty) return '--:--';
    try {
      final expiry = DateTime.parse(expiryIso).toLocal();
      final diff = expiry.difference(DateTime.now());
      if (diff.isNegative) return '0:00';
      final mins = diff.inMinutes;
      final secs = diff.inSeconds % 60;
      return '$mins:${secs.toString().padLeft(2, '0')}';
    } catch (_) {
      return '--:--';
    }
  }

  String _statusLabel(SessionStatus status) {
    switch (status) {
      case SessionStatus.active:
        return 'Active';
      case SessionStatus.completed:
        return 'Completed';
      case SessionStatus.timedOut:
        return 'Timed Out';
      case SessionStatus.cancelled:
        return 'Cancelled';
      case SessionStatus.pending:
        return 'Pending';
    }
  }

  Color _statusColor(SessionStatus status) {
    switch (status) {
      case SessionStatus.active:
        return AppColors.success;
      case SessionStatus.completed:
        return AppColors.success;
      case SessionStatus.timedOut:
        return AppColors.alert;
      case SessionStatus.cancelled:
        return AppColors.secondaryText;
      case SessionStatus.pending:
        return AppColors.warning;
    }
  }

  Future<void> _closeSession() async {
    final id = _sessionId;
    if (id == null || id.isEmpty || _isClosing) return;

    setState(() {
      _isClosing = true;
    });

    try {
      await _sessionRepository.closeSession(sessionId: id, reason: 'manual');
      await _fetchSessionData();

      if (!mounted) return;

      final transactionId = _session?.transactionId;
      if (transactionId != null && transactionId.isNotEmpty) {
        Navigator.of(context).pushReplacementNamed(
          '/transaction-detail',
          arguments: {'transactionId': transactionId},
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Session closed successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      var message = 'Unable to close session. Please try again.';
      if (e is AppError && e.detail != null && e.detail!.trim().isNotEmpty) {
        message = e.detail!;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          _isClosing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Live Session', style: AppTextStyles.sectionHeading),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? _buildErrorState()
              : _buildSessionBody(),
        ),
      ),
    );
  }

  Widget _buildSessionBody() {
    final session = _session!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppBorderRadius.card),
            boxShadow: AppShadows.subtleList,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Session Status',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _statusColor(session.status),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Text(
                        _statusLabel(session.status),
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _statusColor(session.status),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Elapsed',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    _formatElapsed(session.startedAt),
                    style: AppTextStyles.cardTitle.copyWith(
                      color: AppColors.brandNavy,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        Text('Fuel Dispensed', style: AppTextStyles.cardTitle),
        SizedBox(height: AppSpacing.md),
        Container(
          padding: EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppBorderRadius.card),
            boxShadow: AppShadows.subtleList,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Volume',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        '${session.totalLitres.toStringAsFixed(2)} L',
                        style: AppTextStyles.liveDataHero.copyWith(
                          fontSize: 40,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total Cost',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        'PKR ${session.totalAmount.toStringAsFixed(2)}',
                        style: AppTextStyles.liveDataHero.copyWith(
                          fontSize: 32,
                          color: AppColors.accentTeal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.lg),
              LinearProgressIndicator(
                value: session.status == SessionStatus.active ? 1 : 0,
                backgroundColor: AppColors.lightGray,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentTeal),
                minHeight: 6,
              ),
              SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Started at: ${_formatDateTime(session.startedAt)}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                  Text(
                    'Expires in: ${_formatExpiry(session.expiresAt)}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.accentTeal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        Text('Session Information', style: AppTextStyles.cardTitle),
        SizedBox(height: AppSpacing.md),
        Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppBorderRadius.card),
            boxShadow: AppShadows.subtleList,
          ),
          child: Column(
            children: [
              _buildInfoRow('Nozzle ID', session.nozzleId),
              Divider(color: AppColors.softGray, height: AppSpacing.lg),
              _buildInfoRow('Session ID', session.id),
              Divider(color: AppColors.softGray, height: AppSpacing.lg),
              _buildInfoRow(
                'Transaction',
                session.transactionId ?? 'Not generated yet',
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (session.status == SessionStatus.active && !_isClosing)
                ? _closeSession
                : (session.transactionId != null
                      ? () => Navigator.of(context).pushNamed(
                          '/transaction-detail',
                          arguments: {'transactionId': session.transactionId},
                        )
                      : null),
            style: ElevatedButton.styleFrom(
              backgroundColor: session.status == SessionStatus.active
                  ? AppColors.alert
                  : AppColors.accentTeal,
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.button),
              ),
              elevation: 0,
              disabledBackgroundColor: AppColors.softGray,
            ),
            child: Text(
              _isClosing
                  ? 'Ending Session...'
                  : (session.status == SessionStatus.active
                        ? 'End Session'
                        : (session.transactionId != null
                              ? 'View Transaction Detail'
                              : 'Session Closed')),
              style: AppTextStyles.cardTitle.copyWith(color: AppColors.white),
            ),
          ),
        ),
        SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        boxShadow: AppShadows.subtleList,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.alert, size: 36),
          SizedBox(height: AppSpacing.md),
          Text(
            _errorMessage ?? 'Unable to load live session',
            style: AppTextStyles.body,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.md),
          ElevatedButton(
            onPressed: _fetchSessionData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.body.copyWith(color: AppColors.secondaryText),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
        ),
      ],
    );
  }
}
