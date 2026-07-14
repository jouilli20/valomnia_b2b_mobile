import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valomnia_b2b_mobile/features/cart/data/cart_order_api.dart';
import 'package:valomnia_b2b_mobile/features/cart/data/cart_repository.dart';
import 'package:valomnia_b2b_mobile/features/cart/domain/cart_item.dart';

void main() {
  test('CustomerCart calculates quantities and totals', () {
    final cart = CustomerCart.empty('customer-1')
        .increment(
          const CartItem(
            productKey: 'item-1',
            name: 'Article 1',
            quantity: 1,
            unitPrice: 12.5,
          ),
        )
        .increment(
          const CartItem(
            productKey: 'item-1',
            name: 'Article 1',
            quantity: 1,
            unitPrice: 12.5,
          ),
        )
        .increment(
          const CartItem(
            productKey: 'item-2',
            name: 'Article 2',
            quantity: 1,
            unitPrice: 4,
          ),
        );

    expect(cart.items, hasLength(2));
    expect(cart.itemCount, 3);
    expect(cart.quantityFor('item-1'), 2);
    expect(cart.total, 29);
  });

  test('CartRepository keeps carts separated by customer id', () async {
    SharedPreferences.setMockInitialValues({});
    const repository = CartRepository();

    final firstCustomerCart = CustomerCart.empty('customer-1').increment(
      const CartItem(
        productKey: 'item-1',
        name: 'Article 1',
        quantity: 1,
        unitPrice: 10,
      ),
    );

    await repository.saveCart(firstCustomerCart);

    final secondCustomerCart = await repository.loadCart('customer-2');
    final reloadedFirstCustomerCart = await repository.loadCart('customer-1');

    expect(secondCustomerCart.isEmpty, isTrue);
    expect(reloadedFirstCustomerCart.items, hasLength(1));
    expect(reloadedFirstCustomerCart.quantityFor('item-1'), 1);
    expect(reloadedFirstCustomerCart.total, 10);
  });

  test('CartOrderPayload matches add-order form fields', () {
    const cart = CustomerCart(
      customerId: 'CT-01',
      items: [
        CartItem(
          productKey: 'id:47',
          name: '55GR Chocolat',
          reference: 'CHOC-55',
          quantity: 2,
          unitPrice: 18,
          orderItemId: '47',
          orderItemUnitId: '46',
        ),
      ],
    );

    final payload = CartOrderPayload(
      cart: cart,
      deliveryDate: DateTime(2026, 11, 20),
      reference: 'ORDER1407260001',
      deliveryComment: 'Test',
    ).toFormData();

    expect(payload['useExternalId'], 'true');
    expect(payload['reference'], 'ORDER1407260001');
    expect(payload['customerId'], 'CT-01');
    expect(payload['status'], 'NOT_PAID');
    expect(payload['total'], '36');
    expect(payload['totalExclTax'], '36');
    expect(payload['operationType'], 'ORDER');
    expect(payload['deliveryComment'], 'Test');
    expect(payload['deliveryDate'], '2026-11-20T00:00:00Z');
    expect(payload.containsKey('delivery_date'), isFalse);

    final orderLines = jsonDecode(payload['orderLines'] as String) as List;
    expect(orderLines, hasLength(1));
    expect(orderLines.first, {
      'id': 47,
      'itemUnitId': 46,
      'finalPrice': 36,
      'unitPrice': 18,
      'tax': '',
      'productName': '55GR Chocolat',
      'productReference': 'CHOC-55',
      'imageUrl': '',
      'quantity': 2,
      'salesQty': 2,
    });
  });

  test('CartOrderPayload sends every cart item in orderLines', () {
    const cart = CustomerCart(
      customerId: 'CT-01',
      items: [
        CartItem(
          productKey: 'id:47',
          name: '55GR Chocolat',
          quantity: 2,
          unitPrice: 18,
          orderItemUnitId: '46',
        ),
        CartItem(
          productKey: 'id:48',
          name: 'Article 2',
          quantity: 3,
          unitPrice: 10,
          orderItemUnitId: '49',
        ),
      ],
    );

    final payload = CartOrderPayload(
      cart: cart,
      deliveryDate: DateTime(2026, 11, 20),
      reference: 'ORDER1407260002',
      deliveryComment: '',
    ).toFormData();

    final orderLines = jsonDecode(payload['orderLines'] as String) as List;

    expect(orderLines, hasLength(2));
    expect(orderLines[0]['id'], 47);
    expect(orderLines[0]['itemUnitId'], 46);
    expect(orderLines[0]['quantity'], 2);
    expect(orderLines[1]['id'], 48);
    expect(orderLines[1]['itemUnitId'], 49);
    expect(orderLines[1]['quantity'], 3);
  });

  test('CartOrderPayload refuses items without unit id', () {
    const cart = CustomerCart(
      customerId: 'CT-01',
      items: [
        CartItem(
          productKey: 'id:47',
          name: '55GR Chocolat',
          quantity: 1,
          unitPrice: 18,
        ),
      ],
    );

    final payload = CartOrderPayload(
      cart: cart,
      deliveryDate: DateTime(2026, 11, 20),
      reference: 'ORDER1407260003',
      deliveryComment: '',
    );

    expect(payload.toFormData, throwsStateError);
  });
}
