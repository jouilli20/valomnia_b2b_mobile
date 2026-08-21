import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'app_database.dart';

final localCacheRepositoryProvider = Provider<LocalCacheRepository>((ref) {
  return LocalCacheRepository(AppDatabase.instance);
});

class LocalCacheRepository {
  const LocalCacheRepository(this._database);

  final AppDatabase _database;

  Future<void> saveJson(String key, Object? value) async {
    try {
      final db = await _openDatabase();
      await db.insert('offline_cache', {
        'cache_key': key,
        'json_value': jsonEncode(value),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {
      // Cache failures must never break the online user flow.
    }
  }

  Future<dynamic> readJson(String key) async {
    try {
      final db = await _openDatabase();
      final rows = await db.query(
        'offline_cache',
        columns: ['json_value'],
        where: 'cache_key = ?',
        whereArgs: [key],
        limit: 1,
      );

      if (rows.isEmpty) return null;
      return jsonDecode(rows.first['json_value'] as String);
    } catch (_) {
      return null;
    }
  }

  Future<Database> _openDatabase() {
    return _database.database.timeout(const Duration(milliseconds: 500));
  }
}
