import 'dart:developer';

import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';

class CatalogApi {
  final Dio _dio = DioClient.dio;

  Future<List<dynamic>> getCategories() async {
    final response = await _dio.get(
      ApiConstants.itemCategories,
      queryParameters: {'baseUrl': 'https://agro.valomnia.com'},
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
}
