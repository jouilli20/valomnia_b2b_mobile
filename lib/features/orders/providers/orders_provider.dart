import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_storage_service.dart';
import '../data/orders_api.dart';
import '../domain/order_history.dart';

final ordersApiProvider = Provider<OrdersApi>((ref) {
  return OrdersApi();
});

final orderHistoryProvider = FutureProvider.autoDispose<List<CustomerOrder>>((
  ref,
) async {
  final customerId = (await SecureStorageService.getCustomerOrderId())?.trim();

  if (customerId == null || customerId.isEmpty) {
    log(
      'Customer order ID not found, cannot load order history',
      name: 'OrdersProvider',
    );
    throw StateError('Customer ID introuvable.');
  }

  log(
    'Loading historical orders for customer order ID = $customerId',
    name: 'OrdersProvider',
  );

  return ref.read(ordersApiProvider).getOrders(customerId: customerId);
});
