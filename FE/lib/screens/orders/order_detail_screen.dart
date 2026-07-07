import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';
import '../../blocs/order/order_bloc.dart';
import '../../blocs/order/order_event.dart';
import '../../blocs/order/order_state.dart';
import '../../models/order_model.dart';
import '../../models/order_status.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_button.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  String? _orderId;
  bool _loadDispatched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadDispatched) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    _orderId = args is String ? args : null;
    _loadDispatched = true;
    if (_orderId != null) {
      final orderId = _orderId!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<OrderBloc>().add(OrderLoadDetail(orderId));
      });
    }
  }

  void _retry() {
    final orderId = _orderId;
    if (orderId == null) return;
    context.read<OrderBloc>().add(OrderLoadDetail(orderId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Chi tiết đơn hàng')),
      body: _orderId == null
          ? _buildError('Không tìm thấy mã đơn hàng.', canRetry: false)
          : BlocBuilder<OrderBloc, OrderState>(
              builder: (context, state) {
                final order = state.selectedOrder;

                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (order == null) {
                  return _buildError(
                    state.error ?? 'Không tìm thấy đơn hàng.',
                    canRetry: true,
                  );
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
                                    color: AppColors.primary
                                        .withValues(alpha: 0.1),
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
                            Text(
                                'Mã: ${order.orderNumber ?? order.id.substring(0, 8).toUpperCase()}',
                                style: AppTypography.bodySmall),
                            const SizedBox(height: 4),
                            Text(
                                'Ngày: ${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
                                style: AppTypography.bodySmall),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppCard(child: _buildTimeline(order.status)),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.productName.isNotEmpty
                                              ? item.productName
                                              : 'Sản phẩm',
                                          style: AppTypography.bodyMedium
                                              .copyWith(
                                                  fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Size ${item.size} x${item.quantity}',
                                          style: AppTypography.caption,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text('${item.unitPrice.toStringAsFixed(0)}đ',
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
                            if (order.discountAmount != null &&
                                order.discountAmount! > 0) ...[
                              const SizedBox(height: 8),
                              _row('Giảm giá', -order.discountAmount!),
                            ],
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
                      if (order.status == OrderStatus.pending ||
                          order.status == OrderStatus.confirmed) ...[
                        const SizedBox(height: 24),
                        AppButton(
                          label: 'Huỷ đơn hàng',
                          backgroundColor: AppColors.error,
                          onPressed: () => _confirmCancel(order),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  /// Renders the linear happy-path stepper, or a terminal badge when the
  /// order was cancelled/refunded (those statuses aren't part of the path).
  Widget _buildTimeline(OrderStatus status) {
    if (status == OrderStatus.cancelled || status == OrderStatus.refunded) {
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status.label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    final steps = OrderStatus.happyPath;
    final currentIndex = steps.indexOf(status);

    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i <= currentIndex
                        ? AppColors.primary
                        : AppColors.textHint.withValues(alpha: 0.3),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  steps[i].label,
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    color: i <= currentIndex
                        ? AppColors.primary
                        : AppColors.textHint,
                    fontWeight:
                        i == currentIndex ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (i != steps.length - 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Container(
                width: 16,
                height: 2,
                color: i < currentIndex
                    ? AppColors.primary
                    : AppColors.textHint.withValues(alpha: 0.3),
              ),
            ),
        ],
      ],
    );
  }

  Future<void> _confirmCancel(OrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Huỷ đơn hàng?'),
        content: const Text(
            'Bạn có chắc chắn muốn huỷ đơn hàng này? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Đóng'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    context.read<OrderBloc>().add(OrderCancel(order.id, order.userId));
  }

  Widget _buildError(String message, {required bool canRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 56, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (canRetry)
              AppButton(label: 'Thử lại', onPressed: _retry)
            else
              AppButton(
                label: 'Quay lại',
                onPressed: () => Navigator.pop(context),
              ),
          ],
        ),
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
