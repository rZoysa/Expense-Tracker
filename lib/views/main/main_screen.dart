import 'package:expense_tracker/views/expense_dashboard_screen/expense_dashboard_screen.dart';
import 'package:expense_tracker/views/profile/profile_screen.dart';
import 'package:expense_tracker/views/transactions/transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  void _onDestinationSelected(int index) {
    if (_selectedIndex == index) {
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      ExpenseDashboardScreen(
        onViewAllTransactions: () => _onDestinationSelected(1),
      ),
      const TransactionsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, size: 24.r),
            selectedIcon: Icon(Icons.home, size: 24.r),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined, size: 24.r),
            selectedIcon: Icon(Icons.receipt_long, size: 24.r),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, size: 24.r),
            selectedIcon: Icon(Icons.person, size: 24.r),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
