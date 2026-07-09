import 'package:bigstyle_app/blocs/checkout/checkout_bloc.dart';
import 'package:bigstyle_app/blocs/checkout/checkout_event.dart';
import 'package:bigstyle_app/blocs/checkout/checkout_state.dart';
import 'package:bigstyle_app/models/cart_item_model.dart';
import 'package:bigstyle_app/models/order_model.dart';
import 'package:bigstyle_app/models/product_model.dart';
import 'package:bigstyle_app/models/variant_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CheckoutBloc', () {
    test('blocks empty item checkout before order service call', () async {
      var orderCalls = 0;
      final bloc = CheckoutBloc(
        null,
        null,
        null,
        createOrder:
            ({
              required items,
              required shippingAddress,
              required shippingFee,
              required paymentMethod,
              notes,
              promoCode,
            }) async {
              orderCalls++;
              throw StateError('should not be called');
            },
        createPayment:
            ({
              required orderId,
              required userId,
              required method,
              required amount,
            }) async {},
      );

      bloc.add(
        const CheckoutPlaceOrder(
          userId: 'user-1',
          items: [],
          subtotal: 0,
          shippingFee: 0,
          address: '123 Test St',
        ),
      );

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<CheckoutState>().having((s) => s.isLoading, 'isLoading', true),
          isA<CheckoutState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having(
                (s) => s.error,
                'error',
                'Vui lòng chọn sản phẩm để đặt hàng',
              ),
        ]),
      );
      expect(orderCalls, 0);

      await bloc.close();
    });

    test('COD success creates order and pending payment', () async {
      final item = _cartItem();
      final paymentCalls = <Map<String, Object?>>[];
      final bloc = CheckoutBloc(
        null,
        null,
        null,
        createOrder:
            ({
              required items,
              required shippingAddress,
              required shippingFee,
              required paymentMethod,
              notes,
              promoCode,
            }) async {
              expect(items, [item]);
              expect(paymentMethod, 'cod');
              expect(shippingAddress['address'], '123 Test St');
              return OrderModel(
                id: 'order-1',
                userId: 'user-1',
                items: const [],
                subtotal: 100000,
                shippingFee: shippingFee,
                total: 115000,
                orderNumber: 'DH000001',
                createdAt: DateTime(2026),
              );
            },
        createPayment:
            ({
              required orderId,
              required userId,
              required method,
              required amount,
            }) async {
              paymentCalls.add({
                'orderId': orderId,
                'userId': userId,
                'method': method,
                'amount': amount,
              });
            },
      );

      bloc.add(
        CheckoutPlaceOrder(
          userId: 'user-1',
          items: [item],
          subtotal: 100000,
          shippingFee: 15000,
          address: '123 Test St',
        ),
      );

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<CheckoutState>().having((s) => s.isLoading, 'isLoading', true),
          isA<CheckoutState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.isSuccess, 'isSuccess', true)
              .having((s) => s.orderId, 'orderId', 'order-1')
              .having((s) => s.orderNumber, 'orderNumber', 'DH000001'),
        ]),
      );
      expect(paymentCalls, [
        {
          'orderId': 'order-1',
          'userId': 'user-1',
          'method': 'cod',
          'amount': 115000.0,
        },
      ]);

      await bloc.close();
    });
  });
}

CartItemModel _cartItem() {
  final product = ProductModel(
    id: 'product-1',
    name: 'Áo BigStyle',
    description: 'Test product',
    price: 100000,
    images: const [],
    createdAt: DateTime(2026),
  );
  const variant = VariantModel(
    id: 'variant-1',
    productId: 'product-1',
    size: 'XL',
    color: 'Xanh',
    colorHex: '#2A6767',
    stockQty: 5,
  );
  return CartItemModel(
    id: 'cart-item-1',
    variantId: 'variant-1',
    quantity: 1,
    addedAt: DateTime(2026),
    product: product,
    variant: variant,
  );
}
