import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/app_constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex = 0;
  final String userName = 'Ayesha';

  final List<Map<String, dynamic>> recentTransactions = [
    {
      'station': 'Shell Gulberg',
      'date': '2 Apr · 10:30 AM',
      'litres': '25.5 L',
      'amount': 'PKR 5,715',
      'status': 'Verified',
      'icon': Icons.check_circle,
    },
    {
      'station': 'Hascol Wapda Town',
      'date': '1 Apr · 3:15 PM',
      'litres': '30.2 L',
      'amount': 'PKR 6,795',
      'status': 'Verified',
      'icon': Icons.check_circle,
    },
    {
      'station': 'Total Lahore',
      'date': '31 Mar · 9:45 AM',
      'litres': '22.8 L',
      'amount': 'PKR 5,130',
      'status': 'Verified',
      'icon': Icons.check_circle,
    },
  ];

  final List<Map<String, String>> nearbyStations = [
    {'name': 'Shell Defence', 'distance': '2.3 km', 'address': 'Defence'},
    {'name': 'Hascol Gulberg', 'distance': '1.8 km', 'address': 'Gulberg'},
    {'name': 'Total Wapda', 'distance': '3.2 km', 'address': 'Wapda Town'},
    {'name': 'PSO Johar', 'distance': '2.7 km', 'address': 'Johar Town'},
  ];

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  void _onScanTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigate to QR Scan Screen')),
    );
  }

  void _onNavItemTap(int index) {
    setState(() => _selectedNavIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting & Scan Cards in Row - Responsive with 55/45 ratio
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 55,
                        child: _buildGreetingCard(),
                      ),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        flex: 45,
                        child: _buildScanCard(),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.xxl),
                _buildQuickStats(),
                SizedBox(height: AppSpacing.xxl),
                _buildRecentTransactions(),
                SizedBox(height: AppSpacing.xxl),
                _buildNearbyStations(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      backgroundColor: AppColors.white,
      title: const Text(
        'FuelProof',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.brandNavy,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: AppSpacing.md),
          child: IconButton(
            icon: Container(
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primaryBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.notifications_none,
                color: AppColors.brandNavy,
                size: 20,
              ),
            ),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildGreetingCard() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.brandNavy,
            AppColors.brandNavy.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandNavy.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Good ${_getGreeting()}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            userName,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: AppColors.accentTeal,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'Ready to verify your fuel transaction?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.white.withOpacity(0.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanCard() {
    return GestureDetector(
      onTap: _onScanTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.accentTeal,
              AppColors.accentTeal.withOpacity(0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppBorderRadius.card),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentTeal.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            splashColor: Colors.white.withOpacity(0.1),
            onTap: _onScanTap,
            borderRadius: BorderRadius.circular(AppBorderRadius.card),
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: AppSpacing.lg,
                horizontal: AppSpacing.lg,
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.qr_code_2,
                      color: AppColors.white,
                      size: 48,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xl),
                  const Text(
                    'Scan to Start',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'Tap to scan a dispenser QR',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.white.withOpacity(0.95),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('25.5 L', 'Today', AppColors.brandNavy),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildStatCard('3', 'Verified', AppColors.accentTeal),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        border: Border.all(color: AppColors.divider, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryText,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
              ),
            ),
            Text(
              'View all',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.accentTeal,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        Column(
          children: recentTransactions.asMap().entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: _buildTransactionTile(entry.value),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> transaction) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        border: Border.all(color: AppColors.divider.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.accentTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              transaction['icon'],
              color: AppColors.accentTeal,
              size: 20,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction['station'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  transaction['date'],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                transaction['litres'],
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandNavy,
                ),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                transaction['amount'],
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentTeal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyStations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nearby Stations',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryText,
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: nearbyStations.map((station) {
              return Padding(
                padding: EdgeInsets.only(right: AppSpacing.md),
                child: _buildStationCard(station),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStationCard(Map<String, String> station) {
    return Container(
      width: 160,
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        border: Border.all(color: AppColors.divider, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.accentTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppBorderRadius.pill),
            ),
            child: Text(
              station['distance']!,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.accentTeal,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            station['name']!,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            station['address']!,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AppColors.secondaryText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: _onNavItemTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.accentTeal,
        unselectedItemColor: AppColors.secondaryText,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, size: 22),
            activeIcon: Icon(Icons.home, size: 22),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_2, size: 22),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined, size: 22),
            activeIcon: Icon(Icons.receipt_long, size: 22),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, size: 22),
            activeIcon: Icon(Icons.person, size: 22),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
