import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cart_item_model.dart';

/// Interacts with the normalized cart / cart_items schema.
/// cart: id, user_id (unique), promo_code, discount_amount
/// cart_items: id, cart_id, variant_id, quantity, added_at  unique(cart_id, variant_id)
class CartService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Returns the cart id for [userId], creating one if it does not exist.
  Future<String> _getOrCreateCart(String userId) async {
    final existing = await _client
        .from('cart')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) return existing['id'] as String;

    final created = await _client
        .from('cart')
        .insert({'user_id': userId})
        .select('id')
        .single();
    return created['id'] as String;
  }

  /// Loads all cart items for [userId] with full variant + product join.
  Future<List<CartItemModel>> getCartItems(String userId) async {
    final cart = await _client
        .from('cart')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    if (cart == null) return [];

    final data = await _client
        .from('cart_items')
        .select('*, variant:product_variants(*, product:products(*, category:categories(*)))')
        .eq('cart_id', cart['id'] as String);

    return data.map((e) => CartItemModel.fromMap(e)).toList();
  }

  /// Adds [variantId] to [userId]'s cart, incrementing quantity if already present.
  Future<void> addToCart(String userId, String variantId, int quantity) async {
    final cartId = await _getOrCreateCart(userId);

    final existing = await _client
        .from('cart_items')
        .select('id, quantity')
        .eq('cart_id', cartId)
        .eq('variant_id', variantId)
        .maybeSingle();

    if (existing != null) {
      final newQty = (existing['quantity'] as int) + quantity;
      await _client
          .from('cart_items')
          .update({'quantity': newQty})
          .eq('id', existing['id'] as String);
    } else {
      await _client.from('cart_items').insert({
        'cart_id': cartId,
        'variant_id': variantId,
        'quantity': quantity,
      });
    }
  }

  /// Updates the quantity of a cart_items row identified by [cartItemId].
  Future<void> updateQuantity(String cartItemId, int quantity) async {
    await _client
        .from('cart_items')
        .update({'quantity': quantity})
        .eq('id', cartItemId);
  }

  /// Removes a single cart_items row by [cartItemId].
  Future<void> removeFromCart(String cartItemId) async {
    await _client.from('cart_items').delete().eq('id', cartItemId);
  }

  /// Deletes all items from [userId]'s cart (does not delete the cart row).
  Future<void> clearCart(String userId) async {
    final cart = await _client
        .from('cart')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    if (cart != null) {
      await _client
          .from('cart_items')
          .delete()
          .eq('cart_id', cart['id'] as String);
    }
  }
}
