import 'package:bigstyle_app/screens/checkout/widgets/checkout_payment_method_selector.dart';
import 'package:bigstyle_app/screens/checkout/widgets/checkout_price_summary.dart';
import 'package:bigstyle_app/screens/checkout/widgets/checkout_voucher_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('payment selector emits exact checkout method values', (
    tester,
  ) async {
    final selectedValues = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CheckoutPaymentMethodSelector(
            value: 'cod',
            onChanged: selectedValues.add,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Chuyển khoản (SePay)'));
    await tester.pump();
    await tester.tap(find.text('Thanh toán khi nhận hàng'));
    await tester.pump();

    expect(selectedValues, ['bank_transfer', 'cod']);
  });

  testWidgets('price summary renders subtotal shipping discount and total', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CheckoutPriceSummary(
            subtotal: 250000,
            shippingFee: 30000,
            discountAmount: 50000,
            total: 230000,
          ),
        ),
      ),
    );

    expect(find.text('Tạm tính'), findsOneWidget);
    expect(find.text('250.000đ'), findsOneWidget);
    expect(find.text('Phí vận chuyển'), findsOneWidget);
    expect(find.text('30.000đ'), findsOneWidget);
    expect(find.text('Giảm giá'), findsOneWidget);
    expect(find.text('-50.000đ'), findsOneWidget);
    expect(find.text('Tổng cộng'), findsOneWidget);
    expect(find.text('230.000đ'), findsOneWidget);
  });

  testWidgets('voucher field keeps input error loading and apply callback', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'SALE50');
    addTearDown(controller.dispose);
    var applyCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CheckoutVoucherField(
            controller: controller,
            isLoading: false,
            errorText: 'Mã giảm giá không hợp lệ',
            onApply: () => applyCount++,
          ),
        ),
      ),
    );

    expect(find.text('SALE50'), findsOneWidget);
    expect(find.text('Mã giảm giá không hợp lệ'), findsOneWidget);

    await tester.tap(find.text('Áp dụng'));
    await tester.pump();

    expect(applyCount, 1);
  });
}
