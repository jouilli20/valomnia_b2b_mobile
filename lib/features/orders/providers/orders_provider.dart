import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/connectivity_service.dart';
import '../../../core/storage/local_cache_repository.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../data/orders_api.dart';
import '../domain/order_history.dart';

final ordersApiProvider = Provider<OrdersApi>((ref) {
  return OrdersApi();
});

final orderHistoryProvider = FutureProvider.autoDispose<List<CustomerOrder>>((
  ref,
) async {
  final onlineStatus = ref.watch(isOnlineProvider);
  final connectivityService = ref.read(connectivityServiceProvider);
  final ordersApi = ref.read(ordersApiProvider);
  final cache = ref.read(localCacheRepositoryProvider);
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

  final cacheKey = 'orders:history:$customerId';

  if (!await _isOnline(connectivityService, onlineStatus)) {
    final cachedOrders = await _cachedOrders(cache, cacheKey);
    return _sortOrdersByRecentDate(cachedOrders);
  }

  List<CustomerOrder> orders;
  try {
    orders = await ordersApi.getOrders(customerId: customerId);
    await cache.saveJson(
      cacheKey,
      orders.map((order) => order.raw).toList(growable: false),
    );
  } catch (_) {
    final cachedOrders = await _cachedOrders(cache, cacheKey);
    if (cachedOrders.isNotEmpty) return _sortOrdersByRecentDate(cachedOrders);
    rethrow;
  }

  return _sortOrdersByRecentDate(orders);
});

Future<bool> _isOnline(
  ConnectivityService connectivityService,
  AsyncValue<bool> onlineStatus,
) async {
  if (onlineStatus is AsyncData<bool>) return onlineStatus.value;
  return connectivityService.hasConnection();
}

Future<List<CustomerOrder>> _cachedOrders(
  LocalCacheRepository cache,
  String cacheKey,
) async {
  final cachedValue = await cache.readJson(cacheKey);
  if (cachedValue is! List) return const [];

  return cachedValue
      .whereType<Map>()
      .map((entry) => CustomerOrder.fromJson(Map<String, dynamic>.from(entry)))
      .toList(growable: false);
}

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
