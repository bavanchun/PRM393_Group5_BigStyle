import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/manager/manager_bloc.dart';
import '../../blocs/manager/manager_event.dart';
import '../../blocs/manager/manager_state.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';
import '../../models/order_model.dart';
import 'manager_dashboard_widgets.dart';
import 'manager_order_card.dart';
import 'manager_order_detail_screen.dart';
import 'manager_orders_screen.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  @override
  void initState() {
    super.initState();
    context.read<ManagerBloc>().add(const ManagerLoadDashboard());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Quản lý',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
        ],
      ),
      body: BlocBuilder<ManagerBloc, ManagerState>(
        builder: (context, state) {
          if (state.isDashboardLoading && state.dashboardStats == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null && state.dashboardStats == null) {
            return _buildError(state.error!);
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                if (state.dashboardStats != null)
                  ManagerStatsGrid(stats: state.dashboardStats!),
                const SizedBox(height: AppSpacing.lg),
                ManagerQuickActions(onComingSoon: _showComingSoon),
                const SizedBox(height: AppSpacing.lg),
                _buildRecentOrdersHeader(),
                const SizedBox(height: AppSpacing.sm),
                if (state.recentOrders.isEmpty)
                  const _EmptyRecentOrders()
                else
                  ...state.recentOrders.map(
                    (order) => ManagerOrderCard(
                      order: order,
                      compact: true,
                      onDetail: () => _openOrderDetail(order),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: AppTypography.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          FilledButton(onPressed: _reload, child: const Text('Thử lại')),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Đơn hàng gần đây', style: AppTypography.headlineMedium),
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ManagerOrdersScreen()),
          ),
          child: const Text('Xem tất cả'),
        ),
      ],
    );
  }

  Future<void> _reload() async {
    context.read<ManagerBloc>().add(const ManagerLoadDashboard());
    await context.read<ManagerBloc>().stream.firstWhere(
      (state) => !state.isDashboardLoading,
    );
  }

  void _openOrderDetail(OrderModel order) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ManagerOrderDetailScreen(order: order)),
    );
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng đang phát triển'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _EmptyRecentOrders extends StatelessWidget {
  const _EmptyRecentOrders();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Center(
        child: Text('Chưa có đơn hàng', style: AppTypography.bodyMedium),
      ),
    );
  }
}
