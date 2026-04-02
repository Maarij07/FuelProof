import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/constants/spacing.dart';
import '../../shared/widgets/dashboard_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex = 0;

  // Mock user name - TODO: Replace with actual user data from state management
  final String userName = 'Ayesha';

  // Mock recent transactions - TODO: Replace with real data
  final List<Map<String, String>> recentTransactions = [
    {
      'station': 'Shell Gulberg',
      'date': '2 Apr 2026, 10:30 AM',
      'litres': '25.5 L',
      'amount': 'PKR 5,715',
      'status': 'Verified',
      'statusColor': 'success',
    },
    {
      'station': 'Hascol Wapda Town',
      'date': '1 Apr 2026, 3:15 PM',
      'litres': '30.2 L',
      'amount': 'PKR 6,795',
      'status': 'Verified',
      'statusColor': 'success',
    },
    {
      'station': 'Total Lahore',
      'date': '31 Mar 2026, 9:45 AM',
      'litres': '22.8 L',
      'amount': 'PKR 5,130',
      'status': 'Verified',
      'statusColor': 'success',
    },
  ];

  // Mock nearby stations - TODO: Replace with real data
  final List<Map<String, String>> nearbyStations = [
    {
      'name': 'Shell Defence',
      'distance': '2.3 km',
      'address': 'Defence, Lahore',
    },
    {
      'name': 'Hascol Gulberg',
      'distance': '1.8 km',
      'address': 'Gulberg, Lahore',
    },
    {
      'name': 'Total Wapda',
      'distance': '3.2 km',
      'address': 'Wapda Town, Lahore',
    },
    {
      'name': 'PSO Johar',
      'distance': '2.7 km',
      'address': 'Johar Town, Lahore',
    },
  ];

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'success':
        return AppColors.success;
      case 'alert':
        return AppColors.alert;
      default:
        return AppColors.brandNavy;
    }
  }

  void _onScanTap() {
    // TODO: Navigate to QR scan screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigate to QR Scan Screen')),
    );
  }

  void _onNavItemTap(int index) {
    setState(() {
      _selectedNavIndex = index;
    });
    // TODO: Handle navigation to other screens
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: const Text(
          'FuelProof',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.brandNavy,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: IconButton(
              icon: const Icon(
                Icons.notifications_none,
                color: AppColors.primaryText,
              ),
              onPressed: () {
                // TODO: Navigate to notifications
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Section
              Text(
                '${_getGreeting()}, $userName',
                style: AppTextStyles.greetingText,
              ),
              SizedBox(height: AppSpacing.lg),

              // Quick Action - Scan to Start
              ScanToStartCard(onTap: _onScanTap),
              SizedBox(height: AppSpacing.xl),

              // Recent Transactions Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Transactions',
                    style: AppTextStyles.sectionHeading,
                  ),
                  SizedBox(height: AppSpacing.md),
                  if (recentTransactions.isEmpty)
                    SizedBox(
                      height: 200,
                      child: EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'No transactions yet',
                        message: 'Your transaction history will appear here',
                      ),
                    )
                  else
                    Column(
                      children: recentTransactions.map((transaction) {
                        return TransactionCard(
                          station: transaction['station']!,
                          date: transaction['date']!,
                          litres: transaction['litres']!,
                          amount: transaction['amount']!,
                          status: transaction['status']!,
                          statusColor: _getStatusColor(transaction['statusColor']!),
                        );
                      }).toList(),
                    ),
                ],
              ),
              SizedBox(height: AppSpacing.xl),

              // Nearby Stations Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nearby Stations',
                    style: AppTextStyles.sectionHeading,
                  ),
                  SizedBox(height: AppSpacing.md),
                  if (nearbyStations.isEmpty)
                    SizedBox(
                      height: 200,
                      child: EmptyState(
                        icon: Icons.location_off_outlined,
                        title: 'No stations nearby',
                        message: 'Enable location to see nearby stations',
                      ),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: nearbyStations.map((station) {
                          return Padding(
                            padding: EdgeInsets.only(right: AppSpacing.md),
                            child: NearbyStationCard(
                              stationName: station['name']!,
                              distance: station['distance']!,
                              address: station['address']!,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
              SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border(
            top: BorderSide(color: AppColors.divider, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedNavIndex,
          onTap: _onNavItemTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.accentTeal,
          unselectedItemColor: AppColors.secondaryText,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: AppTextStyles.caption.copyWith(
            color: AppColors.accentTeal,
          ),
          unselectedLabelStyle: AppTextStyles.caption.copyWith(
            color: AppColors.secondaryText,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_2),
              label: 'Scan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
