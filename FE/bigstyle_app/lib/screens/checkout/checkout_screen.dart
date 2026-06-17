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

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

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
          if (state.isSuccess) {
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
        },
        builder: (context, checkoutState) {
          return BlocBuilder<CartBloc, CartState>(
            builder: (context, cartState) {
              final total = cartState.subtotal + checkoutState.shippingFee;

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
                                'Phí vận chuyển', checkoutState.shippingFee),
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
    final cartState = context.read<CartBloc>().state;

    context.read<CheckoutBloc>().add(CheckoutPlaceOrder(
          userId: authState.user?.id ?? '',
          items: cartState.items,
          subtotal: cartState.subtotal,
          shippingFee: 30000,
          address: _addressController.text,
          note: _noteController.text.isNotEmpty ? _noteController.text : null,
        ));
  }
}
