import 'dart:developer';

import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';

class CatalogApi {
  final Dio _dio = DioClient.dio;

  Future<List<dynamic>> getCategories() async {
    final response = await _dio.get(
      ApiConstants.itemCategories,
      queryParameters: {'baseUrl': ApiConstants.tenantBaseUrl},
    );

    log('CATEGORIES STATUS: ${response.statusCode}', name: 'CatalogApi');
    log('CATEGORIES RESPONSE: ${response.data}', name: 'CatalogApi');

    if (response.data is List) {
      return response.data;
    }

    if (response.data is Map && response.data['data'] is List) {
      return response.data['data'];
    }

    return [];
  }

  Future<List<dynamic>> getItems({
    String? customerId,
    int offset = 0,
    int max = 10,
    String? sort,
    String? order,
    String? category,
    String? searchTerm,
    String? minPrice,
    String? maxPrice,
    bool? isNew,
    String? withLabel,
    bool? isPromo,
  }) async {
    final queryParameters = <String, dynamic>{
      'baseUrl': ApiConstants.tenantBaseUrl,
      'offset': offset,
      'max': max,
      if (customerId != null && customerId.trim().isNotEmpty)
        'customerId': customerId.trim(),
      if (sort != null && sort.trim().isNotEmpty) 'sort': sort.trim(),
      if (order != null && order.trim().isNotEmpty) 'order': order.trim(),
      if (category != null && category.trim().isNotEmpty)
        'category': category.trim(),
      if (searchTerm != null && searchTerm.trim().isNotEmpty)
        'searchTerm': searchTerm.trim(),
      if (minPrice != null && minPrice.trim().isNotEmpty)
        'minPrice': minPrice.trim(),
      if (maxPrice != null && maxPrice.trim().isNotEmpty)
        'maxPrice': maxPrice.trim(),
      if (isNew != null) 'isNew': isNew.toString(),
      if (withLabel != null && withLabel.trim().isNotEmpty)
        'withLabel': withLabel.trim(),
      if (isPromo != null) 'isPromo': isPromo.toString(),
    };

    final response = await _dio.post(
      ApiConstants.items,
      queryParameters: queryParameters,
    );

    log('ITEMS STATUS: ${response.statusCode}', name: 'CatalogApi');
    log('ITEMS RESPONSE: ${response.data}', name: 'CatalogApi');

    final data = response.data;
    if (data is List) {
      return data;
    }

    if (data is Map) {
      for (final key in ['data', 'items', 'content', 'results']) {
        final value = data[key];
        if (value is List) return value;
      }
    }

    return [];
  }
}
