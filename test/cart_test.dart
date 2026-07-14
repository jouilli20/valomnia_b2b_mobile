import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
}
