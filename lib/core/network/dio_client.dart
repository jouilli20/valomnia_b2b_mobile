import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

class DioClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      followRedirects: false,
      validateStatus: (status) =>
          status != null && status >= 200 && status < 300,
      headers: {'Accept': 'application/json'},
    ),
  );
}
