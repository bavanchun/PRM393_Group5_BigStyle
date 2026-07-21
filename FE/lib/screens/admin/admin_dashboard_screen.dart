import 'package:flutter/material.dart';
import '../../utils/currency_format.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/admin/admin_bloc.dart';
import '../../blocs/admin/admin_event.dart';
import '../../blocs/admin/admin_state.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_typography.dart';
import '../../config/theme/status_colors.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminBloc>().add(const AdminLoadDashboard());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<AdminBloc, AdminState>(
        // AdminBloc is one app-wide instance and AdminShell keeps all 4 admin
        // tabs mounted (IndexedStack), sharing this single error field — gate
        // on dashboardStats already being loaded so a Users/Categories action
        // failing elsewhere doesn't pop a wrongly-attributed SnackBar here.
        listenWhen: (previous, current) =>
            current.error != null &&
            current.error != previous.error &&
            current.dashboardStats.isNotEmpty,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        },
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<AdminBloc>().add(const AdminLoadDashboard());
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(state)),
                SliverToBoxAdapter(child: _buildStatsSection(state)),
                SliverToBoxAdapter(child: _buildQuickActions(context)),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(AdminState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.onPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.admin_panel_settings,
                  color: AppColors.onPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Admin Panel',
                  style: AppTypography.headlineLarge.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.onPrimary),
                onPressed: () =>
                    context.read<AdminBloc>().add(const AdminLoadDashboard()),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Xin chào, Admin!',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.onPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tổng quan nền tảng BigStyle',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.onPrimary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(AdminState state) {
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final stats = state.dashboardStats;
    final revenue = stats['totalRevenue'] ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Revenue card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.payments_outlined,
                        color: AppColors.success,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('Tổng doanh thu', style: AppTypography.bodySmall),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _formatCurrency(revenue),
                  style: AppTypography.headlineLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 28,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stats grid
          Text('Thống kê', style: AppTypography.headlineMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Người dùng',
                  value: '${stats['totalUsers'] ?? 0}',
                  icon: Icons.people_outline,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Sản phẩm',
                  value: '${stats['totalProducts'] ?? 0}',
                  icon: Icons.inventory_2_outlined,
                  color: Theme.of(context).extension<StatusColors>()!.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Đơn hàng',
                  value: '${stats['totalOrders'] ?? 0}',
                  icon: Icons.receipt_long_outlined,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Danh mục',
                  value: '${stats['totalCategories'] ?? 0}',
                  icon: Icons.category_outlined,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Khách hàng',
                  value: '${stats['totalCustomers'] ?? 0}',
                  icon: Icons.person_outline,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Quản lý',
                  value: '${stats['totalManagers'] ?? 0}',
                  icon: Icons.store_outlined,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Thao tác nhanh', style: AppTypography.headlineMedium),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.people_outline,
            title: 'Quản lý người dùng',
            subtitle: 'Phân quyền customer / manager / admin',
            color: AppColors.primary,
            onTap: () {
              // Trigger tab switch via parent
            },
          ),
          const SizedBox(height: 8),
          _ActionCard(
            icon: Icons.category_outlined,
            title: 'Quản lý danh mục',
            subtitle: 'Thêm, sửa, xóa danh mục sản phẩm',
            color: AppColors.accent,
            onTap: () {
              // Trigger tab switch via parent
            },
          ),
        ],
      ),
    );
  }

  String _formatCurrency(dynamic amount) {
    final value = (amount as num).toInt();
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)} tỷđ';
    }
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)} triệuđ';
    }
    return formatVnd(value);
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTypography.headlineLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.labelSmall),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.labelLarge),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTypography.caption),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
