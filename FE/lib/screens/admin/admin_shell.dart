import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../config/theme/app_colors.dart';
import '../../widgets/auth_avatar.dart';
import 'admin_dashboard_screen.dart';
import 'admin_users_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_shipping_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  final _screens = const [
    AdminDashboardScreen(),
    AdminUsersScreen(),
    AdminCategoriesScreen(),
    AdminShippingScreen(),
    _AdminProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) =>
              setState(() => _currentIndex = index),
          backgroundColor: Colors.transparent,
          indicatorColor: AppColors.primary.withValues(alpha: 0.12),
          height: 64,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, size: 22),
              selectedIcon: Icon(Icons.dashboard, size: 22, color: AppColors.primary),
              label: 'Tổng quan',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outlined, size: 22),
              selectedIcon: Icon(Icons.people, size: 22, color: AppColors.primary),
              label: 'Người dùng',
            ),
            NavigationDestination(
              icon: Icon(Icons.category_outlined, size: 22),
              selectedIcon: Icon(Icons.category, size: 22, color: AppColors.primary),
              label: 'Danh mục',
            ),
            NavigationDestination(
              icon: Icon(Icons.local_shipping_outlined, size: 22),
              selectedIcon: Icon(Icons.local_shipping, size: 22, color: AppColors.primary),
              label: 'Vận chuyển',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline, size: 22),
              selectedIcon: Icon(Icons.person, size: 22, color: AppColors.primary),
              label: 'Cá nhân',
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminProfileScreen extends StatelessWidget {
  const _AdminProfileScreen();

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
                    AuthAvatar(
                      key: ValueKey(user?.avatarUrl),
                      url: user?.avatarUrl,
                      radius: 28,
                      backgroundColor: AppColors.onPrimary.withValues(alpha: 0.2),
                      fallback: Text(
                        (user?.fullName.isNotEmpty == true
                            ? user!.fullName[0]
                            : 'A'),
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
                            user?.fullName ?? 'Admin',
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
                        ],
                      ),
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

              const SizedBox(height: 16),

              // Menu items
              _ProfileMenuItem(
                icon: Icons.edit_outlined,
                title: 'Chỉnh sửa hồ sơ',
                onTap: () => Navigator.pushNamed(context, '/edit-profile'),
              ),
              _ProfileMenuItem(
                icon: Icons.person_outline,
                title: 'Hồ sơ',
                onTap: () {},
              ),
              _ProfileMenuItem(
                icon: Icons.settings_outlined,
                title: 'Cài đặt',
                onTap: () {},
              ),
              _ProfileMenuItem(
                icon: Icons.help_outline,
                title: 'Trợ giúp',
                onTap: () {},
              ),

              const Spacer(),

              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.read<AuthBloc>().add(const SignOutEvent());
                    },
                    icon: const Icon(Icons.logout, color: AppColors.error),
                    label: const Text('Đăng xuất',
                        style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
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
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
      onTap: onTap,
    );
  }
}
