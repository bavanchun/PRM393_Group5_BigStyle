import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';
import '../../config/theme/status_colors.dart';
import '../../models/order_model.dart';
import '../../models/order_status.dart';
import '../../utils/currency_format.dart';
import '../../widgets/status_badge.dart';

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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DH-$reference',
                    style: AppTypography.labelLarge.copyWith(fontSize: 13),
                  ),
                  Text(
                    order.customerName?.trim().isNotEmpty == true
                        ? order.customerName!
                        : order.customerEmail?.trim().isNotEmpty == true
                            ? order.customerEmail!
                            : 'Khách hàng',
                    style: AppTypography.bodySmall.copyWith(fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        formatVnd(order.total),
                        style: AppTypography.labelLarge.copyWith(fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: StatusBadge(
                          label: order.status.label,
                          status: order.status,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!compact &&
                onUpdateStatus != null &&
                order.status.nextStatuses.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: FilledButton(
                  onPressed: onUpdateStatus,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: const Text('Đổi'),
                ),
              ),
            if (!compact)
              OutlinedButton(
                onPressed: onDetail,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(fontSize: 12),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Chi tiết'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
