import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const _databaseName = 'valomnia_b2b.db';
  static const _databaseVersion = 1;

  Database? _database;

  Future<Database> get database async {
    final existingDatabase = _database;
    if (existingDatabase != null) return existingDatabase;

    final databasePath = await getDatabasesPath();
    final filePath = path.join(databasePath, _databaseName);

    final openedDatabase = await openDatabase(
      filePath,
      version: _databaseVersion,
      onCreate: _create,
    );
    _database = openedDatabase;
    return openedDatabase;
  }

  Future<void> _create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE offline_cache (
        cache_key TEXT PRIMARY KEY,
        json_value TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE carts (
        customer_id TEXT PRIMARY KEY,
        json_value TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }
}
