import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../blocs/manager/manager_bloc.dart';
import '../../blocs/manager/manager_state.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';
import '../../models/order_model.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';
import 'manager_order_card.dart';
import 'order_status_update_sheet.dart';

/// Manager-only order detail screen. Unlike the customer-facing
/// OrderDetailScreen, this one is instantiated with an [OrderModel] snapshot,
/// but re-resolves the current order from [ManagerBloc.state.orders] on every
/// build so a status update elsewhere is reflected here once the bloc
/// reloads its orders list.
class ManagerOrderDetailScreen extends StatefulWidget {
  final OrderModel order;

  const ManagerOrderDetailScreen({super.key, required this.order});

  @override
  State<ManagerOrderDetailScreen> createState() =>
      _ManagerOrderDetailScreenState();
}

class _ManagerOrderDetailScreenState extends State<ManagerOrderDetailScreen> {
  Map<String, dynamic>? _payment;
  bool _isLoadingPayment = true;

  @override
  void initState() {
    super.initState();
    _loadPayment();
  }

  Future<void> _loadPayment() async {
    try {
      final rows = await Supabase.instance.client
          .from('payments')
          .select('method, status, amount, paid_at')
          .eq('order_id', widget.order.id)
          .order('created_at', ascending: false)
          .limit(1);
      if (!mounted) return;
      setState(() {
        _payment = rows.isNotEmpty ? rows.first : null;
        _isLoadingPayment = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingPayment = false);
    }
  }

  String _paymentMethodLabel(String? method) {
    switch (method) {
      case 'cod':
        return 'Thanh toán khi nhận hàng (COD)';
      case 'bank_transfer':
        return 'Chuyển khoản ngân hàng';
      case 'vnpay':
        return 'VNPay';
      case 'momo':
        return 'Momo';
      default:
        return 'Chưa xác định';
    }
  }

  String _paymentStatusLabel(String? status) {
    switch (status) {
      case 'pending':
        return 'Chưa thanh toán';
      case 'success':
        return 'Đã thanh toán';
      case 'failed':
        return 'Thất bại';
      case 'refunded':
        return 'Đã hoàn tiền';
      default:
        return 'Không có';
    }
  }

  Color _paymentStatusColor(String? status) {
    switch (status) {
      case 'success':
        return AppColors.success;
      case 'failed':
        return AppColors.error;
      case 'refunded':
        return AppColors.warning;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ManagerBloc, ManagerState>(
      builder: (context, state) {
        final order = state.orders.firstWhere(
          (o) => o.id == widget.order.id,
          orElse: () => widget.order,
        );
        return _buildBody(context, order);
      },
    );
  }

  Widget _buildBody(BuildContext context, OrderModel order) {
    final reference =
        order.orderNumber ??
        (order.id.length >= 8
            ? order.id.substring(0, 8).toUpperCase()
            : order.id.toUpperCase());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Chi tiết đơn hàng')),
      body: SingleChildScrollView(
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
                      Text('DH-$reference', style: AppTypography.headlineSmall),
                      StatusBadge(
                        label: order.status.label,
                        status: order.status,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Khách hàng: ${order.customerName?.trim().isNotEmpty == true ? order.customerName! : 'Không rõ'}',
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ngày đặt: ${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Thanh toán', style: AppTypography.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: _isLoadingPayment
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phương thức: ${_paymentMethodLabel(_payment?['method'] as String?)}',
                          style: AppTypography.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Trạng thái: ',
                              style: AppTypography.bodyMedium,
                            ),
                            Text(
                              _paymentStatusLabel(
                                _payment?['status'] as String?,
                              ),
                              style: AppTypography.bodyMedium.copyWith(
                                color: _paymentStatusColor(
                                  _payment?['status'] as String?,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Sản phẩm', style: AppTypography.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: AppCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName.isNotEmpty
                                  ? item.productName
                                  : 'Sản phẩm',
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Size ${item.size} x${item.quantity}',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        formatOrderCurrency(item.unitPrice),
                        style: AppTypography.priceSmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Column(
                children: [
                  _amountRow('Tạm tính', order.subtotal),
                  const SizedBox(height: 8),
                  _amountRow('Phí vận chuyển', order.shippingFee),
                  const Divider(height: 16),
                  _amountRow('Tổng cộng', order.total, isBold: true),
                ],
              ),
            ),
            if (order.address != null) ...[
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Địa chỉ giao hàng',
                      style: AppTypography.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(order.address!, style: AppTypography.bodyMedium),
                    if (order.note != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Ghi chú: ${order.note}',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (order.status.nextStatuses.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => showOrderStatusUpdateSheet(context, order),
                  child: const Text('Cập nhật trạng thái'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _amountRow(String label, double amount, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isBold
              ? AppTypography.headlineSmall
              : AppTypography.bodyMedium,
        ),
        Text(
          formatOrderCurrency(amount),
          style: isBold
              ? AppTypography.headlineSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                )
              : AppTypography.bodyMedium,
        ),
      ],
    );
  }
}
