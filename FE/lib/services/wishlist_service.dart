import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';

class WishlistService {
  // Pull the full product (with variants) for each wishlist row so the
  // Favorites grid can reuse ProductCard without a second round-trip.
  static const _wishlistSelect =
      'product:products(*, category:categories(*), variants:product_variants(*))';

  final SupabaseClient _client;

  WishlistService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  Future<List<ProductModel>> getWishlist(String userId) async {
    final data = await _client
        .from('wishlist_items')
        .select(_wishlistSelect)
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return data
        .map((row) => row['product'] as Map<String, dynamic>?)
        .whereType<Map<String, dynamic>>()
        .map(ProductModel.fromMap)
        .toList();
  }

  Future<void> add(String userId, String productId) async {
    await _client.from('wishlist_items').upsert({
      'user_id': userId,
      'product_id': productId,
    }, onConflict: 'user_id,product_id');
  }

  Future<void> remove(String userId, String productId) async {
    await _client
        .from('wishlist_items')
        .delete()
        .eq('user_id', userId)
        .eq('product_id', productId);
  }
}
