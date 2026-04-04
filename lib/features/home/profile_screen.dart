import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/widgets/app_bottom_navigation_bar.dart';
import '../../main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key}); // UPDATED: Converted to super parameter

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = AppThemeController.themeMode.value == ThemeMode.dark;

  void _toggleDarkMode(bool value) {
    setState(() => _darkModeEnabled = value);
    AppThemeController.themeMode.value = value
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      bottomNavigationBar: const AppBottomNavigationBar(currentIndex: 3),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text('Profile', style: AppTextStyles.sectionHeading),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(),
              SizedBox(height: AppSpacing.xl),
              _buildSectionTitle('Overview'),
              SizedBox(height: AppSpacing.md),
              _buildStatsSection(),
              SizedBox(height: AppSpacing.xl),
              _buildSectionTitle('Payment Methods'),
              SizedBox(height: AppSpacing.md),
              _buildPaymentMethod(),
              SizedBox(height: AppSpacing.lg),
              _buildPaymentMethod(isSecondary: true),
              SizedBox(height: AppSpacing.xl),
              _buildSectionTitle('Settings'),
              SizedBox(height: AppSpacing.md),
              _buildSettingItem(
                icon: Icons.notifications_active_rounded,
                title: 'Notifications',
                subtitle: 'Alerts for transactions and reminders',
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                },
              ),
              SizedBox(height: AppSpacing.md),
              _buildSettingItem(
                icon: Icons.dark_mode_rounded,
                title: 'Dark Mode',
                subtitle: 'Use dark appearance throughout the app',
                value: _darkModeEnabled,
                onChanged: _toggleDarkMode,
              ),
              SizedBox(height: AppSpacing.xl),
              _buildSectionTitle('Security'),
              SizedBox(height: AppSpacing.md),
              _buildMenuOption(
                icon: Icons.password_rounded,
                title: 'Change Password',
                subtitle: 'Update your account password securely',
                iconBackgroundColor: AppColors.alertLight,
                iconColor: AppColors.alert,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Change password flow coming soon'),
                      backgroundColor: AppColors.brandNavy,
                    ),
                  );
                },
              ),
              SizedBox(height: AppSpacing.xl),
              _buildSectionTitle('Support & Information'),
              SizedBox(height: AppSpacing.md),
              _buildMenuOption(
                icon: Icons.headset_mic_rounded,
                title: 'Help & Support',
                subtitle: 'Get assistance and contact our support team',
                iconBackgroundColor: AppColors.navyLight,
                iconColor: AppColors.brandNavy,
                onTap: () {},
              ),
              _buildMenuOption(
                icon: Icons.shield_rounded,
                title: 'Privacy Policy',
                subtitle: 'Read how we handle your data',
                iconBackgroundColor: AppColors.successLight,
                iconColor: AppColors.success,
                onTap: () {},
              ),
              _buildMenuOption(
                icon: Icons.menu_book_rounded,
                title: 'Terms & Conditions',
                subtitle: 'Review app terms and usage guidelines',
                iconBackgroundColor: AppColors.warningLight,
                iconColor: AppColors.warning,
                onTap: () {},
              ),
              _buildMenuOption(
                icon: Icons.info_outline_rounded,
                title: 'About FuelProof',
                subtitle: 'Version, licenses, and app information',
                iconBackgroundColor: AppColors.lightGray,
                iconColor: AppColors.tertiaryText,
                onTap: () {},
              ),
              SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showLogoutConfirmation,
                  icon: Icon(Icons.logout_rounded, color: AppColors.white),
                  label: Text(
                    'Logout',
                    style: AppTextStyles.cardTitle.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.alert,
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
              SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        boxShadow: AppShadows.subtleList,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.accentTeal.withValues(alpha: 0.3),
                      AppColors.brandNavy.withValues(alpha: 0.3),
                    ],
                  ),
                  boxShadow: AppShadows.lightList,
                ),
                child: Center(
                  child: Icon(
                    Icons.person_rounded,
                    size: 42,
                    color: AppColors.accentTeal,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'John Doe',
                      style: AppTextStyles.sectionHeading.copyWith(
                        fontSize: 24,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      'john.doe@email.com',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentTeal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(
                          AppBorderRadius.pill,
                        ),
                      ),
                      child: Text(
                        'Gold Member',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.accentTeal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            'Profile Completion',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppBorderRadius.pill),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: 0.78,
              backgroundColor: AppColors.lightGray,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentTeal),
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Member since April 2024 • 78% complete',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.tertiaryText,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentTeal,
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.button),
                ),
              ),
              child: Text(
                'Edit Profile',
                style: AppTextStyles.cardTitle.copyWith(color: AppColors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.45,
      children: [
        _buildStatCard(
          value: '245',
          label: 'Transactions',
          icon: Icons.local_gas_station_rounded,
        ),
        _buildStatCard(
          value: '1,850 L',
          label: 'Fuel Bought',
          icon: Icons.water_drop_rounded,
        ),
        _buildStatCard(
          value: '₱92.5K',
          label: 'Total Spent',
          icon: Icons.payments_rounded,
        ),
        _buildStatCard(
          value: '₱4.2K',
          label: 'Saved This Month',
          icon: Icons.savings_rounded,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.accentTeal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppBorderRadius.small),
            ),
            child: Icon(icon, color: AppColors.accentTeal, size: 18),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTextStyles.sectionHeading.copyWith(
              fontSize: 18,
              color: AppColors.accentTeal,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTextStyles.cardTitle);
  }

  Widget _buildPaymentMethod({bool isSecondary = false}) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        boxShadow: AppShadows.subtleList,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.lightGray,
              borderRadius: BorderRadius.circular(AppBorderRadius.small),
            ),
            child: Icon(
              Icons.credit_card_rounded,
              color: AppColors.accentTeal,
              size: 24,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSecondary ? 'GCash Mobile Wallet' : 'Visa Card',
                  style: AppTextStyles.cardTitle,
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  isSecondary ? 'Mobile payment' : '**** **** **** 4521',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          if (!isSecondary)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.accentTeal.withValues(
                  alpha: 0.1,
                ), // UPDATED: Replaced withOpacity with withValues
                borderRadius: BorderRadius.circular(AppBorderRadius.pill),
              ),
              child: Text(
                'Default',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.accentTeal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        boxShadow: AppShadows.subtleList,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.accentTeal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppBorderRadius.small),
            ),
            child: Icon(icon, color: AppColors.accentTeal, size: 20),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.body),
                SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.accentTeal,
            inactiveThumbColor: AppColors.softGray,
            inactiveTrackColor: AppColors.lightGray,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconBackgroundColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
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
              boxShadow: AppShadows.subtleList,
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    borderRadius: BorderRadius.circular(AppBorderRadius.small),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.body),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.secondaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.tertiaryText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout from FuelProof?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Logging out...'),
                  backgroundColor: AppColors.alert,
                ),
              );
            },
            child: Text('Logout', style: TextStyle(color: AppColors.alert)),
          ),
        ],
      ),
    );
  }
}
