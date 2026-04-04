import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/app_constants.dart';

class TransactionSuccessScreen extends StatefulWidget {
  const TransactionSuccessScreen({
    super.key,
  }); // UPDATED: Converted to super parameter

  @override
  State<TransactionSuccessScreen> createState() =>
      _TransactionSuccessScreenState();
}

class _TransactionSuccessScreenState extends State<TransactionSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleAnimationController;
  late AnimationController _checkAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
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
    Future.delayed(Duration(milliseconds: 300), () {
      _checkAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _scaleAnimationController.dispose();
    _checkAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // UPDATED: Replaced WillPopScope with PopScope
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
        body: SingleChildScrollView(
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
                    borderRadius: BorderRadius.circular(AppBorderRadius.card),
                    boxShadow: AppShadows.subtleList,
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        'Transaction ID',
                        'TXN-2024-089452',
                        isHighlight: true,
                      ),
                      Divider(color: AppColors.softGray, height: AppSpacing.lg),
                      _buildDetailRow('Date & Time', '4 Apr 2024, 2:45 PM'),
                      Divider(color: AppColors.softGray, height: AppSpacing.lg),
                      _buildDetailRow('Station', 'Shell - Makati Avenue'),
                      Divider(color: AppColors.softGray, height: AppSpacing.lg),
                      _buildDetailRow('Fuel Type', 'Premium 95 RON'),
                      Divider(color: AppColors.softGray, height: AppSpacing.lg),
                      _buildDetailRow('Volume', '45 Liters'),
                      Divider(color: AppColors.softGray, height: AppSpacing.lg),
                      _buildDetailRow('Price Per Liter', 'â‚±50.00'),
                      Divider(color: AppColors.softGray, height: AppSpacing.lg),
                      _buildDetailRow(
                        'Total Amount',
                        'â‚±2,250.00',
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.lg),
                Container(
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.navyLight,
                    borderRadius: BorderRadius.circular(AppBorderRadius.card),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Payment Breakdown', style: AppTextStyles.cardTitle),
                      SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Subtotal', style: AppTextStyles.body),
                          Text(
                            'â‚±2,250.00',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tax (12%)', style: AppTextStyles.body),
                          Text(
                            'â‚±270.00',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Rewards Applied',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                          Text(
                            '-â‚±50.00',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      Divider(color: AppColors.divider, height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Final Total',
                            style: AppTextStyles.cardTitle.copyWith(
                              color: AppColors.brandNavy,
                            ),
                          ),
                          Text(
                            'â‚±2,470.00',
                            style: AppTextStyles.cardTitle.copyWith(
                              color: AppColors.accentTeal,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.download_rounded),
                    label: Text('Download Receipt'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentTeal,
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
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
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.accentTeal, width: 2),
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
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
        Text(
          value,
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
      ],
    );
  }
}
