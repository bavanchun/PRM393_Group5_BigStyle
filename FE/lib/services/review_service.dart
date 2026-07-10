import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/review_model.dart';

class ReviewService {
  static const _reviewSelect =
      '*, author:profiles!reviews_user_id_fkey(full_name,avatar_url)';

  final SupabaseClient _client;

  ReviewService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  Future<List<ReviewModel>> getReviews(String productId) async {
    final data = await _client
        .from('reviews')
        .select(_reviewSelect)
        .eq('product_id', productId)
        .order('created_at', ascending: false);
    return data.map(ReviewModel.fromMap).toList();
  }

  Future<ReviewModel?> getMyReview(String productId, String userId) async {
    final data = await _client
        .from('reviews')
        .select(_reviewSelect)
        .eq('product_id', productId)
        .eq('user_id', userId)
        .maybeSingle();
    return data == null ? null : ReviewModel.fromMap(data);
  }

  /// Returns the id of an order_items row proving the user received this
  /// product (a delivered, own order containing a variant of the product), or
  /// null if none. Uses `.limit(1)` — a repeat purchaser has multiple eligible
  /// rows and `maybeSingle()` would throw 406 on more than one.
  Future<String?> getEligibleOrderItem(String productId, String userId) async {
    final data = await _client
        .from('order_items')
        .select('id, orders!inner(user_id,status), variant:product_variants!inner(product_id)')
        .eq('orders.user_id', userId)
        .eq('orders.status', 'delivered')
        .eq('variant.product_id', productId)
        .order('id')
        .limit(1);
    if (data.isEmpty) return null;
    return data.first['id'] as String?;
  }

  Future<void> upsertReview({
    required String productId,
    required String userId,
    required String orderItemId,
    required int rating,
    String? comment,
    ReviewSizeFeedback? sizeFeedback,
  }) async {
    // is_verified is owned by the DB trigger — never sent from the client.
    await _client.from('reviews').upsert({
      'product_id': productId,
      'user_id': userId,
      'order_item_id': orderItemId,
      'rating': rating,
      'comment': comment,
      'size_feedback': sizeFeedback?.databaseValue,
    }, onConflict: 'product_id,user_id');
  }
}
