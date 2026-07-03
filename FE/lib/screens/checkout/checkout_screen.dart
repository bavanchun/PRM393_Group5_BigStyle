import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_state.dart';
import '../../blocs/checkout/checkout_bloc.dart';
import '../../blocs/checkout/checkout_event.dart';
import '../../blocs/checkout/checkout_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import 'payment_qr_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  // 'cod' | 'bank_transfer'
  String _paymentMethod = 'cod';
  // Phí vận chuyển cố định (flat). Dùng chung cho hiển thị và khi đặt hàng để
  // số tiền trên màn khớp với total của đơn tạo ra.
  static const double _shippingFee = 30000;

  @override
  void dispose() {
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Thanh toán')),
      body: BlocConsumer<CheckoutBloc, CheckoutState>(
        listener: (context, state) {
          // Mutually exclusive: a given place-order result is either a COD
          // success dialog or a SePay QR navigation — never both.
          if (state.awaitingPayment) {
            final authState = context.read<AuthBloc>().state;
            Navigator.pushNamed(
              context,
              '/payment-qr',
              arguments: PaymentQrArgs(
                orderId: state.orderId!,
                orderNumber: state.orderNumber,
                total: state.total ?? 0,
                userId: authState.user?.id ?? '',
              ),
            );
          } else if (state.isSuccess) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.success, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Đặt hàng thành công!',
                      style: AppTypography.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mã đơn hàng: ${state.orderId?.substring(0, 8)}',
                      style: AppTypography.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Xem đơn hàng',
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/orders', (route) => false);
                      },
                    ),
                  ],
                ),
              ),
            );
          }
          if (state.error != null) {
            // createOrder succeeded but createPayment failed for the bank
            // transfer branch — orderId/orderNumber survive the error so
            // "Thử lại" can retry only the payment insert, never the order.
            // Gated on the specific message (not just orderId != null) so an
            // order-creation failure never shows a payment-retry action with
            // a stale orderId from a previous order.
            final canRetryPayment = state.orderId != null &&
                state.error == 'Tạo yêu cầu thanh toán thất bại. Vui lòng thử lại.';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                action: canRetryPayment
                    ? SnackBarAction(
                        label: 'Thử lại',
                        onPressed: () {
                          final authState = context.read<AuthBloc>().state;
                          context.read<CheckoutBloc>().add(CheckoutRetryPayment(
                                orderId: state.orderId!,
                                userId: authState.user?.id ?? '',
                                orderNumber: state.orderNumber,
                                total: state.total ?? 0,
                              ));
                        },
                      )
                    : null,
              ),
            );
          }
        },
        builder: (context, checkoutState) {
          return BlocBuilder<CartBloc, CartState>(
            builder: (context, cartState) {
              final total = cartState.subtotal + _shippingFee;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Địa chỉ giao hàng',
                          style: AppTypography.headlineSmall),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _addressController,
                        hint: 'Nhập địa chỉ của bạn',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        maxLines: 2,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Vui lòng nhập địa chỉ' : null,
                      ),
                      const SizedBox(height: 24),
                      Text('Sản phẩm', style: AppTypography.headlineSmall),
                      const SizedBox(height: 12),
                      ...cartState.items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    color: AppColors.secondary.withValues(alpha: 0.3),
                                    child: item.product?.images.isNotEmpty == true
                                        ? Image.network(item.product!.images.first,
                                            fit: BoxFit.cover)
                                        : const Icon(Icons.image_outlined,
                                            size: 24),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item.product?.name ?? '',
                                          style: AppTypography.bodySmall
                                              .copyWith(fontWeight: FontWeight.w600)),
                                      Text('Size ${item.size} x${item.quantity}',
                                          style: AppTypography.caption),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${item.totalPrice.toStringAsFixed(0)}đ',
                                  style: AppTypography.priceSmall,
                                ),
                              ],
                            ),
                          )),
                      const SizedBox(height: 24),
                      Text('Ghi chú', style: AppTypography.headlineSmall),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _noteController,
                        hint: 'Ghi chú cho đơn hàng (không bắt buộc)',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 24),
                      Text('Phương thức thanh toán',
                          style: AppTypography.headlineSmall),
                      const SizedBox(height: 12),
                      _buildPaymentMethodSelector(),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.cardRadius),
                        ),
                        child: Column(
                          children: [
                            _buildPriceRow('Tạm tính', cartState.subtotal),
                            const SizedBox(height: 8),
                            _buildPriceRow(
                                'Phí vận chuyển', _shippingFee),
                            const Divider(height: 24),
                            _buildPriceRow('Tổng cộng', total, isTotal: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      AppButton(
                        label: 'Đặt hàng (${total.toStringAsFixed(0)}đ)',
                        isLoading: checkoutState.isLoading,
                        onPressed: _placeOrder,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildPaymentMethodOption(
            value: 'cod',
            icon: Icons.payments_outlined,
            label: 'Thanh toán khi nhận hàng',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPaymentMethodOption(
            value: 'bank_transfer',
            icon: Icons.qr_code_2_outlined,
            label: 'Chuyển khoản (SePay)',
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodOption({
    required String value,
    required IconData icon,
    required String label,
  }) {
    final selected = _paymentMethod == value;
    return InkWell(
      onTap: () => setState(() => _paymentMethod = value),
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm, horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal ? AppTypography.headlineSmall : AppTypography.bodyMedium,
        ),
        Text(
          '${amount.toStringAsFixed(0)}đ',
          style: isTotal
              ? AppTypography.headlineSmall.copyWith(
                  color: AppColors.primary, fontWeight: FontWeight.w700)
              : AppTypography.bodyMedium,
        ),
      ],
    );
  }

  void _placeOrder() {
    if (!_formKey.currentState!.validate()) return;

    final authState = context.read<AuthBloc>().state;
    final user = authState.user;

    // Auth guard — require a real (non-mock) authenticated user
    if (user == null || user.id.isEmpty || user.id.startsWith('mock-')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để đặt hàng')),
      );
      return;
    }

    final cartState = context.read<CartBloc>().state;

    context.read<CheckoutBloc>().add(CheckoutPlaceOrder(
          userId: user.id,
          items: cartState.items,
          subtotal: cartState.subtotal,
          shippingFee: _shippingFee,
          address: _addressController.text,
          note: _noteController.text.isNotEmpty ? _noteController.text : null,
          paymentMethod: _paymentMethod,
        ));
  }
}
