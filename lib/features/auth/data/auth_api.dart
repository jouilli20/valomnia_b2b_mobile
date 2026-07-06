import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../domain/auth_exception.dart';
import '../domain/login_request.dart';
import '../domain/login_response.dart';

class AuthApi {
  AuthApi({Dio? dio}) : _dio = dio ?? DioClient.dio;

  static final Options _formOptions = Options(
    contentType: Headers.formUrlEncodedContentType,
  );
  static final Options _textResponseJsonOptions = Options(
    contentType: Headers.jsonContentType,
    responseType: ResponseType.plain,
  );

  final Dio _dio;

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await _post(
        ApiConstants.login,
        data: request.toJson(),
        options: _formOptions,
      );

      return LoginResponse.fromJson(_jsonMap(response.data));
    } on DioException catch (error) {
      _logDioError('LOGIN', error);
      throw AuthException(_loginErrorMessage(error));
    }
  }

  Future<void> forgotPassword({
    required String email,
    required String organization,
  }) async {
    try {
      await _post(
        ApiConstants.forgotPassword,
        data: {'email': email, 'organization': organization},
        options: _textResponseJsonOptions,
      );
    } on DioException catch (error) {
      _logDioError('FORGOT PASSWORD', error);
      throw const AuthException(
        "Impossible d'envoyer le lien de réinitialisation.",
      );
    }
  }

  Future<Response<dynamic>> _post(
    String path, {
    required Object data,
    required Options options,
  }) {
    return _dio.post(path, data: data, options: options);
  }

  static Map<String, dynamic> _jsonMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw const AuthException('Réponse serveur invalide.');
  }

  static String _loginErrorMessage(DioException error) {
    final statusCode = error.response?.statusCode;
    final redirectLocation = error.response?.headers.value('location');
    final redirectsToLoginPage =
        redirectLocation?.contains('/login/auth') == true;

    if (statusCode == 302 || redirectsToLoginPage) {
      return "Connexion refusée. Vérifiez l'organisation, l'adresse e-mail et le mot de passe.";
    }

    if (statusCode == 401 || statusCode == 403) {
      return 'Identifiants incorrects ou compte non autorisé.';
    }

    if (statusCode == null) {
      return 'Impossible de joindre le serveur. Vérifiez votre connexion.';
    }

    return 'Erreur serveur. Réessayez plus tard.';
  }

  static void _logDioError(String label, DioException error) {
    if (!kDebugMode) {
      return;
    }

    debugPrint('$label ERROR STATUS: ${error.response?.statusCode}');
    debugPrint(
      '$label ERROR LOCATION: ${error.response?.headers.value('location')}',
    );
    debugPrint('$label ERROR DATA: ${error.response?.data}');
    debugPrint('$label ERROR MESSAGE: ${error.message}');
  }

  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    try {
      await _dio.put(
        ApiConstants.resetPassword,
        queryParameters: {'token': token},
        data: {'password': password},
        options: Options(
          contentType: Headers.jsonContentType,
          followRedirects: true,
          responseType: ResponseType.plain,
          validateStatus: (status) =>
              status != null && status >= 200 && status < 400,
        ),
      );
    } on DioException catch (error) {
      _logDioError('RESET PASSWORD', error);
      throw const AuthException('Token invalide ou expire.');
    }
  }
}
