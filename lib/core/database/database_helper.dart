import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../constants/app_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, AppConstants.databaseName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Storesテーブル
    await db.execute('''
      CREATE TABLE stores (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        lat REAL NOT NULL,
        lng REAL NOT NULL,
        status TEXT,
        memo TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // VisitRecordsテーブル
    await db.execute('''
      CREATE TABLE visit_records (
        id TEXT PRIMARY KEY,
        store_id TEXT NOT NULL,
        visited_at TEXT NOT NULL,
        menu TEXT NOT NULL,
        memo TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (store_id) REFERENCES stores (id)
      )
    ''');

    // Photosテーブル
    await db.execute('''
      CREATE TABLE photos (
        id TEXT PRIMARY KEY,
        store_id TEXT NOT NULL,
        visit_id TEXT,
        file_path TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (store_id) REFERENCES stores (id),
        FOREIGN KEY (visit_id) REFERENCES visit_records (id)
      )
    ''');

    // インデックス作成
    await db.execute('CREATE INDEX idx_stores_status ON stores (status)');
    await db.execute(
        'CREATE INDEX idx_visit_records_store_id ON visit_records (store_id)');
    await db.execute('CREATE INDEX idx_photos_store_id ON photos (store_id)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    for (int version = oldVersion + 1; version <= newVersion; version++) {
      switch (version) {
        case 2:
          await _upgradeToVersion2(db);
          break;
        case 3:
          await _upgradeToVersion3(db);
          break;
        default:
          throw UnsupportedError('Unsupported database version: $version');
      }
    }
  }

  Future<void> _upgradeToVersion2(Database db) async {
    // 例: storesテーブルにratingカラムを追加
    await db
        .execute('ALTER TABLE stores ADD COLUMN rating REAL DEFAULT 0.0');

    // 新しいインデックスを追加
    await db.execute('CREATE INDEX idx_stores_rating ON stores (rating)');
  }

  Future<void> _upgradeToVersion3(Database db) async {
    // 例: 将来の拡張用
    // await db.execute('ALTER TABLE stores ADD COLUMN phone TEXT');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}