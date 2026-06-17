import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cart_item_model.dart';

class CartService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<CartItemModel>> getCartItems(String userId) async {
    final data = await _client
        .from('carts')
        .select('*, product:products(*, category:categories(*))')
        .eq('user_id', userId);
    return data.map((e) => CartItemModel.fromMap(e)).toList();
  }

  Future<void> addToCart(CartItemModel item) async {
    final existing = await _client
        .from('carts')
        .select()
        .eq('user_id', item.id.split('_').first)
        .eq('product_id', item.productId)
        .eq('size', item.size)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from('carts')
          .update({'quantity': existing['quantity'] + item.quantity})
          .eq('id', existing['id']);
    } else {
      await _client.from('carts').insert(item.toMap());
    }
  }

  Future<void> updateQuantity(String cartId, int quantity) async {
    await _client.from('carts').update({'quantity': quantity}).eq('id', cartId);
  }

  Future<void> removeFromCart(String cartId) async {
    await _client.from('carts').delete().eq('id', cartId);
  }

  Future<void> clearCart(String userId) async {
    await _client.from('carts').delete().eq('user_id', userId);
  }
}
