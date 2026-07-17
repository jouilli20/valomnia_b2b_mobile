import 'dart:developer';

import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../domain/customer_profile.dart';

class CustomerApi {
  CustomerApi({Dio? dio}) : _dio = dio ?? DioClient.dio;

  final Dio _dio;

  Future<CustomerProfile> getCustomerProfile({
    required String customerId,
  }) async {
    final normalizedCustomerId = customerId.trim();
    if (normalizedCustomerId.isEmpty) {
      throw ArgumentError.value(customerId, 'customerId', 'Customer ID vide.');
    }

    final response = await _dio.get(
      ApiConstants.customer,
      queryParameters: {
        'baseUrl': ApiConstants.tenantBaseUrl,
        'customerId': normalizedCustomerId,
      },
    );

    log('CUSTOMER STATUS: ${response.statusCode}', name: 'CustomerApi');
    log('CUSTOMER RESPONSE: ${response.data}', name: 'CustomerApi');

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return CustomerProfile.fromJson(data);
    }

    if (data is Map) {
      return CustomerProfile.fromJson(Map<String, dynamic>.from(data));
    }

    throw StateError('Reponse client invalide.');
  }
}
