import 'package:equatable/equatable.dart';

enum ReviewSizeFeedback {
  smaller,
  trueToSize,
  larger;

  String get databaseValue => switch (this) {
    ReviewSizeFeedback.smaller => 'smaller',
    ReviewSizeFeedback.trueToSize => 'true_to_size',
    ReviewSizeFeedback.larger => 'larger',
  };

  String get label => switch (this) {
    ReviewSizeFeedback.smaller => 'Nhỏ hơn dự kiến',
    ReviewSizeFeedback.trueToSize => 'Đúng kích thước',
    ReviewSizeFeedback.larger => 'Lớn hơn dự kiến',
  };

  static ReviewSizeFeedback? fromDatabaseValue(String? value) {
    return switch (value) {
      'smaller' => ReviewSizeFeedback.smaller,
      'true_to_size' => ReviewSizeFeedback.trueToSize,
      'larger' => ReviewSizeFeedback.larger,
      _ => null,
    };
  }
}

class ReviewModel extends Equatable {
  final String id;
  final String productId;
  final String userId;
  final String? orderItemId;
  final int rating;
  final String? comment;
  final List<String> images;
  final ReviewSizeFeedback? sizeFeedback;
  final bool isVerified;
  final DateTime createdAt;
  final String authorName;
  final String? authorAvatarUrl;

  const ReviewModel({
    required this.id,
    required this.productId,
    required this.userId,
    this.orderItemId,
    required this.rating,
    this.comment,
    this.images = const [],
    this.sizeFeedback,
    this.isVerified = false,
    required this.createdAt,
    required this.authorName,
    this.authorAvatarUrl,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    final author = map['author'] as Map<String, dynamic>?;
    return ReviewModel(
      id: map['id'] as String? ?? '',
      productId: map['product_id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      orderItemId: map['order_item_id'] as String?,
      rating: (map['rating'] as num?)?.toInt() ?? 0,
      comment: map['comment'] as String?,
      images: List<String>.from(map['images'] as List? ?? const []),
      sizeFeedback: ReviewSizeFeedback.fromDatabaseValue(
        map['size_feedback'] as String?,
      ),
      isVerified: map['is_verified'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      authorName: author?['full_name'] as String? ?? 'Khách hàng',
      authorAvatarUrl: author?['avatar_url'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    productId,
    userId,
    orderItemId,
    rating,
    comment,
    images,
    sizeFeedback,
    isVerified,
    createdAt,
    authorName,
    authorAvatarUrl,
  ];
}
