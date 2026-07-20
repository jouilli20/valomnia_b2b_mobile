import 'dart:developer';

import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../domain/user_profile.dart';

class UserProfileApi {
  UserProfileApi({Dio? dio}) : _dio = dio ?? DioClient.dio;

  static final Options _formOptions = Options(
    contentType: Headers.formUrlEncodedContentType,
  );

  final Dio _dio;

  Future<UserProfile> getConnectedUserProfile({
    required String username,
  }) async {
    final normalizedUsername = username.trim();
    if (normalizedUsername.isEmpty) {
      throw ArgumentError.value(username, 'username', 'Username vide.');
    }

    final response = await _dio.get(
      ApiConstants.userCheck,
      queryParameters: {
        'baseUrl': ApiConstants.tenantBaseUrl,
        'username': normalizedUsername,
        'email': normalizedUsername,
      },
    );

    log('USER PROFILE STATUS: ${response.statusCode}', name: 'UserProfileApi');
    log('USER PROFILE RESPONSE: ${response.data}', name: 'UserProfileApi');

    return UserProfile.fromJson(_responseMap(response.data));
  }

  Future<UserProfile> updateConnectedUser({
    required String organisation,
    required String email,
    required String oldPassword,
    required String newPassword,
    required String userName,
  }) async {
    final normalizedOrganisation = organisation.trim();
    final normalizedEmail = email.trim();
    final oldPasswordText = oldPassword;
    final newPasswordText = newPassword;
    final normalizedUserName = userName.trim();

    if (normalizedOrganisation.isEmpty) {
      throw ArgumentError.value(
        organisation,
        'organisation',
        'Organisation vide.',
      );
    }
    if (normalizedEmail.isEmpty) {
      throw ArgumentError.value(email, 'email', 'E-mail vide.');
    }
    if (oldPasswordText.trim().isEmpty) {
      throw ArgumentError.value(
        oldPassword,
        'oldPassword',
        'Ancien mot de passe vide.',
      );
    }
    if (newPasswordText.trim().isEmpty) {
      throw ArgumentError.value(
        newPassword,
        'newPassword',
        'Nouveau mot de passe vide.',
      );
    }
    if (normalizedUserName.isEmpty) {
      throw ArgumentError.value(userName, 'userName', 'Nom utilisateur vide.');
    }

    Response<dynamic> response;
    try {
      response = await _dio.post(
        ApiConstants.updateUser,
        data: {
          'organisation': normalizedOrganisation,
          'email': normalizedEmail,
          'oldPassword': oldPasswordText,
          'newPassword': newPasswordText,
          'userName': normalizedUserName,
        },
        options: await _options(),
      );
    } on DioException catch (error) {
      log(
        'UPDATE USER ERROR STATUS: ${error.response?.statusCode}',
        name: 'UserProfileApi',
      );
      log(
        'UPDATE USER ERROR DATA: ${error.response?.data}',
        name: 'UserProfileApi',
      );
      throw UserProfileUpdateException.fromDio(error);
    }

    log('UPDATE USER STATUS: ${response.statusCode}', name: 'UserProfileApi');
    log('UPDATE USER RESPONSE: ${response.data}', name: 'UserProfileApi');

    return UserProfile.fromJson(_responseMap(response.data)).mergeFallback(
      UserProfile(name: normalizedUserName, email: normalizedEmail),
    );
  }

  Future<Options> _options() async {
    final token = await SecureStorageService.getToken();
    final authorization = token == null
        ? null
        : token.toLowerCase().startsWith('bearer ')
        ? token
        : 'Bearer $token';

    final headers = <String, dynamic>{};
    if (authorization != null) {
      headers['Authorization'] = authorization;
    }

    return _formOptions.copyWith(headers: headers);
  }
}

class UserProfileUpdateException implements Exception {
  const UserProfileUpdateException(this.message);

  factory UserProfileUpdateException.fromDio(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data?.toString().trim();

    if (statusCode == 404) {
      return UserProfileUpdateException(
        data == null || data.isEmpty
            ? 'Service changement de mot de passe introuvable. Verifiez la session et reessayez.'
            : 'Service changement de mot de passe introuvable: $data',
      );
    }

    if (statusCode == 401 || statusCode == 403) {
      return const UserProfileUpdateException(
        'Session expiree. Reconnectez-vous puis reessayez.',
      );
    }

    if (statusCode == null) {
      return const UserProfileUpdateException(
        'Impossible de joindre le serveur. Verifiez votre connexion.',
      );
    }

    return UserProfileUpdateException(
      data == null || data.isEmpty
          ? 'Changement de mot de passe rejete par le serveur ($statusCode).'
          : 'Changement de mot de passe rejete par le serveur ($statusCode): $data',
    );
  }

  final String message;

  @override
  String toString() => message;
}

Map<String, dynamic> _responseMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;

  if (data is Map) return Map<String, dynamic>.from(data);

  if (data is List && data.isNotEmpty) {
    final first = data.first;
    if (first is Map<String, dynamic>) return first;
    if (first is Map) return Map<String, dynamic>.from(first);
  }

  throw StateError('Reponse profil utilisateur invalide.');
}
