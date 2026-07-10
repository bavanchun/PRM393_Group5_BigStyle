import 'package:bigstyle_app/blocs/review/review_bloc.dart';
import 'package:bigstyle_app/blocs/review/review_event.dart';
import 'package:bigstyle_app/models/review_model.dart';
import 'package:bigstyle_app/services/review_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Hand-fake mirrors the FakeOrderService pattern (test/blocs/manager_bloc_test.dart):
/// ReviewService falls back to Supabase.instance.client when no client is given,
/// so a dummy SupabaseClient is passed to super — none of its methods run because
/// every method below is overridden.
class FakeReviewService extends ReviewService {
  FakeReviewService()
    : super(client: SupabaseClient('http://localhost', 'anon-key'));

  List<ReviewModel> reviewsResult = const [];
  ReviewModel? myReviewResult;
  String? eligibleOrderItemIdResult;

  int getEligibleCallCount = 0;
  String? lastUpsertOrderItemId;

  @override
  Future<List<ReviewModel>> getReviews(String productId) async =>
      reviewsResult;

  @override
  Future<ReviewModel?> getMyReview(String productId, String userId) async =>
      myReviewResult;

  @override
  Future<String?> getEligibleOrderItem(String productId, String userId) async {
    getEligibleCallCount++;
    return eligibleOrderItemIdResult;
  }

  @override
  Future<void> upsertReview({
    required String productId,
    required String userId,
    required String orderItemId,
    required int rating,
    String? comment,
    ReviewSizeFeedback? sizeFeedback,
  }) async {
    lastUpsertOrderItemId = orderItemId;
  }
}

ReviewModel _review({String? orderItemId, bool isVerified = false}) =>
    ReviewModel(
      id: 'r1',
      productId: 'p1',
      userId: 'u1',
      orderItemId: orderItemId,
      rating: 5,
      createdAt: DateTime(2026, 7, 10),
      authorName: 'Khách',
      isVerified: isVerified,
    );

void main() {
  late FakeReviewService service;

  setUp(() => service = FakeReviewService());

  group('ReviewBloc eligibility gate', () {
    test('no eligibility and no existing review → canReview=false', () async {
      service.eligibleOrderItemIdResult = null;
      final bloc = ReviewBloc(service);

      bloc.add(const ReviewLoad('p1', userId: 'u1'));
      final state = await bloc.stream.firstWhere((s) => !s.isLoading);

      expect(state.canReview, isFalse);
      expect(state.eligibleOrderItemId, isNull);
      await bloc.close();
    });

    test('delivered purchase → canReview=true with eligible order item',
        () async {
      service.eligibleOrderItemIdResult = 'oi-1';
      final bloc = ReviewBloc(service);

      bloc.add(const ReviewLoad('p1', userId: 'u1'));
      final state = await bloc.stream.firstWhere((s) => !s.isLoading);

      expect(state.canReview, isTrue);
      expect(state.eligibleOrderItemId, 'oi-1');
      await bloc.close();
    });

    test('existing review reuses its immutable order_item_id, no re-resolve',
        () async {
      service.myReviewResult = _review(orderItemId: 'oi-9', isVerified: true);
      service.eligibleOrderItemIdResult = 'oi-should-not-be-used';
      final bloc = ReviewBloc(service);

      bloc.add(const ReviewLoad('p1', userId: 'u1'));
      final state = await bloc.stream.firstWhere((s) => !s.isLoading);

      expect(state.eligibleOrderItemId, 'oi-9');
      expect(state.canReview, isTrue);
      expect(service.getEligibleCallCount, 0);
      await bloc.close();
    });

    test('anonymous load (no userId) does not resolve eligibility', () async {
      final bloc = ReviewBloc(service);

      bloc.add(const ReviewLoad('p1'));
      final state = await bloc.stream.firstWhere((s) => !s.isLoading);

      expect(state.canReview, isFalse);
      expect(service.getEligibleCallCount, 0);
      await bloc.close();
    });
  });

  group('ReviewBloc submit', () {
    test('submit forwards the order_item_id to the service', () async {
      final bloc = ReviewBloc(service);

      bloc.add(
        const ReviewSubmit(
          productId: 'p1',
          userId: 'u1',
          orderItemId: 'oi-1',
          rating: 4,
        ),
      );
      await bloc.stream.firstWhere((s) => s.submissionSucceeded);

      expect(service.lastUpsertOrderItemId, 'oi-1');
      await bloc.close();
    });
  });
}
