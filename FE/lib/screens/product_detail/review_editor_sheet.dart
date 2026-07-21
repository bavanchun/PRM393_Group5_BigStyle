import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/review/review_bloc.dart';
import '../../blocs/review/review_event.dart';
import '../../blocs/review/review_state.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';
import '../../models/review_model.dart';

class ReviewEditorSheet extends StatefulWidget {
  final String productId;
  final String userId;
  final String orderItemId;
  final ReviewModel? existingReview;

  const ReviewEditorSheet({
    super.key,
    required this.productId,
    required this.userId,
    required this.orderItemId,
    this.existingReview,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String productId,
    required String userId,
    required String orderItemId,
    ReviewModel? existingReview,
  }) {
    final reviewBloc = context.read<ReviewBloc>();
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BlocProvider.value(
        value: reviewBloc,
        child: ReviewEditorSheet(
          productId: productId,
          userId: userId,
          orderItemId: orderItemId,
          existingReview: existingReview,
        ),
      ),
    );
  }

  @override
  State<ReviewEditorSheet> createState() => _ReviewEditorSheetState();
}

class _ReviewEditorSheetState extends State<ReviewEditorSheet> {
  late final TextEditingController _commentController;
  late int _rating;
  ReviewSizeFeedback? _sizeFeedback;

  @override
  void initState() {
    super.initState();
    _rating = widget.existingReview?.rating ?? 5;
    _sizeFeedback = widget.existingReview?.sizeFeedback;
    _commentController = TextEditingController(
      text: widget.existingReview?.comment ?? '',
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReviewBloc, ReviewState>(
      listenWhen: (previous, current) =>
          previous.submissionSucceeded != current.submissionSucceeded ||
          previous.error != current.error,
      listener: (context, state) {
        if (state.submissionSucceeded) {
          Navigator.pop(context, true);
        } else if (state.error != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.error!)));
        }
      },
      builder: (context, state) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.existingReview == null
                      ? 'Viết đánh giá'
                      : 'Sửa đánh giá',
                  style: AppTypography.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Mức độ hài lòng', style: AppTypography.labelLarge),
                Row(
                  children: List.generate(5, (index) {
                    final value = index + 1;
                    return IconButton(
                      tooltip: '$value sao',
                      onPressed: state.isSubmitting
                          ? null
                          : () => setState(() => _rating = value),
                      icon: Icon(
                        value <= _rating ? Icons.star : Icons.star_border,
                        color: AppColors.warning,
                        size: 30,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('Đánh giá kích thước', style: AppTypography.labelLarge),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  children: ReviewSizeFeedback.values.map((feedback) {
                    return ChoiceChip(
                      label: Text(feedback.label),
                      selected: _sizeFeedback == feedback,
                      onSelected: state.isSubmitting
                          ? null
                          : (selected) => setState(
                              () => _sizeFeedback = selected ? feedback : null,
                            ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _commentController,
                  enabled: !state.isSubmitting,
                  maxLength: 1000,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Nhận xét (không bắt buộc)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: state.isSubmitting ? null : _submit,
                    child: state.isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Lưu đánh giá'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _submit() {
    final comment = _commentController.text.trim();
    context.read<ReviewBloc>().add(
      ReviewSubmit(
        productId: widget.productId,
        userId: widget.userId,
        orderItemId: widget.orderItemId,
        rating: _rating,
        comment: comment.isEmpty ? null : comment,
        sizeFeedback: _sizeFeedback,
      ),
    );
  }
}
