import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../domain/auth_exception.dart';
import '../domain/login_request.dart';
import '../domain/login_response.dart';

class AuthApi {
  final Dio _dio = DioClient.dio;

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: request.toJson(),
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      return LoginResponse.fromJson(_jsonMap(response.data));
    } on DioException catch (error) {
      _logLoginError(error);
      throw AuthException(_loginErrorMessage(error));
    }
  }

  Map<String, dynamic> _jsonMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw const AuthException('Réponse serveur invalide.');
  }

  String _loginErrorMessage(DioException error) {
    final statusCode = error.response?.statusCode;
    final redirectLocation = error.response?.headers.value('location');
    final redirectsToLoginPage =
        redirectLocation?.contains('/login/auth') == true;

    if (statusCode == 302 || redirectsToLoginPage) {
      return 'Connexion refusée. Vérifiez l’organisation, l’adresse e-mail et le mot de passe.';
    }

    if (statusCode == 401 || statusCode == 403) {
      return 'Identifiants incorrects ou compte non autorisé.';
    }

    if (statusCode == null) {
      return 'Impossible de joindre le serveur. Vérifiez votre connexion.';
    }

    return 'Erreur serveur. Réessayez plus tard.';
  }

  void _logLoginError(DioException error) {
    debugPrint('LOGIN ERROR STATUS: ${error.response?.statusCode}');
    debugPrint(
      'LOGIN ERROR LOCATION: ${error.response?.headers.value('location')}',
    );
    debugPrint('LOGIN ERROR DATA: ${error.response?.data}');
    debugPrint('LOGIN ERROR MESSAGE: ${error.message}');
  }
}
