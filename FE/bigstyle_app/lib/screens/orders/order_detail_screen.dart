import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';
import '../../blocs/order/order_bloc.dart';
import '../../blocs/order/order_event.dart';
import '../../blocs/order/order_state.dart';
import '../../widgets/app_card.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orderId = ModalRoute.of(context)?.settings.arguments as String;
    context.read<OrderBloc>().add(OrderLoadDetail(orderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Chi tiết đơn hàng')),
      body: BlocBuilder<OrderBloc, OrderState>(
        builder: (context, state) {
          final order = state.selectedOrder;
          if (state.isLoading || order == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Đơn hàng',
                              style: AppTypography.headlineSmall),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              order.status.label,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Mã: ${order.id.substring(0, 8).toUpperCase()}',
                          style: AppTypography.bodySmall),
                      const SizedBox(height: 4),
                      Text(
                          'Ngày: ${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
                          style: AppTypography.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('Sản phẩm', style: AppTypography.headlineSmall),
                const SizedBox(height: 12),
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product?.name ?? 'Sản phẩm',
                                    style: AppTypography.bodyMedium
                                        .copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Size ${item.size} x${item.quantity}',
                                    style: AppTypography.caption,
                                  ),
                                ],
                              ),
                            ),
                            Text('${item.price.toStringAsFixed(0)}đ',
                                style: AppTypography.priceSmall),
                          ],
                        ),
                      ),
                    )),
                const SizedBox(height: 24),
                AppCard(
                  child: Column(
                    children: [
                      _row('Tạm tính', order.subtotal),
                      const SizedBox(height: 8),
                      _row('Phí vận chuyển', order.shippingFee),
                      const Divider(height: 16),
                      _row('Tổng cộng', order.total, isBold: true),
                    ],
                  ),
                ),
                if (order.address != null) ...[
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Địa chỉ giao hàng',
                            style: AppTypography.headlineSmall),
                        const SizedBox(height: 8),
                        Text(order.address!,
                            style: AppTypography.bodyMedium),
                        if (order.note != null) ...[
                          const SizedBox(height: 8),
                          Text('Ghi chú: ${order.note}',
                              style: AppTypography.bodySmall),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _row(String label, double amount, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: isBold
                ? AppTypography.headlineSmall
                : AppTypography.bodyMedium),
        Text(
          '${amount.toStringAsFixed(0)}đ',
          style: isBold
              ? AppTypography.headlineSmall.copyWith(
                  color: AppColors.primary, fontWeight: FontWeight.w700)
              : AppTypography.bodyMedium,
        ),
      ],
    );
  }
}
