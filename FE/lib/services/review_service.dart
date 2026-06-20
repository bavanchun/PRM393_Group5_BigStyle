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

  Future<void> upsertReview({
    required String productId,
    required String userId,
    required int rating,
    String? comment,
    ReviewSizeFeedback? sizeFeedback,
  }) async {
    await _client.from('reviews').upsert({
      'product_id': productId,
      'user_id': userId,
      'rating': rating,
      'comment': comment,
      'size_feedback': sizeFeedback?.databaseValue,
    }, onConflict: 'product_id,user_id');
  }
}
