import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String sessionKey = 'session';
  static const String customerIdKey = 'customerId';
  static const String usernameKey = 'username';
  static const String organisationKey = 'organisation';

  static Future<void> saveSession(Map<String, dynamic> session) async {
    await _storage.write(key: sessionKey, value: jsonEncode(session));

    await _storage.write(
      key: customerIdKey,
      value: session['customerId']?.toString(),
    );

    await _storage.write(
      key: 'token',
      value: session['token']?.toString(),
    );
  }

  static Future<Map<String, dynamic>?> getSession() async {
    final value = await _storage.read(key: sessionKey);

    if (value == null) return null;

    return jsonDecode(value);
  }

  static Future<void> saveCustomerId(String id) async {
    await _storage.write(
      key: customerIdKey,
      value: id,
    );
  }

  static Future<String?> getCustomerId() async {
    return await _storage.read(key: customerIdKey);
  }

  static Future<void> saveUsername(String username) async {
    await _storage.write(
      key: usernameKey,
      value: username,
    );
  }

  static Future<String?> getUsername() async {
    return await _storage.read(key: usernameKey);
  }

  static Future<void> saveOrganisation(String organisation) async {
    await _storage.write(
      key: organisationKey,
      value: organisation,
    );
  }

  static Future<String?> getOrganisation() async {
    return await _storage.read(key: organisationKey);
  }

  static Future<void> logout() async {
    await _storage.deleteAll();
  }
}
