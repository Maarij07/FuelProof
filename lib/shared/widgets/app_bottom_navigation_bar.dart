import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

class AppBottomNavigationBar extends StatelessWidget {
  const AppBottomNavigationBar({super.key, required this.currentIndex});

  final int currentIndex;

  static const List<String> _routes = [
    '/home',
    '/transaction-history',
    '/ai-chat',
    '/profile',
  ];

  void _handleDestinationSelected(BuildContext context, int index) {
    if (index == currentIndex) return;

    Navigator.of(context).pushReplacementNamed(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      left: false,
      right: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF111827) : AppColors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF2A364A)
                  : AppColors.divider.withValues(
                      alpha: 0.7,
                    ), // UPDATED: Replaced withOpacity with withValues
            ),
            boxShadow: AppShadows.cardList,
          ),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: Colors.transparent,
              indicatorColor: AppColors.tealLight,
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                // UPDATED: Replaced MaterialStateProperty with WidgetStateProperty
                final selected = states.contains(
                  WidgetState.selected,
                ); // UPDATED: Replaced MaterialState with WidgetState
                return TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? AppColors.accentTeal
                      : AppColors.secondaryText,
                );
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                // UPDATED: Replaced MaterialStateProperty with WidgetStateProperty
                final selected = states.contains(
                  WidgetState.selected,
                ); // UPDATED: Replaced MaterialState with WidgetState
                return IconThemeData(
                  color: selected
                      ? AppColors.accentTeal
                      : AppColors.tertiaryText,
                  size: AppDimensions.iconNavigationSize,
                );
              }),
            ),
            child: NavigationBar(
              height: 72,
              selectedIndex: currentIndex,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              backgroundColor: Colors.transparent,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              onDestinationSelected: (index) =>
                  _handleDestinationSelected(context, index),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long_rounded),
                  label: 'History',
                ),
                NavigationDestination(
                  icon: Icon(Icons.chat_bubble_outline_rounded),
                  selectedIcon: Icon(Icons.chat_bubble_rounded),
                  label: 'Support',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
