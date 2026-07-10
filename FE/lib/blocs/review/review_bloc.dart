import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/review_service.dart';
import 'review_event.dart';
import 'review_state.dart';

class ReviewBloc extends Bloc<ReviewEvent, ReviewState> {
  final ReviewService _reviewService;
  int _loadRequestId = 0;

  ReviewBloc(this._reviewService) : super(const ReviewState()) {
    on<ReviewLoad>(_onLoad);
    on<ReviewSubmit>(_onSubmit);
  }

  Future<void> _onLoad(ReviewLoad event, Emitter<ReviewState> emit) async {
    final requestId = ++_loadRequestId;
    emit(
      state.copyWith(
        isLoading: true,
        submissionSucceeded: false,
        productId: event.productId,
        userId: event.userId,
        clearUserId: event.userId == null,
        clearError: true,
      ),
    );
    try {
      final reviewsFuture = _reviewService.getReviews(event.productId);
      final myReviewFuture = event.userId == null
          ? Future.value(null)
          : _reviewService.getMyReview(event.productId, event.userId!);
      final reviews = await reviewsFuture;
      final myReview = await myReviewFuture;
      // An existing review's order_item_id is immutable (DB trigger), so reuse
      // it instead of re-resolving; otherwise resolve eligibility for the user.
      String? eligibleOrderItemId = myReview?.orderItemId;
      if (eligibleOrderItemId == null && event.userId != null) {
        eligibleOrderItemId = await _reviewService.getEligibleOrderItem(
          event.productId,
          event.userId!,
        );
      }
      if (requestId != _loadRequestId) return;
      emit(
        state.copyWith(
          isLoading: false,
          reviews: reviews,
          myReview: myReview,
          clearMyReview: myReview == null,
          canReview: eligibleOrderItemId != null,
          eligibleOrderItemId: eligibleOrderItemId,
          clearEligibility: eligibleOrderItemId == null,
        ),
      );
    } catch (_) {
      if (requestId != _loadRequestId) return;
      emit(state.copyWith(isLoading: false, error: 'Tải đánh giá thất bại'));
    }
  }

  Future<void> _onSubmit(ReviewSubmit event, Emitter<ReviewState> emit) async {
    ++_loadRequestId;
    emit(
      state.copyWith(
        isSubmitting: true,
        submissionSucceeded: false,
        clearError: true,
      ),
    );
    try {
      await _reviewService.upsertReview(
        productId: event.productId,
        userId: event.userId,
        orderItemId: event.orderItemId,
        rating: event.rating,
        comment: event.comment,
        sizeFeedback: event.sizeFeedback,
      );
      final reviewsFuture = _reviewService.getReviews(event.productId);
      final myReviewFuture = _reviewService.getMyReview(
        event.productId,
        event.userId,
      );
      final reviews = await reviewsFuture;
      final myReview = await myReviewFuture;
      emit(
        state.copyWith(
          isSubmitting: false,
          submissionSucceeded: true,
          productId: event.productId,
          userId: event.userId,
          reviews: reviews,
          myReview: myReview,
          clearMyReview: myReview == null,
        ),
      );
    } catch (_) {
      emit(state.copyWith(isSubmitting: false, error: 'Lưu đánh giá thất bại'));
    }
  }
}
