import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/text_styles.dart';
import '../../shared/widgets/app_bottom_navigation_bar.dart';
import '../../shared/widgets/dashboard_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key}); // UPDATED: Converted to super parameter

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _userName = 'Ayesha';

  void _navigateToScreen(String routeName) {
    Navigator.of(context).pushNamed(routeName);
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              SizedBox(height: AppSpacing.lg),
              Text(
                '${_greeting()}, $_userName',
                style: AppTextStyles.displayHero.copyWith(
                  fontSize: 28,
                  height: 1.0,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              ScanToStartCard(onTap: () => _navigateToScreen('/scan-qr')),
              SizedBox(height: AppSpacing.md),
              _buildSecondaryActions(),
              SizedBox(height: AppSpacing.lg),
              _buildLiveSessionCard(),
              SizedBox(height: AppSpacing.lg),
              _buildRecentActivitySection(),
              SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavigationBar(currentIndex: 0),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'FuelProof',
          style: AppTextStyles.sectionHeading.copyWith(
            fontSize: 24,
            letterSpacing: -1.1,
          ),
        ),
        IconButton(
          onPressed: () => _navigateToScreen('/notifications'),
          icon: Icon(
            Icons.notifications_none_rounded,
            color: AppColors.primaryText,
            size: 30,
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryActions() {
    return Row(
      children: [
        Expanded(
          child: _buildSmallActionCard(
            icon: Icons.location_on_rounded,
            label: 'Find Station',
            onTap: () => _navigateToScreen('/station-finder'),
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildSmallActionCard(
            icon: Icons.receipt_long_rounded,
            label: 'History',
            onTap: () => _navigateToScreen('/transaction-history'),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppBorderRadius.card),
            border: Border.all(
              color: AppColors.softGray.withValues(alpha: 0.45),
            ), // UPDATED: Replaced withOpacity with withValues
            boxShadow: AppShadows.subtleList,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.accentTeal, size: 18),
              SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveSessionCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        border: Border.all(
          color: AppColors.softGray.withValues(alpha: 0.45),
        ), // UPDATED: Replaced withOpacity with withValues
        boxShadow: AppShadows.subtleList,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Active Session', style: AppTextStyles.cardTitle),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _metric('12.5 L', 'Fuel', AppColors.accentTeal),
              SizedBox(width: AppSpacing.md),
              _metric('580 PKR', 'Cost', AppColors.brandNavy),
              SizedBox(width: AppSpacing.md),
              _metric('02:15', 'Time', AppColors.secondaryText),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _navigateToScreen('/live-session'),
              child: Text(
                'View Live Session',
                style: AppTextStyles.cardTitle.copyWith(color: AppColors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String value, String label, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppTextStyles.cardTitle.copyWith(color: color)),
          SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: AppTextStyles.sectionHeading.copyWith(fontSize: 24),
        ),
        SizedBox(height: AppSpacing.md),
        _activityTile(
          station: 'Shell Station',
          detail: '25 L • 1,200 PKR',
          time: '2h ago',
          status: 'Completed',
          statusColor: AppColors.success,
        ),
        SizedBox(height: AppSpacing.md),
        _activityTile(
          station: 'PSO Station',
          detail: '30 L • 1,400 PKR',
          time: 'Yesterday',
          status: 'Pending',
          statusColor: AppColors.warning,
        ),
      ],
    );
  }

  Widget _activityTile({
    required String station,
    required String detail,
    required String time,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        border: Border.all(
          color: AppColors.softGray.withValues(alpha: 0.45),
        ), // UPDATED: Replaced withOpacity with withValues
        boxShadow: AppShadows.subtleList,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(station, style: AppTextStyles.cardTitle),
                SizedBox(height: AppSpacing.xs),
                Text(detail, style: AppTextStyles.caption),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(
                    alpha: 0.12,
                  ), // UPDATED: Replaced withOpacity with withValues
                  borderRadius: BorderRadius.circular(AppBorderRadius.pill),
                ),
                child: Text(
                  status,
                  style: AppTextStyles.caption.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(time, style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}
