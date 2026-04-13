import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/text_styles.dart';
import '../../core/models/error_models.dart';
import '../../core/models/transaction_models.dart';
import '../../core/repositories/transaction_repository.dart';
import '../../core/services/api_client.dart';
import '../../core/services/token_manager.dart';

class TransactionDetailScreen extends StatefulWidget {
  const TransactionDetailScreen({super.key});

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late final TransactionRepository _transactionRepository;

  bool _initialized = false;
  bool _isLoading = true;
  String? _errorMessage;
  String? _transactionId;
  Transaction? _transaction;
  bool _isFlagged = false;
  bool _isDownloadingReceipt = false;

  @override
  void initState() {
    super.initState();
    final tokenManager = TokenManager();
    final apiClient = ApiClient(tokenManager: tokenManager);
    _transactionRepository = TransactionRepository(apiClient: apiClient);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic> && args['transactionId'] is String) {
      _transactionId = args['transactionId'] as String;
      _loadTransaction();
    } else {
      setState(() {
        _errorMessage = 'Transaction details unavailable.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTransaction() async {
    final transactionId = _transactionId;
    if (transactionId == null || transactionId.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final transaction = await _transactionRepository.getTransaction(
        transactionId,
      );
      if (!mounted) return;
      setState(() {
        _transaction = transaction;
        _isFlagged = transaction.isFlagged;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      var message = 'Unable to load transaction details.';
      if (e is AppError && e.detail != null && e.detail!.trim().isNotEmpty) {
        message = e.detail!;
      }
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'en_PK',
      symbol: 'PKR ',
      decimalDigits: 2,
    ).format(amount);
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate).toLocal();
      return DateFormat('MMM d, yyyy · h:mm a').format(date);
    } catch (_) {
      return isoDate;
    }
  }

  String _label(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  String _shortId(String value) {
    if (value.length <= 8) return value;
    return value.substring(value.length - 8);
  }

  Color _statusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return AppColors.success;
      case TransactionStatus.pending:
        return AppColors.warning;
      case TransactionStatus.failed:
        return AppColors.alert;
      case TransactionStatus.refunded:
        return AppColors.brandNavy;
    }
  }

  Future<void> _downloadReceipt() async {
    final transaction = _transaction;
    if (transaction == null || _isDownloadingReceipt) return;

    setState(() => _isDownloadingReceipt = true);

    try {
      final bytes = await _transactionRepository.downloadReceipt(transaction.id);
      final dir = await getApplicationDocumentsDirectory();
      final suffix = transaction.id.length > 8
          ? transaction.id.substring(transaction.id.length - 8)
          : transaction.id;
      final file = File('${dir.path}/receipt_$suffix.pdf');
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Receipt saved: receipt_$suffix.pdf'),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to download receipt right now')),
      );
    } finally {
      if (mounted) setState(() => _isDownloadingReceipt = false);
    }
  }

  Future<void> _openFlagSheet() async {
    final transaction = _transaction;
    if (transaction == null) return;

    final reasonController = TextEditingController();
    FraudSeverity selectedSeverity = FraudSeverity.medium;
    bool submitting = false;

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            String severityLabel(FraudSeverity severity) {
              switch (severity) {
                case FraudSeverity.low:
                  return 'Low - Minor discrepancy';
                case FraudSeverity.medium:
                  return 'Medium - Suspicious activity';
                case FraudSeverity.high:
                  return 'High - Clear tampering';
                case FraudSeverity.critical:
                  return 'Critical - Hardware tamper detected';
              }
            }

            return Container(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppBorderRadius.card),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Report Issue', style: AppTextStyles.sectionHeading),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      'Transaction ID: ${transaction.id}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: reasonController,
                      maxLines: 4,
                      minLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Reason',
                        hintText: 'Describe what went wrong...',
                      ),
                    ),
                    SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<FraudSeverity>(
                      initialValue: selectedSeverity,
                      decoration: const InputDecoration(labelText: 'Severity'),
                      items: FraudSeverity.values
                          .map(
                            (severity) => DropdownMenuItem<FraudSeverity>(
                              value: severity,
                              child: Text(severityLabel(severity)),
                            ),
                          )
                          .toList(),
                      onChanged: submitting
                          ? null
                          : (value) {
                              if (value == null) return;
                              setModalState(() {
                                selectedSeverity = value;
                              });
                            },
                    ),
                    SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: submitting
                            ? null
                            : () async {
                                final reason = reasonController.text.trim();
                                if (reason.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter a reason'),
                                    ),
                                  );
                                  return;
                                }

                                setModalState(() {
                                  submitting = true;
                                });

                                try {
                                  await _transactionRepository.flagTransaction(
                                    transactionId: transaction.id,
                                    reason: reason,
                                    severity: selectedSeverity.name,
                                  );
                                  if (!context.mounted) return;
                                  Navigator.pop(context, true);
                                } catch (e) {
                                  if (!context.mounted) return;
                                  final message =
                                      e is AppError &&
                                          e.detail != null &&
                                          e.detail!.trim().isNotEmpty
                                      ? e.detail!
                                      : 'Unable to submit report right now';
                                  setModalState(() {
                                    submitting = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(message)),
                                  );
                                }
                              },
                        child: Text(
                          submitting ? 'Submitting...' : 'Submit Report',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || submitted != true || _isFlagged) return;

    setState(() {
      _isFlagged = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report submitted successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transaction = _transaction;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: AppColors.primaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Transaction Detail', style: AppTextStyles.sectionHeading),
        actions: [
          if (transaction != null && !_isFlagged)
            IconButton(
              onPressed: _openFlagSheet,
              icon: const Icon(Icons.flag_outlined),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!, style: AppTextStyles.body))
          : transaction == null
          ? Center(
              child: Text('Transaction not found', style: AppTextStyles.body),
            )
          : RefreshIndicator(
              onRefresh: _loadTransaction,
              child: ListView(
                padding: EdgeInsets.all(AppSpacing.md),
                children: [
                  if (_isFlagged)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: BorderRadius.circular(
                          AppBorderRadius.card,
                        ),
                      ),
                      child: Text(
                        'You reported this transaction',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  if (_isFlagged) SizedBox(height: AppSpacing.md),
                  Container(
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                transaction.id,
                                style: AppTextStyles.sectionHeading,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: _statusColor(
                                  transaction.status,
                                ).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(
                                  AppBorderRadius.pill,
                                ),
                              ),
                              child: Text(
                                _label(transaction.status.name),
                                style: AppTextStyles.caption.copyWith(
                                  color: _statusColor(transaction.status),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppSpacing.md),
                        _infoRow(
                          'Fuel Type',
                          _label(transaction.fuelType.name),
                        ),
                        _infoRow(
                          'Volume',
                          '${transaction.litresDispensed.toStringAsFixed(1)} L',
                        ),
                        _infoRow(
                          'Price / L',
                          _formatCurrency(transaction.pricePerLitre),
                        ),
                        _infoRow(
                          'Total Amount',
                          _formatCurrency(transaction.totalAmount),
                        ),
                        _infoRow(
                          'Payment Method',
                          _label(transaction.paymentMethod.name),
                        ),
                        _infoRow('Created', _formatDate(transaction.createdAt)),
                        _infoRow(
                          'Vehicle',
                          transaction.vehicleId == null
                              ? 'Not linked'
                              : _shortId(transaction.vehicleId!),
                        ),
                        _infoRow(
                          'Station',
                          transaction.stationId == null
                              ? 'Not linked'
                              : _shortId(transaction.stationId!),
                        ),
                        _infoRow(
                          'Receipt Available',
                          transaction.receiptUrl == null ? 'No' : 'Yes',
                        ),
                        if (transaction.evidenceUrl != null) ...[
                          SizedBox(height: AppSpacing.sm),
                          Text(
                            'Evidence Snapshot',
                            style: AppTextStyles.cardTitle,
                          ),
                          SizedBox(height: AppSpacing.sm),
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (dialogContext) => Dialog(
                                  insetPadding: EdgeInsets.all(AppSpacing.md),
                                  child: InteractiveViewer(
                                    child: Image.network(
                                      transaction.evidenceUrl!,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              height: 240,
                                              color: AppColors.lightGray,
                                              child: const Center(
                                                child: Icon(
                                                  Icons.broken_image_rounded,
                                                ),
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppBorderRadius.card,
                              ),
                              child: Image.network(
                                transaction.evidenceUrl!,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 180,
                                    color: AppColors.lightGray,
                                    child: const Center(
                                      child: Icon(
                                        Icons.image_not_supported_rounded,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),
                  Container(
                    padding: EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppBorderRadius.card),
                      boxShadow: AppShadows.subtleList,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Actions', style: AppTextStyles.cardTitle),
                        SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isDownloadingReceipt ? null : _downloadReceipt,
                            icon: _isDownloadingReceipt
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.download_rounded),
                            label: Text(_isDownloadingReceipt
                                ? 'Downloading...'
                                : 'Download Receipt'),
                          ),
                        ),
                        SizedBox(height: AppSpacing.sm),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isFlagged ? null : _openFlagSheet,
                            icon: const Icon(Icons.flag_outlined),
                            label: Text(
                              _isFlagged ? 'Reported' : 'Report Issue',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.caption),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
