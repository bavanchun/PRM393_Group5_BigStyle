import 'package:equatable/equatable.dart';
import '../../models/review_model.dart';

class ReviewState extends Equatable {
  final bool isLoading;
  final bool isSubmitting;
  final bool submissionSucceeded;
  final String? productId;
  final String? userId;
  final List<ReviewModel> reviews;
  final ReviewModel? myReview;
  // True when the user may write/edit a review for this product.
  final bool canReview;
  // order_items id proving eligibility; required to submit under the RLS gate.
  final String? eligibleOrderItemId;
  final String? error;

  const ReviewState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.submissionSucceeded = false,
    this.productId,
    this.userId,
    this.reviews = const [],
    this.myReview,
    this.canReview = false,
    this.eligibleOrderItemId,
    this.error,
  });

  ReviewState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    bool? submissionSucceeded,
    String? productId,
    String? userId,
    bool clearUserId = false,
    List<ReviewModel>? reviews,
    ReviewModel? myReview,
    bool clearMyReview = false,
    bool? canReview,
    String? eligibleOrderItemId,
    bool clearEligibility = false,
    String? error,
    bool clearError = false,
  }) {
    return ReviewState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submissionSucceeded: submissionSucceeded ?? this.submissionSucceeded,
      productId: productId ?? this.productId,
      userId: clearUserId ? null : userId ?? this.userId,
      reviews: reviews ?? this.reviews,
      myReview: clearMyReview ? null : myReview ?? this.myReview,
      canReview: canReview ?? this.canReview,
      eligibleOrderItemId: clearEligibility
          ? null
          : eligibleOrderItemId ?? this.eligibleOrderItemId,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isSubmitting,
    submissionSucceeded,
    productId,
    userId,
    reviews,
    myReview,
    canReview,
    eligibleOrderItemId,
    error,
  ];
}
