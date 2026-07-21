import 'package:equatable/equatable.dart';
import '../../models/review_model.dart';

sealed class ReviewEvent extends Equatable {
  const ReviewEvent();

  @override
  List<Object?> get props => [];
}

class ReviewLoad extends ReviewEvent {
  final String productId;
  final String? userId;

  const ReviewLoad(this.productId, {this.userId});

  @override
  List<Object?> get props => [productId, userId];
}

class ReviewSubmit extends ReviewEvent {
  final String productId;
  final String userId;
  final String orderItemId;
  final int rating;
  final String? comment;
  final ReviewSizeFeedback? sizeFeedback;

  const ReviewSubmit({
    required this.productId,
    required this.userId,
    required this.orderItemId,
    required this.rating,
    this.comment,
    this.sizeFeedback,
  });

  @override
  List<Object?> get props => [
    productId,
    userId,
    orderItemId,
    rating,
    comment,
    sizeFeedback,
  ];
}
