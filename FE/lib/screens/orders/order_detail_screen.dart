import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../utils/currency_format.dart';
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
import '../../widgets/status_badge.dart';
import '../../widgets/app_bottom_nav.dart';

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
      appBar: AppBar(
        title: const Text('Chi tiết đơn hàng'),
      ),
      body: _orderId == null
          ? _buildError('Không tìm thấy mã đơn hàng.', canRetry: false)
          : BlocListener<OrderBloc, OrderState>(
              listenWhen: (prev, curr) =>
                  prev.error != curr.error && curr.error != null,
              listener: (context, state) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.error!),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: BlocBuilder<OrderBloc, OrderState>(
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
                        _buildOrderHeader(order),
                        const SizedBox(height: 16),
                        if (order.status != OrderStatus.cancelled) ...[
                          _buildSectionHeader('Trạng thái đơn hàng'),
                          const SizedBox(height: 8),
                          AppCard(child: _buildTimeline(order.status)),
                          const SizedBox(height: 16),
                        ],
                        _buildSectionHeader('Sản phẩm'),
                        const SizedBox(height: 12),
                        ...order.items.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _buildProductCard(item),
                            )),
                        const SizedBox(height: 16),
                        _buildSectionHeader('Phương thức thanh toán'),
                        const SizedBox(height: 8),
                        _buildPaymentMethodCard(order.paymentMethod),
                        const SizedBox(height: 16),
                        _buildSectionHeader('Chi tiết thanh toán'),
                        const SizedBox(height: 8),
                        _buildPriceSummary(order),
                        const SizedBox(height: 16),
                        if (order.address != null) ...[
                          _buildSectionHeader('Địa chỉ giao hàng'),
                          const SizedBox(height: 8),
                          _buildAddressCard(order),
                          const SizedBox(height: 16),
                        ],
                        if (order.status == OrderStatus.pending) ...[
                          AppButton(
                            label: 'Huỷ đơn hàng',
                            backgroundColor: AppColors.error,
                            onPressed: () => _confirmCancel(order),
                          ),
                          const SizedBox(height: 12),
                        ],
                        AppButton(
                          label: 'Quay lại',
                          isOutlined: true,
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                },
              ),
            ),
  bottomNavigationBar: const AppBottomNav(currentIndex: 3),
  );
}

  Widget _buildSectionHeader(String title) {
    return Text(title, style: AppTypography.headlineSmall);
  }

  Widget _buildOrderHeader(OrderModel order) {
    final orderNumber = order.orderNumber ?? order.id.substring(0, 8).toUpperCase();
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đơn hàng #$orderNumber',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          StatusBadge(
            label: order.status.label,
            status: order.status,
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(OrderItem item) {
    final imageUrl = item.productImage;
    return AppCard(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius - 4),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 72,
                      height: 72,
                      color: AppColors.divider,
                      child: Icon(Icons.image_rounded,
                          size: 24, color: AppColors.textHint),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 72,
                      height: 72,
                      color: AppColors.divider,
                      child: Icon(Icons.image_rounded,
                          size: 24, color: AppColors.textHint),
                    ),
                  )
                : Container(
                    width: 72,
                    height: 72,
                    color: AppColors.divider,
                    child: Icon(Icons.image_rounded,
                        size: 24, color: AppColors.textHint),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName.isNotEmpty ? item.productName : 'Sản phẩm',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Size: ${item.size}',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(
                  'SL: x${item.quantity}',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatVnd(item.unitPrice),
                style: AppTypography.priceSmall,
              ),
              const SizedBox(height: 4),
              Text(
                '= ${formatVnd(item.unitPrice * item.quantity)}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(String method) {
    String label;
    IconData icon;
    Color color;

    switch (method) {
      case 'vnpay':
        label = 'VNPay (Thẻ ATM / QR / Ví)';
        icon = Icons.payment_rounded;
        color = AppColors.primary;
        break;
      case 'bank_transfer':
        label = 'Chuyển khoản ngân hàng';
        icon = Icons.account_balance_rounded;
        color = AppColors.secondary;
        break;
      case 'cod':
      default:
        label = 'Thanh toán khi nhận hàng (COD)';
        icon = Icons.money_rounded;
        color = AppColors.success;
        break;
    }

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummary(OrderModel order) {
    final hasDiscount = order.discountAmount != null && order.discountAmount! > 0;

    return AppCard(
      child: Column(
        children: [
          _priceRow('Tạm tính', order.subtotal),
          const SizedBox(height: 8),
          _priceRow('Phí vận chuyển', order.shippingFee),
          if (hasDiscount) ...[
            const SizedBox(height: 8),
            _priceRow('Giảm giá', -order.discountAmount!, isDiscount: true),
          ],
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Divider(height: 1),
          ),
          _priceRow('Tổng cộng', order.total, isTotal: true),
        ],
      ),
    );
  }

  Widget _priceRow(String label, double amount, {bool isDiscount = false, bool isTotal = false}) {
    final formatted = formatVnd(amount);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? AppTypography.headlineSmall
              : AppTypography.bodyMedium,
        ),
        Text(
          formatted,
          style: isTotal
              ? AppTypography.headlineSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                )
              : isDiscount
                  ? AppTypography.bodyMedium.copyWith(
                      color: AppColors.error,
                    )
                  : AppTypography.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildAddressCard(OrderModel order) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_rounded,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Địa chỉ giao hàng',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order.address!,
            style: AppTypography.bodyMedium,
          ),
          if (order.note != null && order.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.note_rounded,
                    size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.note!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (order.cancellationReason != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.cancel_rounded,
                      size: 18, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lý do huỷ đơn',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.cancellationReason!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.error.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
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
            child: Text('Xác nhận',
                style: TextStyle(color: AppColors.error)),
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
                isOutlined: true,
                onPressed: () => Navigator.pop(context),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(OrderStatus status) {
    if (status == OrderStatus.cancelled) {
      return Row(
        children: [
          StatusBadge(label: status.label, status: status),
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
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i <= currentIndex
                        ? AppColors.primary
                        : AppColors.textHint.withValues(alpha: 0.25),
                    border: Border.all(
                      color: i <= currentIndex
                          ? AppColors.primary
                          : AppColors.textHint.withValues(alpha: 0.25),
                      width: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  steps[i].label,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: i <= currentIndex
                        ? AppColors.textPrimary
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
              padding: const EdgeInsets.only(top: 7),
              child: Container(
                width: 24,
                height: 2,
                decoration: BoxDecoration(
                  color: i < currentIndex
                      ? AppColors.primary
                      : AppColors.textHint.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

