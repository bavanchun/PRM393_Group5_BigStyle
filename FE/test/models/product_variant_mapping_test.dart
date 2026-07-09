import 'package:flutter_test/flutter_test.dart';
import 'package:bigstyle_app/models/product_model.dart';
import 'package:bigstyle_app/models/variant_model.dart';

void main() {
  test('VariantModel preserves color_hex through map conversion', () {
    final variant = VariantModel.fromMap(const {
      'id': 'variant-1',
      'product_id': 'product-1',
      'size': 'XL',
      'color': 'Xanh ngọc',
      'color_hex': '#2A6767',
      'stock_qty': 12,
    });

    expect(variant.colorHex, '#2A6767');
    expect(variant.toMap()['color_hex'], '#2A6767');
  });

  test('ProductModel toMap keeps editable normalized product fields', () {
    final product = ProductModel(
      id: 'product-1',
      name: 'Áo Linen Bigsize',
      description: 'Mát và nhẹ',
      price: 199000,
      originalPrice: 249000,
      images: const ['https://example.com/product.jpg'],
      categoryId: 'category-1',
      material: 'Linen',
      elasticity: 'Nhẹ',
      storeId: 'manager-1',
      createdAt: DateTime.utc(2026, 7, 9),
    );

    final map = product.toMap();

    expect(map['base_price'], 249000);
    expect(map['sale_price'], 199000);
    expect(map['images'], ['https://example.com/product.jpg']);
    expect(map['category_id'], 'category-1');
    expect(map['store_id'], 'manager-1');
  });
}
