import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase/supabase_config.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

class ProductService {
  final SupabaseClient _client = Supabase.instance.client;
  final http.Client _httpClient = http.Client();

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

  // --- MANAGER OPERATIONS ---

  /// Build a URL-safe slug from a Vietnamese product name.
  /// Strips diacritics, lowercases, and hyphenates. A short time-based suffix
  /// keeps it unique against the `products_slug_key` constraint even when two
  /// products share the same name.
  String _generateSlug(String name) {
    var slug = name.toLowerCase().trim();
    const diacriticGroups = {
      'a': 'àáảãạăằắẳẵặâầấẩẫậ',
      'e': 'èéẻẽẹêềếểễệ',
      'i': 'ìíỉĩị',
      'o': 'òóỏõọôồốổỗộơờớởỡợ',
      'u': 'ùúủũụưừứửữự',
      'y': 'ỳýỷỹỵ',
      'd': 'đ',
    };
    diacriticGroups.forEach((ascii, chars) {
      slug = slug.replaceAll(RegExp('[$chars]'), ascii);
    });
    slug = slug
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    if (slug.isEmpty) slug = 'san-pham';
    final stamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    return '$slug-${stamp.substring(stamp.length - 4)}';
  }

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
    productData['slug'] = _generateSlug(product.name);

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
    final productData = product.toMap();
    productData.remove('category');
    productData.remove('variants');
    productData.remove('created_at');

    await _client.from('products').update(productData).eq('id', product.id);

    // Xử lý update variants: Xóa cũ, thêm mới để đơn giản
    await _client.from('product_variants').delete().eq('product_id', product.id);
    
    if (product.variants.isNotEmpty) {
      final variantsData = product.variants.map((v) {
        final vMap = v.toMap();
        vMap.remove('id'); // Xóa id để insert mới hoàn toàn (generate uuid)
        vMap['product_id'] = product.id;
        return vMap;
      }).toList();
      await _client.from('product_variants').insert(variantsData);
    }

    return getProductById(product.id);
  }

  Future<void> deleteProduct(String id) async {
    await _client.from('products').delete().eq('id', id);
  }

  Future<String?> uploadProductImage(String fileName, List<int> bytes, String mimeType) async {
    try {
      final supabaseUrl = SupabaseConfig.supabaseUrl;
      final anonKey = SupabaseConfig.supabaseAnonKey;
      // Use user's JWT so RLS allows the upload (anon key is blocked by policy)
      final accessToken = _client.auth.currentSession?.accessToken ?? anonKey;
      final url = Uri.parse('$supabaseUrl/storage/v1/object/products/$fileName');

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
        return '$supabaseUrl/storage/v1/object/public/products/$fileName';
      } else {
        print('Upload failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }
}

