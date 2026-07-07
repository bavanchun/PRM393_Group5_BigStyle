import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category_model.dart';
import '../utils/slug.dart';

/// Manager-facing category CRUD. RLS policy `Managers can manage categories`
/// (is_manager()) authorizes writes. Deletes are soft (is_active=false) to
/// avoid violating the products.category_id foreign key.
class CategoryService {
  final SupabaseClient _client = Supabase.instance.client;

  /// All categories (active + inactive) with a live product count, ordered for
  /// the manager list. Uses a PostgREST embedded aggregate for the count.
  Future<List<CategoryModel>> getCategoriesForManager() async {
    final data = await _client
        .from('categories')
        .select('*, products(count)')
        .order('sort_order')
        .order('name');
    return data.map((row) {
      final count = _extractProductCount(row['products']);
      return CategoryModel.fromMap(row).copyWith(productCount: count);
    }).toList();
  }

  Future<CategoryModel?> createCategory(CategoryModel category) async {
    final payload = category.toMap();
    payload.remove('id'); // DB generates the uuid.
    payload['slug'] = generateSlug(category.name); // NOT NULL + unique.

    final inserted = await _client
        .from('categories')
        .insert(payload)
        .select()
        .limit(1);
    if (inserted.isEmpty) return null;
    return CategoryModel.fromMap(inserted.first);
  }

  /// Updates a category. Regenerates the slug only when the name changed so an
  /// unchanged edit keeps its stable slug.
  Future<CategoryModel?> updateCategory(
    CategoryModel category, {
    String? previousName,
  }) async {
    final payload = category.toMap();
    payload.remove('id');
    if (previousName != null && previousName != category.name) {
      payload['slug'] = generateSlug(category.name);
    } else {
      payload.remove('slug'); // Leave the existing slug untouched.
    }

    final updated = await _client
        .from('categories')
        .update(payload)
        .eq('id', category.id)
        .select()
        .limit(1);
    if (updated.isEmpty) return null;
    return CategoryModel.fromMap(updated.first);
  }

  /// Soft-delete: hide the category without breaking product references.
  Future<void> softDeleteCategory(String id) async {
    await _client
        .from('categories')
        .update({'is_active': false})
        .eq('id', id);
  }

  int _extractProductCount(dynamic embedded) {
    if (embedded is List && embedded.isNotEmpty) {
      final first = embedded.first;
      if (first is Map && first['count'] is int) return first['count'] as int;
    }
    return 0;
  }
}
