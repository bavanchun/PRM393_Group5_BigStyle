import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/manager/manager_bloc.dart';
import '../../blocs/manager/manager_event.dart';
import '../../blocs/manager/manager_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/notification/notification_bloc.dart';
import '../../blocs/notification/notification_event.dart';
import '../../blocs/notification/notification_state.dart';
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
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    context.read<ManagerBloc>().add(const ManagerLoadOrders());
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId != null) {
      context.read<NotificationBloc>().add(NotificationLoad(userId));
    }
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
      _applyFilter();
    }
  }

  void _setToday() {
    final now = DateTime.now();
    setState(() {
      _fromDate = DateTime(now.year, now.month, now.day);
      _toDate = _fromDate!.add(const Duration(days: 1));
    });
    _applyFilter();
  }

  void _clearDateFilter() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
    _applyFilter();
  }

  void _applyFilter() {
    final status = context.read<ManagerBloc>().state.selectedStatus;
    context.read<ManagerBloc>().add(
      ManagerLoadOrders(
        status: status,
        fromDate: _fromDate,
        toDate: _toDate,
      ),
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
        actions: [
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
                  textStyle: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  child: const Icon(Icons.notifications_outlined),
                ),
                onPressed: () =>
                    Navigator.pushNamed(context, '/notifications'),
              );
            },
          ),
        ],
      ),
      body: BlocListener<ManagerBloc, ManagerState>(
        listenWhen: (previous, current) =>
            previous.error != current.error,
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
                _buildFilterSection(state.selectedStatus),
                if (state.isOrdersLoading)
                  const LinearProgressIndicator(),
                const Divider(height: 1),
                Expanded(child: _buildOrdersContent(state)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterSection(String? selectedStatus) {
    final hasDateFilter = _fromDate != null || _toDate != null;

    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 4,
              ),
              itemCount: OrderStatus.values.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 4),
              itemBuilder: (context, index) {
                final status = index == 0
                    ? null
                    : OrderStatus.values[index - 1];
                final key = status?.name;
                final isSelected = key == selectedStatus;
                return ChoiceChip(
                  label: Text(status?.label ?? 'Tất cả',
                      style: const TextStyle(fontSize: 12)),
                  selected: isSelected,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) {
                    context.read<ManagerBloc>().add(
                      ManagerLoadOrders(
                        status: key,
                        fromDate: _fromDate,
                        toDate: _toDate,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              4,
            ),
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
          ),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.error!, style: AppTypography.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              onPressed: () {
                context.read<ManagerBloc>().add(
                  ManagerLoadOrders(
                    status: state.selectedStatus,
                    fromDate: _fromDate,
                    toDate: _toDate,
                  ),
                );
              },
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
      onRefresh: () async {
        context.read<ManagerBloc>().add(
          ManagerLoadOrders(
            status: state.selectedStatus,
            fromDate: _fromDate,
            toDate: _toDate,
          ),
        );
        await context
            .read<ManagerBloc>()
            .stream
            .firstWhere((s) => !s.isOrdersLoading);
      },
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
                builder: (_) =>
                    ManagerOrderDetailScreen(order: order),
              ),
            ),
            onUpdateStatus: () =>
                showOrderStatusUpdateSheet(context, order),
          );
        },
      ),
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
          border: isActive
              ? Border.all(color: AppColors.primary)
              : null,
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
