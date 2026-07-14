import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/cart_item.dart';

class CartRepository {
  const CartRepository();

  Future<CustomerCart> loadCart(String customerId) async {
    final normalizedCustomerId = _normalizeCustomerId(customerId);
    final preferences = await SharedPreferences.getInstance();
    final rawCart = preferences.getString(_storageKey(normalizedCustomerId));

    if (rawCart == null || rawCart.trim().isEmpty) {
      return CustomerCart.empty(normalizedCustomerId);
    }

    try {
      final decoded = jsonDecode(rawCart);
      if (decoded is Map) {
        return CustomerCart.fromJson(
          normalizedCustomerId,
          Map<String, dynamic>.from(decoded),
        );
      }
    } catch (_) {
      await preferences.remove(_storageKey(normalizedCustomerId));
    }

    return CustomerCart.empty(normalizedCustomerId);
  }

  Future<void> saveCart(CustomerCart cart) async {
    final normalizedCustomerId = _normalizeCustomerId(cart.customerId);
    final preferences = await SharedPreferences.getInstance();
    final key = _storageKey(normalizedCustomerId);

    if (cart.isEmpty) {
      await preferences.remove(key);
      return;
    }

    await preferences.setString(
      key,
      jsonEncode(cart.copyWith(customerId: normalizedCustomerId).toJson()),
    );
  }

  String _storageKey(String customerId) {
    return 'cart:$customerId';
  }

  String _normalizeCustomerId(String customerId) {
    final normalized = customerId.trim();
    if (normalized.isEmpty) {
      throw StateError('Customer ID introuvable.');
    }

    return normalized;
  }
}
