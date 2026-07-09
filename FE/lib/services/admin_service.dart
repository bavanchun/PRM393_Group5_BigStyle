import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/revenue_recognition.dart';
import '../models/user_model.dart';

typedef AdminFunctionInvoker =
    Future<FunctionResponse> Function(String functionName, {Object? body});

class AdminService {
  final SupabaseClient? _client;
  final AdminFunctionInvoker? _functionInvoker;

  AdminService({SupabaseClient? client, AdminFunctionInvoker? functionInvoker})
    : _client = client,
      _functionInvoker = functionInvoker;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  // ─── Platform Stats ───
  Future<Map<String, dynamic>> getDashboardStats() async {
    final results = await Future.wait([
      _supabase.from('profiles').select('id').then((r) => r.length),
      _supabase.from('products').select('id').then((r) => r.length),
      _supabase.from('orders').select('id').then((r) => r.length),
      _supabase
          .from('orders')
          .select('total,status')
          .inFilter('status', RevenueRecognition.acceptedStatuses.toList())
          .then((rows) => RevenueRecognition.recognizedRevenue(rows)),
      _supabase
          .from('profiles')
          .select('id')
          .eq('role', 'customer')
          .then((r) => r.length),
      _supabase
          .from('profiles')
          .select('id')
          .eq('role', 'manager')
          .then((r) => r.length),
      _supabase.from('categories').select('id').then((r) => r.length),
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
    final data = await _supabase
        .from('profiles')
        .select()
        .order('created_at', ascending: false);
    return (data as List).map((e) => UserModel.fromMap(e)).toList();
  }

  Future<void> addUser({
    required String email,
    required String fullName,
    required String role,
    String? brandName,
  }) async {
    final body = {
      'email': email,
      'fullName': fullName,
      'role': role,
      if (brandName != null && brandName.trim().isNotEmpty)
        'brandName': brandName.trim(),
    };
    final invoke = _functionInvoker ?? _supabase.functions.invoke;
    final response = await invoke('admin-invite-user', body: body);
    if (response.status < 200 || response.status >= 300) {
      throw Exception(_functionErrorMessage(response.data));
    }
  }

  String _functionErrorMessage(dynamic data) {
    if (data is Map && data['error'] != null) return data['error'].toString();
    return 'Không thể tạo người dùng';
  }

  Future<void> updateUserRole(String userId, UserRole newRole) async {
    await _supabase
        .from('profiles')
        .update({'role': newRole.name})
        .eq('id', userId);
  }

  Future<void> updateBrandName(String userId, String brandName) async {
    await _supabase
        .from('profiles')
        .update({'brand_name': brandName})
        .eq('id', userId);
  }

  // ─── Category Management ───
  Future<List<Map<String, dynamic>>> getAllCategories() async {
    final data = await _supabase
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
    await _supabase.from('categories').insert({
      'name': name,
      'slug': slug,
      'image_url': imageUrl,
      'sort_order': sortOrder,
      'is_active': true,
    });
  }

  Future<void> updateCategory(String id, Map<String, dynamic> updates) async {
    await _supabase.from('categories').update(updates).eq('id', id);
  }

  Future<void> deleteCategory(String id) async {
    await _supabase.from('categories').delete().eq('id', id);
  }
}
