import 'package:bigstyle_app/screens/manager/products/form/manager_product_variant_form_row.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bigstyle_app/models/variant_model.dart';

void main() {
  test('fromVariant and toVariant preserve existing color hex', () {
    final row = ManagerProductVariantFormRow.fromVariant(
      const VariantModel(
        id: 'variant-1',
        productId: 'product-1',
        size: '3XL',
        color: 'Xanh ngọc',
        colorHex: '#2A6767',
        stockQty: 7,
        heightRange: '160-170',
        weightRange: '60-70',
        bustRange: '90-95',
        waistRange: '75-80',
        hipsRange: '95-100',
        armRange: '30-32',
        thighRange: '50-55',
        shoulderRange: '38-40',
      ),
    );

    addTearDown(row.dispose);

    final variant = row.toVariant(
      productId: 'product-1',
      fallbackColorHex: '#914B34',
    );

    expect(variant.id, 'variant-1');
    expect(variant.productId, 'product-1');
    expect(variant.size, '3XL');
    expect(variant.color, 'Xanh ngọc');
    expect(variant.colorHex, '#2A6767');
    expect(variant.stockQty, 7);
    expect(variant.heightRange, '160-170');
    expect(variant.weightRange, '60-70');
    expect(variant.bustRange, '90-95');
    expect(variant.waistRange, '75-80');
    expect(variant.hipsRange, '95-100');
    expect(variant.armRange, '30-32');
    expect(variant.thighRange, '50-55');
    expect(variant.shoulderRange, '38-40');
  });

  test('empty row falls back to current swatch hex when saved', () {
    final row = ManagerProductVariantFormRow.empty();
    addTearDown(row.dispose);

    row.size.text = 'XL';
    row.color.text = 'Đất nung';

    final variant = row.toVariant(productId: '', fallbackColorHex: '#914B34');

    expect(variant.size, 'XL');
    expect(variant.color, 'Đất nung');
    expect(variant.colorHex, '#914B34');
    expect(variant.stockQty, 0);
  });
}
