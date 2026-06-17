import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';

class OrderService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<OrderModel>> getOrders(String userId) async {
    final data = await _client
        .from('orders')
        .select('*, items:order_items(*, product:products(*))')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return data.map((e) => OrderModel.fromMap(e)).toList();
  }

  Future<OrderModel?> getOrderById(String id) async {
    final data = await _client
        .from('orders')
        .select('*, items:order_items(*, product:products(*))')
        .eq('id', id)
        .maybeSingle();
    return data != null ? OrderModel.fromMap(data) : null;
  }

  Future<void> createOrder(OrderModel order) async {
    await _client.from('orders').insert(order.toMap());
    for (final item in order.items) {
      await _client.from('order_items').insert({
        'order_id': order.id,
        ...item.toMap(),
      });
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _client
        .from('orders')
        .update({'status': status, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', orderId);
  }
}
