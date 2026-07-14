import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/manager/manager_bloc.dart';
import '../../blocs/manager/manager_event.dart';
import '../../blocs/notification/notification_bloc.dart';
import '../../blocs/notification/notification_event.dart';
import '../../blocs/notification/notification_state.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthBloc>().state.user?.id;
      if (userId != null) {
        context.read<NotificationBloc>().add(NotificationLoad(userId));
      }
    });
  }

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
          if (index == _ordersTabIndex) {
            context.read<ManagerBloc>().add(const ManagerLoadOrders());
          }
          final userId = context.read<AuthBloc>().state.user?.id;
          if (userId != null) {
            context.read<NotificationBloc>().add(NotificationLoad(userId));
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
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state.user;
          return Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.onPrimary.withValues(alpha: 0.2),
                      child: user?.avatarUrl != null
                          ? ClipOval(
                              child: Image.network(user!.avatarUrl!,
                                  width: 56, height: 56, fit: BoxFit.cover))
                          : Text(
                              (user?.fullName.isNotEmpty == true
                                  ? user!.fullName[0]
                                  : 'M'),
                              style: const TextStyle(
                                  color: AppColors.onPrimary,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700),
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'Quản lý',
                            style: const TextStyle(
                              color: AppColors.onPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? '',
                            style: TextStyle(
                              color: AppColors.onPrimary.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                          ),
                          if (user?.brandName != null &&
                              user!.brandName!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.store,
                                    size: 12,
                                    color: AppColors.onPrimary.withValues(alpha: 0.8)),
                                const SizedBox(width: 4),
                                Text(
                                  user.brandName!,
                                  style: TextStyle(
                                    color: AppColors.onPrimary.withValues(alpha: 0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    BlocBuilder<NotificationBloc, NotificationState>(
                      builder: (context, notifState) {
                        return IconButton(
                          icon: Badge(
                            isLabelVisible: notifState.unreadCount > 0,
                            label: notifState.unreadCount > 99
                                ? const Text('99+')
                                : Text('${notifState.unreadCount}'),
                            backgroundColor: AppColors.error,
                            textColor: Colors.white,
                            textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                            child: const Icon(Icons.notifications_outlined,
                                color: AppColors.onPrimary, size: 20),
                          ),
                          onPressed: () =>
                              Navigator.pushNamed(context, '/notifications'),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          color: AppColors.onPrimary, size: 20),
                      onPressed: () =>
                          Navigator.pushNamed(context, '/edit-profile'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Menu
              _ProfileMenuItem(
                icon: Icons.edit_outlined,
                title: 'Chỉnh sửa hồ sơ',
                onTap: () => Navigator.pushNamed(context, '/edit-profile'),
              ),
              const Divider(indent: 16, endIndent: 16),
              if (user != null)
                _ProfileMenuItem(
                  icon: Icons.logout,
                  title: 'Đăng xuất',
                  color: AppColors.error,
                  onTap: () {
                    context.read<AuthBloc>().add(const SignOutEvent());
                  },
                )
              else
                _ProfileMenuItem(
                  icon: Icons.login,
                  title: 'Đăng nhập',
                  color: AppColors.primary,
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? color;
  final VoidCallback? onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.textSecondary),
      title: Text(title,
          style: TextStyle(
              fontSize: 14, color: color ?? AppColors.textPrimary)),
      trailing:
          Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
      onTap: onTap,
    );
  }
}
