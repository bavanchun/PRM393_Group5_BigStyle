import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AdminService {
  final SupabaseClient _client = Supabase.instance.client;

  // ─── Platform Stats ───
  Future<Map<String, dynamic>> getDashboardStats() async {
    final results = await Future.wait([
      _client.from('profiles').select('id').then((r) => r.length),
      _client.from('products').select('id').then((r) => r.length),
      _client.from('orders').select('id').then((r) => r.length),
      _client.from('orders').select('total').then((rows) =>
          rows.fold<double>(0, (sum, r) => sum + (r['total'] as num).toDouble())),
      _client.from('profiles').select('id').eq('role', 'customer').then((r) => r.length),
      _client.from('profiles').select('id').eq('role', 'manager').then((r) => r.length),
      _client.from('categories').select('id').then((r) => r.length),
    ]);

    return {
      'totalUsers': results[0],
      'totalProducts': results[1],
      'totalOrders': results[2],
      'totalRevenue': results[3],
      'totalCustomers': results[4],
      'totalManagers': results[5],
      'totalCategories': results[6],
    };
  }

  // ─── User Management ───
  Future<List<UserModel>> getAllUsers() async {
    final data = await _client
        .from('profiles')
        .select()
        .order('created_at', ascending: false);
    return (data as List).map((e) => UserModel.fromMap(e)).toList();
  }

  Future<void> addUser({
    required String email,
    required String fullName,
    required String role,
  }) async {
    final response = await _client.auth.admin.inviteUserByEmail(
      email,
      data: {'role': role},
    );
    final userId = response.user?.id;
    if (userId == null) throw Exception('Không thể tạo người dùng');

    await _client.from('profiles').update({
      'full_name': fullName,
      'role': role,
    }).eq('id', userId);
  }

  Future<void> updateUserRole(String userId, UserRole newRole) async {
    await _client.from('profiles').update({'role': newRole.name}).eq('id', userId);
  }

  Future<void> updateBrandName(String userId, String brandName) async {
    await _client.from('profiles').update({'brand_name': brandName}).eq('id', userId);
  }

  // ─── Category Management ───
  Future<List<Map<String, dynamic>>> getAllCategories() async {
    final data = await _client
        .from('categories')
        .select()
        .order('sort_order', ascending: true);
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<void> createCategory({
    required String name,
    required String slug,
    String? imageUrl,
    int sortOrder = 0,
  }) async {
    await _client.from('categories').insert({
      'name': name,
      'slug': slug,
      'image_url': imageUrl,
      'sort_order': sortOrder,
      'is_active': true,
    });
  }

  Future<void> updateCategory(String id, Map<String, dynamic> updates) async {
    await _client.from('categories').update(updates).eq('id', id);
  }

  Future<void> deleteCategory(String id) async {
    await _client.from('categories').delete().eq('id', id);
  }
}
