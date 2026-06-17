import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_event.dart';
import '../../blocs/cart/cart_state.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_bottom_nav.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Giỏ hàng')),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined,
                      size: 80, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  Text(
                    'Giỏ hàng trống',
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hãy thêm sản phẩm vào giỏ hàng',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Mua sắm ngay',
                    width: 200,
                    onPressed: () =>
                        Navigator.pushNamed(context, '/products'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return _buildCartItem(context, item);
                  },
                ),
              ),
              _buildBottomBar(context, state),
            ],
          );
        },
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }

  Widget _buildCartItem(BuildContext context, dynamic item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                height: 80,
                color: AppColors.secondary.withValues(alpha: 0.3),
                child: item.product?.images.isNotEmpty == true
                    ? Image.network(item.product!.images.first, fit: BoxFit.cover)
                    : const Icon(Icons.image_outlined, color: AppColors.textHint),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product?.name ?? '',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Size: ${item.size}',
                    style: AppTypography.caption,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.totalPrice.toStringAsFixed(0)}đ',
                    style: AppTypography.priceSmall,
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Row(
                  children: [
                    _miniButton(Icons.remove, () {
                      if (item.quantity > 1) {
                        context.read<CartBloc>().add(
                              CartUpdateQuantity(item.id, item.quantity - 1),
                            );
                      }
                    }),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${item.quantity}',
                        style: AppTypography.headlineSmall,
                      ),
                    ),
                    _miniButton(Icons.add, () {
                      context.read<CartBloc>().add(
                            CartUpdateQuantity(item.id, item.quantity + 1),
                          );
                    }),
                  ],
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => context
                      .read<CartBloc>()
                      .add(CartRemoveItem(item.id)),
                  child: const Icon(Icons.delete_outline,
                      color: AppColors.error, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 14, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, CartState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tạm tính:', style: AppTypography.bodyMedium),
                Text(
                  '${state.subtotal.toStringAsFixed(0)}đ',
                  style: AppTypography.headlineSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Thanh toán (${state.totalQuantity} sản phẩm)',
              onPressed: () => Navigator.pushNamed(context, '/checkout'),
            ),
          ],
        ),
      ),
    );
  }
}
