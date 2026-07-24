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

  final orders = await ref
      .read(ordersApiProvider)
      .getOrders(customerId: customerId);

  return _sortOrdersByRecentDate(orders);
});

List<CustomerOrder> _sortOrdersByRecentDate(List<CustomerOrder> orders) {
  final sortedOrders = [...orders];
  sortedOrders.sort(_compareOrdersByRecentDate);
  return List.unmodifiable(sortedOrders);
}

int _compareOrdersByRecentDate(CustomerOrder first, CustomerOrder second) {
  final dateComparison = _compareNullableDates(
    first.createdAt ?? first.deliveryDate,
    second.createdAt ?? second.deliveryDate,
  );
  if (dateComparison != 0) return -dateComparison;

  final sequenceComparison = _compareNullableInts(
    _referenceSequence(first.reference),
    _referenceSequence(second.reference),
  );
  if (sequenceComparison != 0) return -sequenceComparison;

  return second.reference.compareTo(first.reference);
}

int _compareNullableDates(DateTime? first, DateTime? second) {
  if (first == null && second == null) return 0;
  if (first == null) return 1;
  if (second == null) return -1;
  return first.compareTo(second);
}

int _compareNullableInts(int? first, int? second) {
  if (first == null && second == null) return 0;
  if (first == null) return 1;
  if (second == null) return -1;
  return first.compareTo(second);
}

int? _referenceSequence(String reference) {
  final match = RegExp(r'(\d+)$').firstMatch(reference.trim());
  if (match == null) return null;
  return int.tryParse(match.group(1)!);
}
