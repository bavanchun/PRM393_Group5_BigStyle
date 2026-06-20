import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';
import '../../models/review_model.dart';

class ProductReviewSection extends StatelessWidget {
  final bool isLoading;
  final List<ReviewModel> reviews;
  final ReviewModel? myReview;
  final String? error;
  final VoidCallback onWrite;
  final VoidCallback onReload;

  const ProductReviewSection({
    super.key,
    required this.isLoading,
    required this.reviews,
    required this.myReview,
    required this.error,
    required this.onWrite,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Đánh giá', style: AppTypography.headlineSmall),
            TextButton.icon(
              onPressed: onWrite,
              icon: const Icon(Icons.rate_review_outlined, size: 18),
              label: Text(myReview == null ? 'Viết đánh giá' : 'Sửa đánh giá'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else if (error != null)
          Center(
            child: TextButton.icon(
              onPressed: onReload,
              icon: const Icon(Icons.refresh),
              label: Text(error!),
            ),
          )
        else if (reviews.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text(
              'Chưa có đánh giá cho sản phẩm này',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          )
        else
          ...reviews.map((review) => _ReviewCard(review: review)),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = review.authorAvatarUrl;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.secondary,
                backgroundImage: avatarUrl?.isNotEmpty == true
                    ? NetworkImage(avatarUrl!)
                    : null,
                child: avatarUrl?.isNotEmpty == true
                    ? null
                    : Text(
                        review.authorName.isEmpty
                            ? '?'
                            : review.authorName[0].toUpperCase(),
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            review.authorName,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelLarge,
                          ),
                        ),
                        if (review.isVerified) ...[
                          const SizedBox(width: AppSpacing.xxs),
                          const Icon(
                            Icons.verified,
                            size: 15,
                            color: AppColors.success,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (index) => Icon(
                            index < review.rating
                                ? Icons.star
                                : Icons.star_border,
                            size: 14,
                            color: AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          DateFormat('dd/MM/yyyy').format(review.createdAt),
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.comment?.trim().isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              review.comment!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (review.sizeFeedback != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Kích thước: ${review.sizeFeedback!.label}',
              style: AppTypography.caption.copyWith(color: AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }
}
