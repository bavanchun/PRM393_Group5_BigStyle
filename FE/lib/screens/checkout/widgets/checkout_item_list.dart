import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';
import '../../../models/cart_item_model.dart';

class CheckoutItemList extends StatelessWidget {
  const CheckoutItemList({super.key, required this.items});

  final List<CartItemModel> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sản phẩm', style: AppTypography.headlineSmall),
        const SizedBox(height: 12),
        for (final item in items)
          Padding(
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
                        ? Image.network(
                            item.product!.images.first,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.image_outlined, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product?.name ?? '',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Size ${item.size} x${item.quantity}',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${item.totalPrice.toStringAsFixed(0)}đ',
                  style: AppTypography.priceSmall,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
