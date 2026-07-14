import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_storage_service.dart';
import '../data/cart_order_api.dart';
import '../data/cart_repository.dart';
import '../domain/cart_item.dart';

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return const CartRepository();
});

final cartOrderApiProvider = Provider<CartOrderApi>((ref) {
  return CartOrderApi();
});

final cartControllerProvider =
    AsyncNotifierProvider<CartController, CustomerCart>(CartController.new);

class CartController extends AsyncNotifier<CustomerCart> {
  @override
  Future<CustomerCart> build() async {
    final customerId = await _currentCustomerId();
    return ref.read(cartRepositoryProvider).loadCart(customerId);
  }

  Future<void> addItem(CartItem item) async {
    await _update((cart) => cart.increment(item));
  }

  Future<void> decrementItem(String productKey) async {
    await _update((cart) => cart.decrement(productKey));
  }

  Future<void> removeItem(String productKey) async {
    await _update((cart) => cart.remove(productKey));
  }

  Future<void> clear() async {
    await _update((cart) => CustomerCart.empty(cart.customerId));
  }

  Future<void> _update(CustomerCart Function(CustomerCart cart) update) async {
    final currentCart = await future;
    final updatedCart = update(currentCart);
    state = AsyncData(updatedCart);
    await ref.read(cartRepositoryProvider).saveCart(updatedCart);
  }

  Future<String> _currentCustomerId() async {
    final customerId = (await SecureStorageService.getCustomerId())?.trim();
    if (customerId == null || customerId.isEmpty) {
      throw StateError('Customer ID introuvable.');
    }

    return customerId;
  }
}
