import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/text_styles.dart';
import '../../shared/widgets/app_bottom_navigation_bar.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({
    super.key,
  }); // UPDATED: Converted to super parameter

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final List<Map<String, dynamic>> notifications = [
    {
      'title': 'Transaction Completed',
      'subtitle': '25 L fuel verified at Shell Station',
      'time': '2h ago',
      'icon': Icons.check_circle_rounded,
      'iconColor': AppColors.success,
      'read': true,
    },
    {
      'title': 'New Session Started',
      'subtitle': 'Fuel transaction initiated',
      'time': '4h ago',
      'icon': Icons.play_circle_filled_rounded,
      'iconColor': AppColors.accentTeal,
      'read': true,
    },
    {
      'title': 'Evidence Upload Pending',
      'subtitle': 'Please verify your fuel receipt',
      'time': 'Yesterday',
      'icon': Icons.image_rounded,
      'iconColor': AppColors.warning,
      'read': false,
    },
    {
      'title': 'Nearby Station Available',
      'subtitle': 'PSO Station is 2km away',
      'time': '3 days ago',
      'icon': Icons.location_on_rounded,
      'iconColor': AppColors.brandNavy,
      'read': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        title: Text(
          'Notifications',
          style: AppTextStyles.sectionHeading.copyWith(fontSize: 24),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              ...notifications.map((notification) {
                return Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.md),
                  child: _buildNotificationTile(notification),
                );
              }), // UPDATED: Removed unnecessary .toList()
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavigationBar(currentIndex: 0),
    );
  }

  Widget _buildNotificationTile(Map<String, dynamic> notification) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: notification['read']
            ? AppColors.white
            : AppColors.accentTeal.withValues(
                alpha: 0.08,
              ), // UPDATED: Replaced withOpacity with withValues
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        border: Border.all(
          color: AppColors.softGray.withValues(alpha: 0.45),
        ), // UPDATED: Replaced withOpacity with withValues
        boxShadow: AppShadows.subtleList,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (notification['iconColor'] as Color).withValues(
                alpha: 0.12,
              ), // UPDATED: Replaced withOpacity with withValues
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              notification['icon'],
              color: notification['iconColor'],
              size: 24,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification['title'], style: AppTextStyles.cardTitle),
                SizedBox(height: AppSpacing.xs),
                Text(notification['subtitle'], style: AppTextStyles.caption),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Text(
            notification['time'],
            style: AppTextStyles.caption.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}
