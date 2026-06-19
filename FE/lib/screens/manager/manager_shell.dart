import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../widgets/manager_bottom_nav.dart';
import 'manager_dashboard.dart';
import 'manager_orders_screen.dart';

class ManagerShell extends StatefulWidget {
  const ManagerShell({super.key});

  @override
  State<ManagerShell> createState() => _ManagerShellState();
}

class _ManagerShellState extends State<ManagerShell> {
  int _currentIndex = 0;

  final _screens = const [
    ManagerDashboard(),
    _PlaceholderScreen(title: 'Quản lý sản phẩm', icon: Icons.inventory_2),
    ManagerOrdersScreen(),
    _PlaceholderScreen(title: 'Cá nhân', icon: Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: ManagerBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PlaceholderScreen({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.textHint.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'Tính năng đang phát triển',
              style: TextStyle(color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }
}
