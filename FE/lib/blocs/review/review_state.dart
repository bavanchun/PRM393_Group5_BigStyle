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
  final String? error;

  const ReviewState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.submissionSucceeded = false,
    this.productId,
    this.userId,
    this.reviews = const [],
    this.myReview,
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
    error,
  ];
}
