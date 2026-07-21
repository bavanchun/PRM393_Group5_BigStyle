import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../config/theme/app_colors.dart';
import '../config/theme/app_spacing.dart';

/// Shimmer placeholder matching [ProductCard]'s 2-column grid geometry.
/// Shared by product_list and search — both render the identical card shape.
class ProductGridSkeleton extends StatelessWidget {
  final int itemCount;

  const ProductGridSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        8,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.58,
      ),
      itemCount: itemCount,
      itemBuilder: (_, _) => Shimmer.fromColors(
        baseColor: AppColors.skeletonBase,
        highlightColor: AppColors.skeletonHighlight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 14,
              width: 140,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 12,
              width: 80,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
