import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
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

  Widget _buildPaymentMethodBadge(String method) {
    final isCod = method.toLowerCase() == 'cod';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isCod
            ? Colors.orange.withValues(alpha: 0.1)
            : Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isCod ? 'COD' : 'Chuyển khoản',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isCod ? Colors.orange.shade800 : Colors.blue.shade800,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reference =
        order.orderNumber ??
        (order.id.length >= 8
            ? order.id.substring(0, 8).toUpperCase()
            : order.id.toUpperCase());

    final orderDateStr = DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt);

    final hasItems = order.items.isNotEmpty;
    final firstItem = hasItems ? order.items.first : null;
    final firstItemName = firstItem?.productName ?? '';
    final firstItemDetails = firstItem != null ? '${firstItem.size}, ${firstItem.color}' : '';
    final firstItemQty = firstItem?.quantity ?? 0;
    final firstItemImage = firstItem?.productImage;

    String itemsSummary = '';
    if (hasItems) {
      itemsSummary = '$firstItemName ($firstItemDetails) x$firstItemQty';
      if (order.items.length > 1) {
        itemsSummary += ' và ${order.items.length - 1} sản phẩm khác';
      }
    } else {
      itemsSummary = 'Không có thông tin sản phẩm';
    }

    return GestureDetector(
      onTap: onDetail, // Entire card is clickable to view detail
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Order Number & Date
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Đơn hàng: DH-$reference',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  orderDateStr,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.xs),

            // Body: Customer Info and Product Thumbnail + Text
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail if available
                if (!compact && firstItemImage != null && firstItemImage.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      firstItemImage,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 44,
                        height: 44,
                        color: AppColors.divider,
                        child: const Icon(Icons.image, size: 20, color: AppColors.textHint),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                
                // Customer and Items list info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer Name
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              order.customerName?.trim().isNotEmpty == true
                                  ? order.customerName!
                                  : order.customerEmail?.trim().isNotEmpty == true
                                      ? order.customerEmail!
                                      : 'Khách hàng',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Item Summary
                      Text(
                        itemsSummary,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (compact) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      formatVnd(order.total),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(
                    label: order.status.label,
                    status: order.status,
                  ),
                ],
              ),
            ],

            if (!compact) ...[
              const SizedBox(height: AppSpacing.xs),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.xs),
              
              // Footer Row: Payment Method, Total, and Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left part: Payment Method and Total
                  Expanded(
                    child: Row(
                      children: [
                        _buildPaymentMethodBadge(order.paymentMethod),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            formatVnd(order.total),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Right part: StatusBadge
                  StatusBadge(
                    label: order.status.label,
                    status: order.status,
                  ),
                ],
              ),

              // Full-width status update action button at the bottom
              if (onUpdateStatus != null && order.status.nextStatuses.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 32,
                  child: OutlinedButton(
                    onPressed: onUpdateStatus,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'Cập nhật trạng thái đơn hàng',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
