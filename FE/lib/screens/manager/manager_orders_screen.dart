import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/manager/manager_bloc.dart';
import '../../blocs/manager/manager_event.dart';
import '../../blocs/manager/manager_state.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';
import '../../models/order_status.dart';
import 'manager_order_card.dart';
import 'manager_order_detail_screen.dart';
import 'order_status_update_sheet.dart';

class ManagerOrdersScreen extends StatefulWidget {
  const ManagerOrdersScreen({super.key});

  @override
  State<ManagerOrdersScreen> createState() => _ManagerOrdersScreenState();
}

class _ManagerOrdersScreenState extends State<ManagerOrdersScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ManagerBloc>().add(const ManagerLoadOrders());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quản lý đơn hàng'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: BlocListener<ManagerBloc, ManagerState>(
        listenWhen: (previous, current) => previous.error != current.error,
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: BlocBuilder<ManagerBloc, ManagerState>(
          builder: (context, state) {
            return Column(
              children: [
                _buildFilterChips(state.selectedStatus),
                if (state.isOrdersLoading) const LinearProgressIndicator(),
                const Divider(height: 1),
                Expanded(child: _buildOrdersContent(state)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChips(String? selectedStatus) {
    final statuses = <OrderStatus?>[null, ...OrderStatus.values];
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        itemCount: statuses.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final status = statuses[index];
          final key = status?.name;
          final isSelected = key == selectedStatus;
          return ChoiceChip(
            label: Text(status?.label ?? 'Tất cả'),
            selected: isSelected,
            onSelected: (_) =>
                context.read<ManagerBloc>().add(ManagerLoadOrders(status: key)),
          );
        },
      ),
    );
  }

  Widget _buildOrdersContent(ManagerState state) {
    if (state.isOrdersLoading && state.orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.error!, style: AppTypography.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              onPressed: () => context.read<ManagerBloc>().add(
                ManagerLoadOrders(status: state.selectedStatus),
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }
    if (state.orders.isEmpty) {
      return Center(
        child: Text('Không có đơn hàng', style: AppTypography.bodyMedium),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _reload(state.selectedStatus),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: state.orders.length,
        itemBuilder: (context, index) {
          final order = state.orders[index];
          return ManagerOrderCard(
            order: order,
            onDetail: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ManagerOrderDetailScreen(order: order),
              ),
            ),
            onUpdateStatus: () => showOrderStatusUpdateSheet(context, order),
          );
        },
      ),
    );
  }

  Future<void> _reload(String? status) async {
    context.read<ManagerBloc>().add(ManagerLoadOrders(status: status));
    await context.read<ManagerBloc>().stream.firstWhere(
      (state) => !state.isOrdersLoading,
    );
  }
}
