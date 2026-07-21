import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/manager/manager_bloc.dart';
import '../../blocs/manager/manager_event.dart';
import '../../blocs/manager/manager_state.dart';
import '../../blocs/refund_request/refund_request_bloc.dart';
import '../../blocs/refund_request/refund_request_event.dart';
import '../../blocs/refund_request/refund_request_state.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';
import '../../models/order_status.dart';
import '../../widgets/app_error_state.dart';
import 'manager_order_card.dart';
import 'manager_order_detail_screen.dart';
import 'order_status_update_sheet.dart';

class ManagerOrdersScreen extends StatefulWidget {
  const ManagerOrdersScreen({super.key});

  @override
  State<ManagerOrdersScreen> createState() => _ManagerOrdersScreenState();
}

class _ManagerOrdersScreenState extends State<ManagerOrdersScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    context.read<ManagerBloc>().add(const ManagerLoadOrders());
    context.read<RefundRequestBloc>().add(
      const RefundRequestLoadPendingOrderIds(),
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
      locale: const Locale('vi', 'VN'),
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end.add(const Duration(days: 1));
      });
      _applyDateFilter();
    }
  }

  void _setToday() {
    final now = DateTime.now();
    setState(() {
      _fromDate = DateTime(now.year, now.month, now.day);
      _toDate = _fromDate!.add(const Duration(days: 1));
    });
    _applyDateFilter();
  }

  void _clearDateFilter() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
    _applyDateFilter();
  }

  void _applyDateFilter() {
    final status = context.read<ManagerBloc>().state.selectedStatus;
    context.read<ManagerBloc>().add(
      ManagerLoadOrders(status: status, fromDate: _fromDate, toDate: _toDate),
    );
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
        // Surface transient failures (e.g. a background reload) that keep the
        // list intact; the empty-list case is handled by the full-screen
        // error state in _buildOrdersContent below.
        listenWhen: (previous, current) =>
            current.error != null &&
            current.error != previous.error &&
            current.orders.isNotEmpty,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: AppColors.error,
            ),
          );
        },
        child: BlocBuilder<ManagerBloc, ManagerState>(
          builder: (context, state) {
            return Column(
              children: [
                _buildFilterChips(state.selectedStatus),
                _buildDateFilterRow(),
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
            onSelected: (_) => context.read<ManagerBloc>().add(
              ManagerLoadOrders(status: key, fromDate: _fromDate, toDate: _toDate),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateFilterRow() {
    final hasDateFilter = _fromDate != null || _toDate != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.xs),
      child: Row(
        children: [
          _FilterChip(
            icon: Icons.calendar_today,
            label: _fromDate != null && _toDate != null
                ? '${_fromDate!.day}/${_fromDate!.month} → ${_toDate!.subtract(const Duration(days: 1)).day}/${_toDate!.subtract(const Duration(days: 1)).month}'
                : 'Chọn ngày',
            onTap: _pickDateRange,
          ),
          const SizedBox(width: 4),
          _FilterChip(
            icon: Icons.today,
            label: 'Hôm nay',
            onTap: _setToday,
            isActive: _fromDate != null &&
                _fromDate ==
                    DateTime(
                      DateTime.now().year,
                      DateTime.now().month,
                      DateTime.now().day,
                    ),
          ),
          if (hasDateFilter) ...[
            const SizedBox(width: 4),
            _FilterChip(
              icon: Icons.clear,
              label: 'Xoá',
              onTap: _clearDateFilter,
              isActive: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrdersContent(ManagerState state) {
    if (state.isOrdersLoading && state.orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.orders.isEmpty) {
      return Center(
        child: AppErrorState(
          message: state.error!,
          onRetry: () => context.read<ManagerBloc>().add(
            ManagerLoadOrders(
              status: state.selectedStatus,
              fromDate: _fromDate,
              toDate: _toDate,
            ),
          ),
        ),
      );
    }
    if (state.orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text('Không có đơn hàng', style: AppTypography.bodyMedium),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _reload(state.selectedStatus),
      child: BlocBuilder<RefundRequestBloc, RefundRequestState>(
        builder: (context, refundState) => ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: state.orders.length,
          itemBuilder: (context, index) {
            final order = state.orders[index];
            return ManagerOrderCard(
              order: order,
              hasPendingRefundRequest: refundState.pendingOrderIds.contains(
                order.id,
              ),
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
      ),
    );
  }

  Future<void> _reload(String? status) async {
    context.read<ManagerBloc>().add(
      ManagerLoadOrders(status: status, fromDate: _fromDate, toDate: _toDate),
    );
    await context.read<ManagerBloc>().stream.firstWhere(
      (state) => !state.isOrdersLoading,
    );
  }
}

class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  const _FilterChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.divider,
          borderRadius: BorderRadius.circular(16),
          border: isActive ? Border.all(color: AppColors.primary) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
