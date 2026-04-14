import 'package:flutter/material.dart';

import '../../shared/widgets/app_bottom_navigation_bar.dart';
import 'ai_chat_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'transaction_history_screen.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _selectTab(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeScreen(),
          TransactionHistoryScreen(),
          AIChatScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: _currentIndex,
        onDestinationSelected: _selectTab,
      ),
    );
  }
}