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
      onOpen: (db) async {
        // 外部キー制約を有効化
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Storesテーブル
    await db.execute('''
      CREATE TABLE stores (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL CHECK(length(name) > 0),
        address TEXT NOT NULL CHECK(length(address) > 0),
        lat REAL NOT NULL CHECK(lat BETWEEN -90 AND 90),
        lng REAL NOT NULL CHECK(lng BETWEEN -180 AND 180),
        image_url TEXT,
        status TEXT NOT NULL CHECK(status IN ('want_to_go', 'visited', 'bad')),
        memo TEXT DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');

    // VisitRecordsテーブル
    await db.execute('''
      CREATE TABLE visit_records (
        id TEXT PRIMARY KEY,
        store_id TEXT NOT NULL,
        visited_at TEXT NOT NULL,
        menu TEXT NOT NULL CHECK(length(menu) > 0),
        memo TEXT DEFAULT '',
        created_at TEXT NOT NULL,
        FOREIGN KEY (store_id) REFERENCES stores (id) ON DELETE CASCADE
      )
    ''');

    // Photosテーブル
    await db.execute('''
      CREATE TABLE photos (
        id TEXT PRIMARY KEY,
        store_id TEXT NOT NULL,
        visit_id TEXT,
        file_path TEXT NOT NULL CHECK(length(file_path) > 0),
        created_at TEXT NOT NULL,
        FOREIGN KEY (store_id) REFERENCES stores (id) ON DELETE CASCADE,
        FOREIGN KEY (visit_id) REFERENCES visit_records (id) ON DELETE SET NULL
      )
    ''');

    // インデックス作成
    await db.execute('CREATE INDEX idx_stores_status ON stores (status)');
    await db
        .execute('CREATE INDEX idx_stores_created_at ON stores (created_at)');
    await db.execute(
        'CREATE INDEX idx_visit_records_store_id ON visit_records (store_id)');
    await db.execute(
        'CREATE INDEX idx_visit_records_visited_at ON visit_records (visited_at)');
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
    // storesテーブルにimage_urlカラムを追加
    await db.execute('ALTER TABLE stores ADD COLUMN image_url TEXT');

    // 画像URL検索のパフォーマンス向上のためのインデックス追加
    // 将来的に「画像がある店舗」の検索が頻繁になる場合に有効
    await db.execute(
        'CREATE INDEX idx_stores_image_url ON stores (image_url) WHERE image_url IS NOT NULL');
  }

  Future<void> _upgradeToVersion3(Database db) async {
    // 例: 将来の拡張用
    // await db.execute('ALTER TABLE stores ADD COLUMN phone TEXT');
  }

  /// バッチ処理用のトランザクション実行
  ///
  /// [action]: トランザクション内で実行する処理
  ///
  /// Returns: アクションの実行結果
  ///
  /// Throws: [Exception] トランザクション実行に失敗した場合
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    try {
      final db = await database;
      return await db.transaction(action);
    } on DatabaseException catch (e) {
      throw Exception('Transaction failed: ${e.toString()}');
    } catch (e) {
      throw Exception('Unexpected error during transaction: ${e.toString()}');
    }
  }

  /// パフォーマンス統計取得
  Future<Map<String, dynamic>> getDatabaseStats() async {
    final db = await database;
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'",
    );

    final stats = <String, dynamic>{
      'version': await db.getVersion(),
      'tables': tables.length,
      'foreign_keys_enabled':
          (await db.rawQuery('PRAGMA foreign_keys')).first['foreign_keys'] == 1,
    };

    return stats;
  }

  /// データベースの整合性チェック
  ///
  /// Returns:
  ///   - true: データベースに問題なし
  ///   - false: データベースに破損または問題あり
  Future<bool> checkIntegrity() async {
    try {
      final db = await database;
      final result = await db.rawQuery('PRAGMA integrity_check');
      return result.isNotEmpty && result.first['integrity_check'] == 'ok';
    } on DatabaseException {
      // データベースエラーの場合は整合性に問題があると判断
      return false;
    } catch (_) {
      // その他の予期しないエラーも整合性問題として扱う
      return false;
    }
  }

  Future<void> close() async {
    if (_database != null) {
      final db = await database;
      await db.close();
      _database = null;
    }
  }
}
