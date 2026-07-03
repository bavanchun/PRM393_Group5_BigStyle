import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/manager/manager_bloc.dart';
import '../../blocs/manager/manager_event.dart';
import '../../config/theme/app_colors.dart';
import '../../widgets/manager_bottom_nav.dart';
import 'manager_dashboard.dart';
import 'manager_orders_screen.dart';
import 'products/manager_product_list_screen.dart';

/// Index of the Orders tab within [_ManagerShellState._screens].
const _ordersTabIndex = 2;

class ManagerShell extends StatefulWidget {
  const ManagerShell({super.key});

  @override
  State<ManagerShell> createState() => _ManagerShellState();
}

class _ManagerShellState extends State<ManagerShell> {
  int _currentIndex = 0;

  final _screens = const [
    ManagerDashboard(),
    ManagerProductListScreen(),
    ManagerOrdersScreen(),
    _ManagerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: ManagerBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          // IndexedStack keeps ManagerOrdersScreen alive after its initial
          // load, so re-fire the load whenever the manager switches back to
          // the Orders tab to pick up any changes made elsewhere.
          if (index == _ordersTabIndex) {
            context.read<ManagerBloc>().add(const ManagerLoadOrders());
          }
        },
      ),
    );
  }
}

class _ManagerProfileScreen extends StatelessWidget {
  const _ManagerProfileScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cá nhân (Quản lý)'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state.user;
          return Column(
            children: [
              const SizedBox(height: 32),
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.secondary,
                child: Text(
                  (user?.fullName.isNotEmpty == true ? user!.fullName[0] : 'M')
                      .toUpperCase(),
                  style: const TextStyle(
                    fontSize: 32,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user?.fullName ?? 'Quản lý',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                user?.email ?? '',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              const Divider(),
              if (user != null)
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.error),
                  title: const Text(
                    'Đăng xuất',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: () {
                    context.read<AuthBloc>().add(const SignOutEvent());
                  },
                )
              else
                ListTile(
                  leading: const Icon(Icons.login, color: AppColors.primary),
                  title: const Text(
                    'Đăng nhập',
                    style: TextStyle(color: AppColors.primary),
                  ),
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
                ),
              const Divider(),
            ],
          );
        },
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
            Icon(
              icon,
              size: 64,
              color: AppColors.textHint.withValues(alpha: 0.5),
            ),
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
