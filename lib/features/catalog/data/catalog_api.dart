import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';

class CatalogApi {
  final Dio _dio = DioClient.dio;

  Future<List<dynamic>> getItems({
    required String customerId,
  }) async {
    final response = await _dio.post(
      ApiConstants.items,
      data: {
        'baseUrl': 'https://agro.valomnia.com',
        'offset': 0,
        'max': 20,
        'customerId': customerId,
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );

    print('ITEMS STATUS: ${response.statusCode}');
    print('ITEMS RESPONSE: ${response.data}');

    if (response.data is Map && response.data['data'] is List) {
      return response.data['data'];
    }

    return [];
  }
}