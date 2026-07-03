import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../blocs/manager/manager_bloc.dart';
import '../../blocs/manager/manager_event.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';
import '../../models/order_model.dart';
import '../../models/order_status.dart';
import 'manager_order_card.dart';

/// Opens a bottom sheet letting the manager pick the next valid status for
/// [order]. Selecting a status dispatches [ManagerUpdateOrderStatus] on the
/// [ManagerBloc] already provided above [context], then closes the sheet.
Future<void> showOrderStatusUpdateSheet(
  BuildContext context,
  OrderModel order,
) {
  final managerBloc = context.read<ManagerBloc>();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      return BlocProvider.value(
        value: managerBloc,
        child: _OrderStatusUpdateSheetContent(order: order),
      );
    },
  );
}

class _OrderStatusUpdateSheetContent extends StatefulWidget {
  final OrderModel order;

  const _OrderStatusUpdateSheetContent({required this.order});

  @override
  State<_OrderStatusUpdateSheetContent> createState() =>
      _OrderStatusUpdateSheetContentState();
}

class _OrderStatusUpdateSheetContentState
    extends State<_OrderStatusUpdateSheetContent> {
  bool _isCheckingPayment = true;
  bool _showUnpaidWarning = false;

  @override
  void initState() {
    super.initState();
    _checkUnpaidBankTransfer();
  }

  /// Warns the manager when this order was paid via bank transfer (SePay)
  /// but the latest payment row is still pending — so confirming it is a
  /// deliberate manual-reconciliation decision, not an accident.
  Future<void> _checkUnpaidBankTransfer() async {
    try {
      final rows = await Supabase.instance.client
          .from('payments')
          .select('method, status')
          .eq('order_id', widget.order.id)
          .order('created_at', ascending: false)
          .limit(1);
      if (!mounted) return;
      final latest = rows.isNotEmpty ? rows.first : null;
      setState(() {
        _isCheckingPayment = false;
        _showUnpaidWarning =
            latest != null &&
            latest['method'] == 'bank_transfer' &&
            latest['status'] == 'pending';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isCheckingPayment = false);
    }
  }

  void _confirm(OrderStatus status) {
    context.read<ManagerBloc>().add(
      ManagerUpdateOrderStatus(orderId: widget.order.id, status: status),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final nextStatuses = widget.order.status.nextStatuses;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cập nhật trạng thái đơn hàng',
              style: AppTypography.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Trạng thái hiện tại: ${widget.order.status.label}',
              style: AppTypography.bodySmall,
            ),
            if (_isCheckingPayment) ...[
              const SizedBox(height: AppSpacing.sm),
              const LinearProgressIndicator(),
            ] else if (_showUnpaidWarning) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Đơn chuyển khoản chưa thanh toán',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            if (nextStatuses.isEmpty)
              Text(
                'Đơn hàng đã ở trạng thái cuối cùng.',
                style: AppTypography.bodyMedium,
              )
            else
              ...nextStatuses.map(
                (status) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: managerOrderStatusColor(status),
                        side: BorderSide(
                          color: managerOrderStatusColor(status),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                      ),
                      onPressed: () => _confirm(status),
                      child: Text(status.label),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
