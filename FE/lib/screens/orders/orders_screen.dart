import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';
import '../../blocs/order/order_bloc.dart';
import '../../blocs/order/order_event.dart';
import '../../blocs/order/order_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../models/order_status.dart';
import '../../models/order_model.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/status_badge.dart';
import '../checkout/payment_qr_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthBloc>().state.user?.id;
      if (userId != null) {
        context.read<OrderBloc>().add(OrderLoad(userId));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Đơn hàng của tôi')),
      body: BlocBuilder<OrderBloc, OrderState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.error != null && state.orders.isEmpty) {
            return Center(
              child: AppErrorState(
                message: state.error!,
                onRetry: () {
                  final userId = context.read<AuthBloc>().state.user?.id;
                  if (userId != null) {
                    context.read<OrderBloc>().add(OrderLoad(userId));
                  }
                },
              ),
            );
          }

          if (state.orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 16),
                  Text('Chưa có đơn hàng nào', style: AppTypography.bodyMedium),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: state.orders.length,
            itemBuilder: (context, index) {
              final order = state.orders[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/order-detail',
                    arguments: order.id,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Đơn #${order.orderNumber ?? order.id.substring(0, 8)}',
                            style: AppTypography.labelLarge,
                          ),
                          StatusBadge(
                            label: order.status.label,
                            status: order.status,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...order.items
                          .take(2)
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '${item.productName.isNotEmpty ? item.productName : 'Sản phẩm'} x${item.quantity}',
                                style: AppTypography.bodySmall,
                              ),
                            ),
                          ),
                      if (order.items.length > 2)
                        Text(
                          '+${order.items.length - 2} sản phẩm khác',
                          style: AppTypography.caption,
                        ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDate(order.createdAt),
                            style: AppTypography.caption,
                          ),
                          Text(
                            '${order.total.toStringAsFixed(0)}đ',
                            style: AppTypography.priceSmall,
                          ),
                        ],
                      ),
                      if (order.paymentMethod == 'bank_transfer' &&
                          order.status == OrderStatus.pending) ...[
                        const SizedBox(height: 12),
                        AppButton(
                          label: 'Thanh toán lại',
                          onPressed: () => _payAgain(context, order),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }

  // Reconstructs PaymentQrArgs directly from the order — orderId, orderNumber,
  // total and userId are all already present on OrderModel, so navigating
  // straight to '/payment-qr' gives the exact same args checkout builds
  // (no need for the order-detail intermediate screen).
  void _payAgain(BuildContext context, OrderModel order) {
    Navigator.pushNamed(
      context,
      '/payment-qr',
      arguments: PaymentQrArgs(
        orderId: order.id,
        orderNumber: order.orderNumber,
        total: order.total,
        userId: order.userId,
        // Re-paying an old order must not clear the user's current cart.
        clearCartOnPaid: false,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
