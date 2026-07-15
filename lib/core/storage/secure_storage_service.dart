import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String sessionKey = 'session';
  static const String customerIdKey = 'customerId';
  static const String customerOrderIdKey = 'customerOrderId';
  static const String usernameKey = 'username';
  static const String organisationKey = 'organisation';

  static Future<void> saveSession(Map<String, dynamic> session) async {
    await _storage.write(key: sessionKey, value: jsonEncode(session));

    final customerId = _extractCustomerId(session);
    await _writeOrDelete(customerIdKey, customerId);

    final customerOrderId = _extractCustomerOrderId(session) ?? customerId;
    await _writeOrDelete(customerOrderIdKey, customerOrderId);

    await _storage.write(key: 'token', value: session['token']?.toString());
  }

  static Future<Map<String, dynamic>?> getSession() async {
    final value = await _storage.read(key: sessionKey);

    if (value == null) return null;

    return jsonDecode(value);
  }

  static Future<void> saveCustomerId(String id) async {
    await _storage.write(key: customerIdKey, value: id);
  }

  static Future<String?> getCustomerId() async {
    final storedCustomerId = _cleanId(await _storage.read(key: customerIdKey));
    if (storedCustomerId != null) return storedCustomerId;

    final session = await getSession();
    if (session == null) return null;

    final customerId = _extractCustomerId(session);
    if (customerId != null) {
      await saveCustomerId(customerId);
    }

    return customerId;
  }

  static Future<String?> getCustomerOrderId() async {
    final storedCustomerOrderId = _cleanId(
      await _storage.read(key: customerOrderIdKey),
    );
    if (storedCustomerOrderId != null) return storedCustomerOrderId;

    final session = await getSession();
    if (session == null) return null;

    final customerOrderId =
        _extractCustomerOrderId(session) ?? _extractCustomerId(session);
    if (customerOrderId != null) {
      await _storage.write(key: customerOrderIdKey, value: customerOrderId);
    }

    return customerOrderId;
  }

  static Future<void> saveUsername(String username) async {
    await _storage.write(key: usernameKey, value: username);
  }

  static Future<String?> getUsername() async {
    return await _storage.read(key: usernameKey);
  }

  static Future<void> saveOrganisation(String organisation) async {
    await _storage.write(key: organisationKey, value: organisation);
  }

  static Future<String?> getOrganisation() async {
    return await _storage.read(key: organisationKey);
  }

  static Future<String?> getToken() async {
    final storedToken = _cleanId(await _storage.read(key: 'token'));
    if (storedToken != null) return storedToken;

    final session = await getSession();
    if (session == null) return null;

    return _extractToken(session);
  }

  static Future<void> logout() async {
    await _storage.deleteAll();
  }

  static Future<void> _writeOrDelete(String key, String? value) async {
    if (value != null) {
      await _storage.write(key: key, value: value);
    } else {
      await _storage.delete(key: key);
    }
  }

  static String? _extractToken(Map<String, dynamic> session) {
    for (final key in [
      'token',
      'accessToken',
      'access_token',
      'authToken',
      'jwt',
    ]) {
      final token = _cleanId(session[key]);
      if (token != null) return token;
    }

    for (final key in ['data', 'user']) {
      final value = session[key];
      if (value is Map) {
        final token = _extractToken(Map<String, dynamic>.from(value));
        if (token != null) return token;
      }
    }

    return null;
  }

  static String? _extractCustomerId(Map<String, dynamic> session) {
    for (final key in [
      'customerId',
      'customerID',
      'customer_id',
      'clientId',
      'clientID',
      'client_id',
    ]) {
      final directValue = _cleanId(session[key]);
      if (directValue != null) return directValue;
    }

    for (final key in ['customer', 'client', 'customerReference']) {
      final value = session[key];
      if (value is Map) {
        final map = Map<String, dynamic>.from(value);
        final id =
            _cleanId(map['customerId']) ??
            _cleanId(map['id']) ??
            _cleanId(map['clientId']);
        if (id != null) return id;
      }
    }

    for (final key in ['data', 'user']) {
      final value = session[key];
      if (value is Map) {
        final id = _extractCustomerId(Map<String, dynamic>.from(value));
        if (id != null) return id;
      }
    }

    return _extractCustomerOrderId(session);
  }

  static String? _extractCustomerOrderId(Map<String, dynamic> session) {
    for (final key in [
      'customerReferenceId',
      'customerReferenceID',
      'customer_reference_id',
      'customerExternalId',
      'customerExternalID',
      'customer_external_id',
      'customerCode',
      'customer_code',
      'customerRef',
      'customer_ref',
    ]) {
      final directValue = _cleanId(session[key]);
      if (directValue != null) return directValue;
    }

    for (final key in ['customer', 'client', 'customerReference']) {
      final value = session[key];
      if (value is Map) {
        final map = Map<String, dynamic>.from(value);
        final id =
            _cleanId(map['reference']) ??
            _cleanId(map['ref']) ??
            _cleanId(map['code']) ??
            _cleanId(map['externalId']) ??
            _cleanId(map['external_id']) ??
            _cleanId(map['customerReferenceId']) ??
            _cleanId(map['customer_reference_id']) ??
            _cleanId(map['customerId']) ??
            _cleanId(map['id']);
        if (id != null) return id;
      }
    }

    for (final key in ['data', 'user']) {
      final value = session[key];
      if (value is Map) {
        final id = _extractCustomerOrderId(Map<String, dynamic>.from(value));
        if (id != null) return id;
      }
    }

    return null;
  }

  static String? _cleanId(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null' || text == '0') {
      return null;
    }
    return text;
  }
}
