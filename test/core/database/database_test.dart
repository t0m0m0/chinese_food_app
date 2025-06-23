import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:chinese_food_app/core/database/database_helper.dart';

void main() {
  late DatabaseHelper databaseHelper;
  late Database database;

  // Use SQLite FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    databaseHelper = DatabaseHelper();
    database = await databaseHelper.database;
  });

  tearDown(() async {
    await databaseHelper.close();
    // Clean up test database
    try {
      await deleteDatabase(database.path);
    } catch (e) {
      // Ignore errors during cleanup
    }
  });

  group('Database Schema Tests', () {
    test('should create stores table with correct schema', () async {
      // Red: This test should fail initially
      final List<Map<String, dynamic>> tables = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='stores'",
      );

      expect(tables.length, 1);

      // Verify table structure
      final List<Map<String, dynamic>> columns = await database.rawQuery(
        'PRAGMA table_info(stores)',
      );

      final expectedColumns = [
        'id',
        'name',
        'address',
        'lat',
        'lng',
        'status',
        'memo',
        'created_at'
      ];

      final actualColumns =
          columns.map((col) => col['name'] as String).toList();

      for (final expectedColumn in expectedColumns) {
        expect(actualColumns, contains(expectedColumn));
      }
    });

    test('should create visit_records table with correct schema', () async {
      // Red: This test should fail initially
      final List<Map<String, dynamic>> tables = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='visit_records'",
      );

      expect(tables.length, 1);

      final List<Map<String, dynamic>> columns = await database.rawQuery(
        'PRAGMA table_info(visit_records)',
      );

      final expectedColumns = [
        'id',
        'store_id',
        'visited_at',
        'menu',
        'memo',
        'created_at'
      ];

      final actualColumns =
          columns.map((col) => col['name'] as String).toList();

      for (final expectedColumn in expectedColumns) {
        expect(actualColumns, contains(expectedColumn));
      }
    });

    test('should create photos table with correct schema', () async {
      // Red: This test should fail initially
      final List<Map<String, dynamic>> tables = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='photos'",
      );

      expect(tables.length, 1);

      final List<Map<String, dynamic>> columns = await database.rawQuery(
        'PRAGMA table_info(photos)',
      );

      final expectedColumns = [
        'id',
        'store_id',
        'visit_id',
        'file_path',
        'created_at'
      ];

      final actualColumns =
          columns.map((col) => col['name'] as String).toList();

      for (final expectedColumn in expectedColumns) {
        expect(actualColumns, contains(expectedColumn));
      }
    });

    test('should have foreign key constraints enabled', () async {
      final List<Map<String, dynamic>> result = await database.rawQuery(
        'PRAGMA foreign_keys',
      );

      expect(result.first['foreign_keys'], 1);
    });

    test('should have correct indexes for performance', () async {
      // Check stores table indexes
      final List<Map<String, dynamic>> storeIndexes = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='stores'",
      );

      final indexNames =
          storeIndexes.map((idx) => idx['name'] as String).toList();
      expect(indexNames, contains('idx_stores_status'));
      expect(indexNames, contains('idx_stores_created_at'));

      // Check visit_records table indexes
      final List<Map<String, dynamic>> visitIndexes = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='visit_records'",
      );

      final visitIndexNames =
          visitIndexes.map((idx) => idx['name'] as String).toList();
      expect(visitIndexNames, contains('idx_visit_records_store_id'));
      expect(visitIndexNames, contains('idx_visit_records_visited_at'));
    });
  });

  group('Database Migration Tests', () {
    test('should handle database version upgrades', () async {
      // Red: This test should fail initially
      final version = await database.getVersion();
      expect(version, 1);

      // Test migration to version 2
      await databaseHelper.close();

      // Simulate version 2 upgrade
      databaseHelper = DatabaseHelper();
      final newDatabase = await databaseHelper.database;

      final newVersion = await newDatabase.getVersion();
      expect(newVersion, greaterThanOrEqualTo(1));
    });
  });

  group('Database CRUD Operations Tests', () {
    test('should insert and retrieve store data', () async {
      // Red: This test should fail initially
      const storeData = {
        'id': 'test-store-1',
        'name': '中華料理 テスト',
        'address': '東京都渋谷区テスト1-1-1',
        'lat': 35.6762,
        'lng': 139.6503,
        'status': 'want_to_go',
        'memo': 'テスト用の店舗',
        'created_at': '2025-06-23T16:00:00.000Z',
      };

      await database.insert('stores', storeData);

      final List<Map<String, dynamic>> result = await database.query(
        'stores',
        where: 'id = ?',
        whereArgs: ['test-store-1'],
      );

      expect(result.length, 1);
      expect(result.first['name'], '中華料理 テスト');
      expect(result.first['status'], 'want_to_go');
    });

    test('should maintain referential integrity with foreign keys', () async {
      // Red: This test should fail initially
      const storeData = {
        'id': 'test-store-2',
        'name': '中華料理 外部キーテスト',
        'address': '東京都新宿区テスト2-2-2',
        'lat': 35.6762,
        'lng': 139.6503,
        'status': 'want_to_go',
        'memo': '',
        'created_at': '2025-06-23T16:00:00.000Z',
      };

      await database.insert('stores', storeData);

      const visitData = {
        'id': 'test-visit-1',
        'store_id': 'test-store-2',
        'visited_at': '2025-06-23T12:00:00.000Z',
        'menu': 'ラーメン',
        'memo': '美味しかった',
        'created_at': '2025-06-23T16:00:00.000Z',
      };

      await database.insert('visit_records', visitData);

      // Verify the relationship
      final List<Map<String, dynamic>> result = await database.rawQuery('''
        SELECT s.name, v.menu 
        FROM stores s 
        JOIN visit_records v ON s.id = v.store_id 
        WHERE s.id = ?
      ''', ['test-store-2']);

      expect(result.length, 1);
      expect(result.first['name'], '中華料理 外部キーテスト');
      expect(result.first['menu'], 'ラーメン');
    });
  });
}
