import 'package:bigstyle_app/models/product_model.dart';
import 'package:bigstyle_app/models/variant_model.dart';
import 'package:bigstyle_app/services/product_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('update product RPC payload preserves variant color_hex', () {
    final product = ProductModel(
      id: 'product-1',
      name: 'Áo Linen Bigsize',
      description: 'Test product',
      price: 199000,
      images: const ['https://example.com/product.jpg'],
      createdAt: DateTime.utc(2026, 7, 10),
      variants: const [
        VariantModel(
          id: 'variant-1',
          productId: 'old-product-id',
          size: 'XL',
          color: 'Xanh ngọc',
          colorHex: '#2A6767',
          stockQty: 12,
        ),
      ],
    );

    final params = ProductService.buildUpdateProductWithVariantsParams(product);
    final variants = params['p_variants'] as List<Map<String, dynamic>>;

    expect(params['p_product_id'], 'product-1');
    expect(variants.single['id'], isNull);
    expect(variants.single['product_id'], 'product-1');
    expect(variants.single['color_hex'], '#2A6767');
    expect(variants.single['stock_qty'], 12);
  });
}
