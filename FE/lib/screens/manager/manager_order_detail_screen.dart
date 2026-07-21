import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../blocs/manager/manager_bloc.dart';
import '../../blocs/manager/manager_state.dart';
import '../../blocs/refund_request/refund_request_bloc.dart';
import '../../blocs/refund_request/refund_request_event.dart';
import '../../blocs/refund_request/refund_request_state.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';
import '../../models/order_model.dart';
import '../../models/refund_request_model.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';
import '../../utils/currency_format.dart';
import 'order_status_update_sheet.dart';
import 'refund_decision_sheet.dart';

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
  String? _paymentError;

  @override
  void initState() {
    super.initState();
    _loadPayment();
    context.read<RefundRequestBloc>().add(
      RefundRequestLoadForOrder(widget.order.id),
    );
  }

  // Guards against a double-tap on the retry button starting two overlapping
  // fetches — without this, an out-of-order resolution could leave the error
  // card showing even after a later call already succeeded.
  bool _paymentLoadInFlight = false;

  Future<void> _loadPayment() async {
    if (_paymentLoadInFlight) return;
    _paymentLoadInFlight = true;
    setState(() {
      _isLoadingPayment = true;
      _paymentError = null;
    });
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
      setState(() {
        _isLoadingPayment = false;
        _paymentError = 'Không tải được thông tin thanh toán';
      });
    } finally {
      _paymentLoadInFlight = false;
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
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DH-$reference', style: AppTypography.headlineSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Khách hàng: ${order.customerName?.trim().isNotEmpty == true ? order.customerName! : order.customerEmail?.trim().isNotEmpty == true ? order.customerEmail! : 'Không rõ'}',
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ngày đặt: ${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  StatusBadge(
                    label: order.status.label,
                    status: order.status,
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
                  : _paymentError != null
                  ? _buildPaymentError()
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
                        if (_payment?['paid_at'] != null) ...[
                          const SizedBox(height: 4),
                          Builder(
                            builder: (context) {
                              final paidAt = DateTime.tryParse(
                                _payment!['paid_at'] as String,
                              );
                              if (paidAt == null) return const SizedBox.shrink();
                              return Text(
                                'Thanh toán lúc: ${paidAt.hour.toString().padLeft(2, '0')}:${paidAt.minute.toString().padLeft(2, '0')} ${paidAt.day}/${paidAt.month}/${paidAt.year}',
                                style: AppTypography.caption,
                              );
                            },
                          ),
                        ],
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
                        formatVnd(item.unitPrice),
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
            BlocBuilder<RefundRequestBloc, RefundRequestState>(
              builder: (context, refundState) =>
                  _buildRefundRequestSection(refundState),
            ),
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

  Widget _buildPaymentError() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 18),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                _paymentError!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: _loadPayment,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Thử lại'),
        ),
      ],
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
          formatVnd(amount),
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

  /// Only pending requests get a decision affordance — approved/rejected
  /// requests just show their outcome (the order's own StatusBadge already
  /// reflects an approval as `refunded`).
  Widget _buildRefundRequestSection(RefundRequestState refundState) {
    final request = refundState.currentRequest;
    if (request == null) return const SizedBox.shrink();

    if (request.status != RefundRequestStatus.pending) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: AppCard(
          child: Text(
            'Yêu cầu hoàn tiền: ${request.status.label}',
            style: AppTypography.bodyMedium,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Yêu cầu hoàn tiền', style: AppTypography.headlineSmall),
                Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              ],
            ),
            const SizedBox(height: 8),
            Text('Lý do: ${request.reason}', style: AppTypography.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => showRefundDecisionSheet(context, request),
                child: const Text('Xử lý yêu cầu hoàn tiền'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
