import 'package:bigstyle_app/screens/manager/products/form/manager_product_variant_form_row.dart';
import 'package:bigstyle_app/screens/manager/products/widgets/manager_product_variants_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders row values and removes a variant row', (tester) async {
    final row = ManagerProductVariantFormRow.empty(colorHex: '#2A6767')
      ..size.text = '6XL'
      ..color.text = 'Xanh ngọc'
      ..stock.text = '5';
    addTearDown(row.dispose);

    var addCount = 0;
    int? removedIndex;
    var changedCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ManagerProductVariantsTable(
            rows: [row],
            onAddRow: () => addCount++,
            onRemoveRow: (index) => removedIndex = index,
            onChanged: () => changedCount++,
          ),
        ),
      ),
    );

    expect(find.text('6XL'), findsOneWidget);
    expect(find.text('Xanh ngọc'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(-900, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump();

    expect(removedIndex, 0);

    await tester.tap(find.text('+ THÊM KÍCH CỠ MỚI'));
    expect(addCount, 1);
    expect(changedCount, 0);
  });

  testWidgets('size dropdown writes selected size to row controller', (
    tester,
  ) async {
    final row = ManagerProductVariantFormRow.empty(colorHex: '#914B34')
      ..size.text = 'L';
    addTearDown(row.dispose);

    var changedCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ManagerProductVariantsTable(
            rows: [row],
            onAddRow: () {},
            onRemoveRow: (_) {},
            onChanged: () => changedCount++,
          ),
        ),
      ),
    );

    await tester.tap(find.text('L'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('XL').last);
    await tester.pumpAndSettle();

    expect(row.size.text, 'XL');
    expect(changedCount, 1);
  });
}
