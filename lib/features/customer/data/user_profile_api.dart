import 'dart:developer';

import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../domain/user_profile.dart';

class UserProfileApi {
  UserProfileApi({Dio? dio}) : _dio = dio ?? DioClient.dio;

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
