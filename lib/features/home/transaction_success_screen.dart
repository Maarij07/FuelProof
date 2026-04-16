import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/text_styles.dart';
import '../../core/models/error_models.dart';
import '../../core/models/transaction_models.dart';
import '../../core/repositories/transaction_repository.dart';
import '../../core/state/app_providers.dart';

class TransactionSuccessScreen extends ConsumerStatefulWidget {
  final String? transactionId;

  const TransactionSuccessScreen({super.key, this.transactionId});

  @override
  ConsumerState<TransactionSuccessScreen> createState() =>
      _TransactionSuccessScreenState();
}

class _TransactionSuccessScreenState
    extends ConsumerState<TransactionSuccessScreen>
    with TickerProviderStateMixin {
  late final TransactionRepository _transactionRepository;

  late AnimationController _scaleAnimationController;
  late AnimationController _checkAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  bool _initialized = false;
  bool _isLoading = true;
  bool _isDownloadingReceipt = false;
  String? _errorMessage;
  String? _transactionId;
  Transaction? _transaction;

  @override
  void initState() {
    super.initState();

    _transactionRepository = ref.read(transactionRepositoryProvider);

    _scaleAnimationController = AnimationController(
      duration: AppDurations.long,
      vsync: this,
    );
    _checkAnimationController = AnimationController(
      duration: AppDurations.medium,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _checkAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _scaleAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _checkAnimationController.forward();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    String? routeTransactionId;
    if (routeArgs is Map<String, dynamic>) {
      routeTransactionId = routeArgs['transactionId'] as String?;
    }

    _transactionId = routeTransactionId ?? widget.transactionId;
    _loadTransaction();
  }

  @override
  void dispose() {
    _scaleAnimationController.dispose();
    _checkAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadTransaction() async {
    final id = _transactionId;
    if (id == null || id.isEmpty) {
      setState(() {
        _errorMessage = 'Transaction details are unavailable.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final transaction = await _transactionRepository.getTransaction(id);
      if (!mounted) return;
      setState(() {
        _transaction = transaction;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      var message = 'Unable to load transaction summary.';
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
      return DateFormat('d MMM yyyy, h:mm a').format(date);
    } catch (_) {
      return isoDate;
    }
  }

  String _label(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  String _shortId(String value) {
    if (value.length <= 12) return value;
    return '${value.substring(0, 4)}...${value.substring(value.length - 6)}';
  }

  Future<void> _downloadReceipt() async {
    final transaction = _transaction;
    if (transaction == null || _isDownloadingReceipt) return;

    setState(() {
      _isDownloadingReceipt = true;
    });

    try {
      await _transactionRepository.downloadReceipt(transaction.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt requested successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      var message = 'Unable to download receipt right now.';
      if (e is AppError && e.detail != null && e.detail!.trim().isNotEmpty) {
        message = e.detail!;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadingReceipt = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transaction = _transaction;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.primaryBackground,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            'Transaction Complete',
            style: AppTextStyles.sectionHeading,
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _buildErrorState()
            : transaction == null
            ? _buildErrorState(message: 'Transaction not found')
            : SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      SizedBox(height: AppSpacing.xl),
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.successLight,
                            shape: BoxShape.circle,
                            boxShadow: AppShadows.lightList,
                          ),
                          child: Center(
                            child: ScaleTransition(
                              scale: _checkAnimation,
                              child: Icon(
                                Icons.check_rounded,
                                size: 64,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: AppSpacing.lg),
                      Text(
                        'Transaction Successful!',
                        style: AppTextStyles.displayHero,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        'Your fuel purchase has been completed',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.secondaryText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppSpacing.xl),
                      Container(
                        padding: EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(
                            AppBorderRadius.card,
                          ),
                          boxShadow: AppShadows.subtleList,
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow(
                              'Transaction ID',
                              _shortId(transaction.id),
                              isHighlight: true,
                            ),
                            Divider(
                              color: AppColors.softGray,
                              height: AppSpacing.lg,
                            ),
                            _buildDetailRow(
                              'Date & Time',
                              _formatDate(transaction.createdAt),
                            ),
                            Divider(
                              color: AppColors.softGray,
                              height: AppSpacing.lg,
                            ),
                            _buildDetailRow(
                              'Fuel Type',
                              _label(transaction.fuelType.name),
                            ),
                            Divider(
                              color: AppColors.softGray,
                              height: AppSpacing.lg,
                            ),
                            _buildDetailRow(
                              'Volume',
                              '${transaction.litresDispensed.toStringAsFixed(2)} L',
                            ),
                            Divider(
                              color: AppColors.softGray,
                              height: AppSpacing.lg,
                            ),
                            _buildDetailRow(
                              'Price Per Liter',
                              _formatCurrency(transaction.pricePerLitre),
                            ),
                            Divider(
                              color: AppColors.softGray,
                              height: AppSpacing.lg,
                            ),
                            _buildDetailRow(
                              'Payment Method',
                              _label(transaction.paymentMethod.name),
                            ),
                            Divider(
                              color: AppColors.softGray,
                              height: AppSpacing.lg,
                            ),
                            _buildDetailRow(
                              'Total Amount',
                              _formatCurrency(transaction.totalAmount),
                              isTotal: true,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isDownloadingReceipt
                              ? null
                              : _downloadReceipt,
                          icon: _isDownloadingReceipt
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.download_rounded),
                          label: Text(
                            _isDownloadingReceipt
                                ? 'Downloading...'
                                : 'Download Receipt',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentTeal,
                            padding: EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppBorderRadius.button,
                              ),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(
                            context,
                          ).pushNamedAndRemoveUntil('/home', (_) => false),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: AppColors.accentTeal,
                              width: 2,
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppBorderRadius.button,
                              ),
                            ),
                          ),
                          child: Text(
                            'Done',
                            style: AppTextStyles.cardTitle.copyWith(
                              color: AppColors.accentTeal,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildErrorState({String? message}) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: AppColors.alert, size: 44),
            SizedBox(height: AppSpacing.md),
            Text(
              message ?? _errorMessage ?? 'Unable to load transaction summary',
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
            SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: _loadTransaction,
              child: const Text('Retry'),
            ),
            SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/home', (_) => false),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isHighlight = false,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? AppTextStyles.cardTitle.copyWith(color: AppColors.brandNavy)
              : AppTextStyles.body.copyWith(color: AppColors.secondaryText),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: isTotal
                ? AppTextStyles.cardTitle.copyWith(
                    color: AppColors.accentTeal,
                    fontWeight: FontWeight.w700,
                  )
                : isHighlight
                ? AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentTeal,
                  )
                : AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
          ),
        ),
      ],
    );
  }
}
