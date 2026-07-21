import 'dart:developer';

import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../domain/order_history.dart';

class OrdersApi {
  OrdersApi({Dio? dio}) : _dio = dio ?? DioClient.dio;

  final Dio _dio;

  Future<List<CustomerOrder>> getOrders({required String customerId}) async {
    final normalizedCustomerId = customerId.trim();
    if (normalizedCustomerId.isEmpty) {
      throw ArgumentError.value(customerId, 'customerId', 'Customer ID vide.');
    }

    final response = await _dio.get(
      ApiConstants.orders,
      queryParameters: {
        'baseUrl': ApiConstants.tenantBaseUrl,
        'customerId': normalizedCustomerId,
      },
    );

    log('ORDERS STATUS: ${response.statusCode}', name: 'OrdersApi');
    log('ORDERS RESPONSE: ${response.data}', name: 'OrdersApi');

    return _extractOrderList(
      response.data,
    ).map(CustomerOrder.fromJson).toList(growable: false);
  }
}

List<Map<String, dynamic>> _extractOrderList(dynamic data) {
  if (data is List) {
    return data
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList(growable: false);
  }

  if (data is Map) {
    for (final key in ['data', 'orders', 'items', 'content', 'results']) {
      final value = data[key];
      if (value is List) {
        return value
            .whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList(growable: false);
      }
    }
  }

  return const [];
}
