import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

class ProductService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<ProductModel>> getProducts({
    String? categoryId,
    String? searchQuery,
    bool? featured,
  }) async {
    var query = _client.from('products').select('*, category:categories(*), variants:product_variants(*)');

    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    if (featured == true) {
      query = query.eq('is_featured', true);
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.ilike('name', '%$searchQuery%');
    }

    final data = await query.order('created_at', ascending: false);
    return data.map((e) => ProductModel.fromMap(e)).toList();
  }

  Future<ProductModel?> getProductById(String id) async {
    final data = await _client
        .from('products')
        .select('*, category:categories(*), variants:product_variants(*)')
        .eq('id', id)
        .maybeSingle();
    return data != null ? ProductModel.fromMap(data) : null;
  }

  Future<List<CategoryModel>> getCategories() async {
    final data = await _client.from('categories').select('*');
    return data.map((e) => CategoryModel.fromMap(e)).toList();
  }
}
