import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';
import '../../config/theme/status_colors.dart';
import '../../models/order_model.dart';
import '../../models/order_status.dart';
import '../../widgets/status_badge.dart';

final _currencyFormat = NumberFormat.currency(
  locale: 'vi_VN',
  symbol: 'đ',
  decimalDigits: 0,
);

String formatOrderCurrency(double amount) => _currencyFormat.format(amount);

/// Takes [context] (rather than reading `StatusColors` as a bare constant)
/// since the shipping tone lives on the theme extension, resolved the same
/// way `StatusBadge` resolves it — kept as one source of truth, not a
/// duplicate `AppColors.info` constant.
Color managerOrderStatusColor(BuildContext context, OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return AppColors.warning;
    case OrderStatus.confirmed:
      return AppColors.primary;
    case OrderStatus.shipping:
      return Theme.of(context).extension<StatusColors>()!.info;
    case OrderStatus.delivered:
      return AppColors.success;
    case OrderStatus.cancelled:
      return AppColors.error;
  }
}

class ManagerOrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onDetail;
  final VoidCallback? onUpdateStatus;
  final bool compact;

  const ManagerOrderCard({
    super.key,
    required this.order,
    required this.onDetail,
    this.onUpdateStatus,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final reference =
        order.orderNumber ??
        (order.id.length >= 8
            ? order.id.substring(0, 8).toUpperCase()
            : order.id.toUpperCase());

    return GestureDetector(
      onTap: compact ? onDetail : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DH-$reference',
                        style: AppTypography.labelLarge.copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        order.customerName?.trim().isNotEmpty == true
                            ? order.customerName!
                            : 'Khách hàng',
                        style: AppTypography.bodySmall.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatOrderCurrency(order.total),
                      style: AppTypography.labelLarge.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    StatusBadge(label: order.status.label, status: order.status),
                  ],
                ),
              ],
            ),
            if (!compact) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onUpdateStatus != null &&
                      order.status.nextStatuses.isNotEmpty) ...[
                    FilledButton(
                      onPressed: onUpdateStatus,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Đổi trạng thái'),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  OutlinedButton(
                    onPressed: onDetail,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Chi tiết'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
