import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_bottom_nav.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final user = state.user;

            return SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Cá nhân', style: AppTypography.headlineLarge),
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          onPressed: () =>
                              Navigator.pushNamed(context, '/notifications'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppColors.secondary,
                          backgroundImage: user?.avatarUrl != null
                              ? NetworkImage(user!.avatarUrl!)
                              : null,
                          child: user?.avatarUrl == null
                              ? Text(
                                  (user?.fullName.isNotEmpty == true
                                          ? user!.fullName[0]
                                          : 'U')
                                      .toUpperCase(),
                                  style: AppTypography.headlineLarge
                                      .copyWith(color: AppColors.primary),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName ?? 'Người dùng',
                                style: AppTypography.headlineSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? '',
                                style: AppTypography.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AppSpacing.microRadius),
                                ),
                                child: Text(
                                  user?.roleLabel ?? 'Khách hàng',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () =>
                              Navigator.pushNamed(context, '/edit-profile'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildMenuItem(
                    context,
                    icon: Icons.receipt_long_outlined,
                    title: 'Đơn hàng của tôi',
                    onTap: () => Navigator.pushNamed(context, '/orders'),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.favorite_outline,
                    title: 'Sản phẩm yêu thích',
                    onTap: () => Navigator.pushNamed(context, '/favorites'),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.chat_outlined,
                    title: 'Hỗ trợ & Chat',
                    onTap: () => Navigator.pushNamed(context, '/chat'),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.support_agent_outlined,
                    title: 'Chat với nhân viên',
                    onTap: () => Navigator.pushNamed(context, '/support-chat'),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.location_on_outlined,
                    title: 'Cửa hàng',
                    onTap: () => Navigator.pushNamed(context, '/delivery-map'),
                  ),
                  const Divider(indent: 56, endIndent: 16),
                  if (user != null)
                    _buildMenuItem(
                      context,
                      icon: Icons.logout,
                      title: 'Đăng xuất',
                      color: AppColors.error,
                      onTap: () => _logout(context),
                    )
                  else
                    _buildMenuItem(
                      context,
                      icon: Icons.login,
                      title: 'Đăng nhập',
                      color: AppColors.primary,
                      onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                    ),
                  const SizedBox(height: 48),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    Color? color,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.textPrimary),
      title: Text(title,
          style: AppTypography.bodyMedium.copyWith(color: color)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
      onTap: onTap,
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(const SignOutEvent());
            },
            child: const Text('Đăng xuất', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
