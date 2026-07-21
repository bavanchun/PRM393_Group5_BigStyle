import 'package:bigstyle_app/models/review_model.dart';
import 'package:bigstyle_app/screens/product_detail/product_review_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host({
  required bool canReview,
  ReviewModel? myReview,
}) {
  return MaterialApp(
    home: Scaffold(
      body: ProductReviewSection(
        isLoading: false,
        reviews: const [],
        myReview: myReview,
        canReview: canReview,
        error: null,
        onWrite: () {},
        onReload: () {},
      ),
    ),
  );
}

ReviewModel _review() => ReviewModel(
      id: 'r1',
      productId: 'p1',
      userId: 'u1',
      orderItemId: 'oi-1',
      rating: 5,
      createdAt: DateTime(2026, 7, 10),
      authorName: 'Khách',
    );

void main() {
  group('ProductReviewSection write gate', () {
    testWidgets('non-purchaser sees a disabled prompt, not an active button',
        (tester) async {
      await tester.pumpWidget(_host(canReview: false, myReview: null));

      expect(find.text('Mua và nhận hàng để đánh giá'), findsOneWidget);
      expect(find.text('Viết đánh giá'), findsNothing);
    });

    testWidgets('eligible purchaser sees the active write button',
        (tester) async {
      await tester.pumpWidget(_host(canReview: true, myReview: null));

      expect(find.text('Viết đánh giá'), findsOneWidget);
      expect(find.text('Mua và nhận hàng để đánh giá'), findsNothing);
    });

    testWidgets('existing reviewer can still edit even without fresh eligibility',
        (tester) async {
      await tester.pumpWidget(_host(canReview: false, myReview: _review()));

      expect(find.text('Sửa đánh giá'), findsOneWidget);
      expect(find.text('Mua và nhận hàng để đánh giá'), findsNothing);
    });
  });
}
