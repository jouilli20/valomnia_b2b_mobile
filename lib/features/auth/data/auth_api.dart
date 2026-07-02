import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../domain/login_request.dart';
import '../domain/login_response.dart';

class AuthApi {
  final Dio _dio = DioClient.dio;

  Future<LoginResponse> login(LoginRequest request) async {
    final response = await _dio.post(
      ApiConstants.login,
      data: FormData.fromMap(request.toJson()),
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );

    return LoginResponse.fromJson(response.data);
  }
}
