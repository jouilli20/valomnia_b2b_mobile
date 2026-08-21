import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/storage/app_database.dart';
import '../domain/cart_item.dart';

class CartRepository {
  const CartRepository({AppDatabase? database}) : _database = database;

  final AppDatabase? _database;

  AppDatabase get _appDatabase => _database ?? AppDatabase.instance;

  Future<CustomerCart> loadCart(String customerId) async {
    final normalizedCustomerId = _normalizeCustomerId(customerId);
    final rawCart =
        await _loadSqliteCart(normalizedCustomerId) ??
        await _loadPreferencesCart(normalizedCustomerId);

    if (rawCart == null || rawCart.trim().isEmpty) {
      return CustomerCart.empty(normalizedCustomerId);
    }

    try {
      final decoded = jsonDecode(rawCart);
      if (decoded is Map) {
        return CustomerCart.fromJson(
          normalizedCustomerId,
          Map<String, dynamic>.from(decoded),
        );
      }
    } catch (_) {
      await _deleteCart(normalizedCustomerId);
    }

    return CustomerCart.empty(normalizedCustomerId);
  }

  Future<void> saveCart(CustomerCart cart) async {
    final normalizedCustomerId = _normalizeCustomerId(cart.customerId);

    if (cart.isEmpty) {
      await _deleteCart(normalizedCustomerId);
      return;
    }

    final jsonCart = jsonEncode(
      cart.copyWith(customerId: normalizedCustomerId).toJson(),
    );

    try {
      final db = await _openDatabase();
      await db.insert('carts', {
        'customer_id': normalizedCustomerId,
        'json_value': jsonCart,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_storageKey(normalizedCustomerId), jsonCart);
    }
  }

  String _storageKey(String customerId) {
    return 'cart:$customerId';
  }

  Future<String?> _loadSqliteCart(String customerId) async {
    try {
      final db = await _openDatabase();
      final rows = await db.query(
        'carts',
        columns: ['json_value'],
        where: 'customer_id = ?',
        whereArgs: [customerId],
        limit: 1,
      );

      if (rows.isEmpty) return null;
      return rows.first['json_value'] as String;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _loadPreferencesCart(String customerId) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_storageKey(customerId));
  }

  Future<void> _deleteCart(String customerId) async {
    try {
      final db = await _openDatabase();
      await db.delete(
        'carts',
        where: 'customer_id = ?',
        whereArgs: [customerId],
      );
    } catch (_) {
      // Keep deleting the legacy fallback storage below.
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey(customerId));
  }

  Future<Database> _openDatabase() {
    return _appDatabase.database.timeout(const Duration(milliseconds: 500));
  }

  String _normalizeCustomerId(String customerId) {
    final normalized = customerId.trim();
    if (normalized.isEmpty) {
      throw StateError('Customer ID introuvable.');
    }

    return normalized;
  }
}
