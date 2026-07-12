import 'package:flutter/material.dart';
import '../../utils/currency_format.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_event.dart';
import '../../blocs/cart/cart_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../models/cart_item_model.dart';
import '../../utils/haptics.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_error_state.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Set<String> _selectedIds = {};

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

          if (state.error != null && state.items.isEmpty) {
            return Center(
              child: AppErrorState(
                message: state.error!,
                onRetry: () {
                  final userId = context.read<AuthBloc>().state.user?.id;
                  if (userId != null) {
                    context.read<CartBloc>().add(CartLoad(userId));
                  }
                },
              ),
            );
          }

          if (state.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 80,
                    color: AppColors.textHint,
                  ),
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
                    onPressed: () => Navigator.pushNamed(context, '/products'),
                  ),
                ],
              ),
            );
          }

          _selectedIds.removeWhere((id) => !state.items.any((i) => i.id == id));
          final selectedItems = state.items
              .where((i) => _selectedIds.contains(i.id))
              .toList();

          return Column(
            children: [
              if (state.items.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _selectedIds.length == state.items.length,
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selectedIds.addAll(state.items.map((i) => i.id));
                            } else {
                              _selectedIds.clear();
                            }
                          });
                        },
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_selectedIds.length == state.items.length) {
                              _selectedIds.clear();
                            } else {
                              _selectedIds.addAll(state.items.map((i) => i.id));
                            }
                          });
                        },
                        child: Text(
                          'Chọn tất cả',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (_selectedIds.isNotEmpty)
                        Text(
                          'Đã chọn ${_selectedIds.length} sản phẩm',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return _buildCartItem(context, item);
                  },
                ),
              ),
              _buildBottomBar(context, selectedItems),
            ],
          );
        },
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }

  Widget _buildCartItem(BuildContext context, dynamic item) {
    final isSelected = _selectedIds.contains(item.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: () =>
            Navigator.pushNamed(context, '/cart-item-edit', arguments: item),
        child: Row(
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    _selectedIds.add(item.id);
                  } else {
                    _selectedIds.remove(item.id);
                  }
                });
              },
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                height: 80,
                color: AppColors.secondary.withValues(alpha: 0.3),
                child: item.product?.images.isNotEmpty == true
                    ? Image.network(
                        item.product!.images.first,
                        fit: BoxFit.cover,
                      )
                    : const Icon(
                        Icons.image_outlined,
                        color: AppColors.textHint,
                      ),
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
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatVnd(item.totalPrice),
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
                        Haptics.tap();
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
                      Haptics.tap();
                      context.read<CartBloc>().add(
                        CartUpdateQuantity(item.id, item.quantity + 1),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Haptics.selection();
                    context.read<CartBloc>().add(CartRemoveItem(item.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã xóa sản phẩm khỏi giỏ hàng'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                      size: 20,
                    ),
                  ),
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
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, size: 14, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    List<CartItemModel> selectedItems,
  ) {
    final selectedSubtotal = selectedItems.fold<double>(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );
    final selectedQty = selectedItems.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.05),
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
                  formatVnd(selectedSubtotal),
                  style: AppTypography.headlineSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppButton(
              label: selectedItems.isEmpty
                  ? 'Chọn sản phẩm để mua'
                  : 'Mua hàng ($selectedQty sản phẩm)',
              onPressed: selectedItems.isEmpty
                  ? null
                  : () => Navigator.pushNamed(
                      context,
                      '/checkout',
                      arguments: {'selectedIds': _selectedIds.toList()},
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
