import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';
import '../../utils/currency_format.dart';

class ProductCard extends StatelessWidget {
  final String imageUrl;
  final String name;
  final double price;
  final double? originalPrice;
  final List<String> sizes;
  final int soldCount;
  final String? brandName;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.price,
    this.originalPrice,
    this.sizes = const [],
    this.soldCount = 0,
    this.brandName,
    this.onTap,
  });

  bool get hasDiscount => originalPrice != null && originalPrice! > price;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: AppColors.secondary.withValues(alpha: 0.3),
                      child: Icon(Icons.image_outlined,
                          color: AppColors.textHint, size: 36),
                    ),
                  ),
                  if (hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.microRadius),
                        ),
                        child: Text(
                          'SALE',
                          style: TextStyle(
                            color: AppColors.onPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (brandName != null && brandName!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSpacing.microRadius),
                ),
                child: Text(
                  brandName!,
                  style: AppTypography.labelSmall.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          Text(
            name,
            style: AppTypography.labelLarge.copyWith(
              fontSize: 12,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          if (sizes.isNotEmpty)
            Wrap(
              spacing: 3,
              runSpacing: 2,
              children: sizes.take(3).map((s) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.microRadius),
                    ),
                    child: Text(
                      s,
                      style: TextStyle(
                        fontSize: 9,
                        color: AppColors.textHint,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )).toList(),
            ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatVnd(price),
                style: AppTypography.priceSmall,
              ),
              if (hasDiscount) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Text(
                    formatVnd(originalPrice!),
                    style: AppTypography.caption.copyWith(
                      fontSize: 10,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: AppColors.textHint,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (soldCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Row(
                children: [
                  Icon(Icons.shopping_bag_outlined,
                      size: 10, color: AppColors.textHint),
                  const SizedBox(width: 2),
                  Text(
                    'Đã bán $soldCount',
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 9,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
