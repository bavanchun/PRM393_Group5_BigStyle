import 'package:flutter/material.dart';
import '../../utils/currency_format.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';
import '../../blocs/order/order_bloc.dart';
import '../../blocs/order/order_event.dart';
import '../../blocs/order/order_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/status_badge.dart';

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
                        children: [
                          Flexible(
                            child: Text(
                              'Đơn #${order.orderNumber ?? order.id.substring(0, 8)}',
                              style: AppTypography.labelLarge,
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
                            formatVnd(order.total),
                            style: AppTypography.priceSmall,
                          ),
                        ],
                      ),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
