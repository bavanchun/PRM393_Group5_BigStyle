import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase/supabase_config.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../utils/slug.dart';

class ProductService {
  final SupabaseClient _client = Supabase.instance.client;
  final http.Client _httpClient = http.Client();

  Future<List<ProductModel>> getProducts({
    String? categoryId,
    String? searchQuery,
    bool? featured,
    String? storeId,
  }) async {
    var query = _client
        .from('products')
        .select(
          '*, category:categories(*), variants:product_variants(*), store:profiles(brand_name)',
        );

    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    if (storeId != null) {
      query = query.eq('store_id', storeId);
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
        .select(
          '*, category:categories(*), variants:product_variants(*), store:profiles(brand_name)',
        )
        .eq('id', id)
        .maybeSingle();
    return data != null ? ProductModel.fromMap(data) : null;
  }

  Future<List<CategoryModel>> getCategories() async {
    // Customer-facing read: only categories the manager has left active.
    final data = await _client
        .from('categories')
        .select('*')
        .eq('is_active', true)
        .order('sort_order');
    return data.map((e) => CategoryModel.fromMap(e)).toList();
  }

  // --- MANAGER OPERATIONS ---

  Future<ProductModel?> createProductWithVariants(ProductModel product) async {
    final productData = product.toMap();
    // Supabase will generate ID, remove it if it's empty string
    if (productData['id'] == '') {
      productData.remove('id');
    }
    // Remove complex nested objects before insert
    productData.remove('category');
    productData.remove('variants');
    productData.remove('created_at'); // Let DB handle it
    // `slug` is NOT NULL with a unique constraint; the UI never collects one,
    // so derive it from the product name before insert.
    productData['slug'] = generateSlug(product.name);

    // Set store_id to current user if not already set
    if (productData['store_id'] == null) {
      final userId = _client.auth.currentUser?.id;
      if (userId != null) {
        productData['store_id'] = userId;
      }
    }

    final insertedProductList = await _client
        .from('products')
        .insert(productData)
        .select()
        .order('created_at', ascending: false)
        .limit(1);

    if (insertedProductList.isEmpty) return null;
    final insertedProduct = insertedProductList.first;
    final String newProductId = insertedProduct['id'];

    if (product.variants.isNotEmpty) {
      final variantsData = product.variants.map((v) {
        final vMap = v.toMap();
        if (vMap['id'] == '') {
          vMap.remove('id');
        }
        vMap['product_id'] = newProductId;
        return vMap;
      }).toList();

      await _client.from('product_variants').insert(variantsData);
    }

    return getProductById(newProductId);
  }

  Future<ProductModel?> updateProduct(ProductModel product) async {
    await _client.rpc(
      'update_product_with_variants',
      params: buildUpdateProductWithVariantsParams(product),
    );

    return getProductById(product.id);
  }

  static Map<String, dynamic> buildUpdateProductWithVariantsParams(
    ProductModel product,
  ) {
    final productData = product.toMap();
    productData.remove('id');
    productData.remove('category');
    productData.remove('variants');
    productData.remove('created_at');

    final variantsData = product.variants.map((v) {
      final vMap = v.toMap();
      vMap.remove('id');
      vMap['product_id'] = product.id;
      return vMap;
    }).toList();

    return {
      'p_product_id': product.id,
      'p_product': productData,
      'p_variants': variantsData,
    };
  }

  Future<void> deleteProduct(String id) async {
    await _client.from('products').delete().eq('id', id);
  }

  /// Uploads bytes to a public Storage bucket and returns the public URL.
  /// [bucket] defaults to `products` (manager-gated). Pass `avatars` for
  /// customer profile photos — that bucket's RLS requires the object path to
  /// start with the caller's uid (e.g. `<uid>/<file>.jpg`).
  Future<String?> uploadProductImage(
    String fileName,
    List<int> bytes,
    String mimeType, {
    String bucket = 'products',
  }) async {
    try {
      final supabaseUrl = SupabaseConfig.supabaseUrl;
      final anonKey = SupabaseConfig.supabaseAnonKey;
      // Use user's JWT so RLS allows the upload (anon key is blocked by policy)
      final accessToken = _client.auth.currentSession?.accessToken ?? anonKey;
      final url = Uri.parse('$supabaseUrl/storage/v1/object/$bucket/$fileName');

      final response = await _httpClient.post(
        url,
        headers: {
          'apikey': anonKey,
          'Authorization': 'Bearer $accessToken',
          'Content-Type': mimeType,
        },
        body: bytes,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return '$supabaseUrl/storage/v1/object/public/$bucket/$fileName';
      } else {
        debugPrint('Upload failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }
}
