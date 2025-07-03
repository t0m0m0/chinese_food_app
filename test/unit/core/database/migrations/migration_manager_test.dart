import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:chinese_food_app/core/database/migrations/migration_manager.dart';
import 'package:chinese_food_app/core/database/schema/app_database.dart';

void main() {
  late AppDatabase database;
  late MigrationManager migrationManager;

  setUp(() {
    // マイグレーションテスト用に空のデータベースを作成
    final connection = DatabaseConnection(NativeDatabase.memory());
    database = AppDatabase(connection);
    migrationManager = MigrationManager(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('MigrationManager Tests', () {
    test('should handle migration from version 1 to 2', () async {
      // TDD: Red - Version 1->2のマイグレーションテスト（image_urlカラム追加）

      // Version 1のテーブル構造を手動作成（image_urlなし）
      await database.customStatement('DROP TABLE IF EXISTS stores');
      await database.customStatement('''
        CREATE TABLE stores (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          address TEXT NOT NULL,
          lat REAL NOT NULL,
          lng REAL NOT NULL,
          status TEXT NOT NULL,
          memo TEXT DEFAULT '',
          created_at TEXT NOT NULL
        )
      ''');

      // Version 1からVersion 2へのマイグレーション実行
      await migrationManager.migrateFromVersion1To2();

      // image_urlカラムが追加されていることを確認
      final result =
          await database.customSelect('PRAGMA table_info(stores)').get();
      final columnNames =
          result.map((row) => row.data['name'] as String).toList();
      expect(columnNames, contains('image_url'));
    });

    test('should validate current schema version', () async {
      // TDD: Red - 現在のスキーマバージョンが正しいことを確認
      final version = await migrationManager.getCurrentSchemaVersion();
      expect(version, equals(2));
    });

    test('should create all required indexes', () async {
      // TDD: Red - 必要なインデックスが全て作成されることを確認
      await migrationManager.createPerformanceIndexes();

      final result = await database
          .customSelect(
              'SELECT name FROM sqlite_master WHERE type="index" AND name NOT LIKE "sqlite_%"')
          .get();

      final indexNames =
          result.map((row) => row.data['name'] as String).toList();
      expect(indexNames, contains('idx_stores_lat_lng'));
      expect(indexNames, contains('idx_visit_records_store_id'));
      expect(indexNames, contains('idx_photos_store_id'));
    });

    test('should enable foreign key constraints', () async {
      // TDD: Red - 外部キー制約が有効化されることを確認
      await migrationManager.enableForeignKeyConstraints();

      final result = await database.customSelect('PRAGMA foreign_keys').get();
      final foreignKeysEnabled = result.first.data.values.first as int;
      expect(foreignKeysEnabled, equals(1));
    });

    test('should validate migration chain integrity', () async {
      // TDD: Red - マイグレーションチェーンの整合性チェック
      final isValid = await migrationManager.validateMigrationChain();
      expect(isValid, isTrue);
    });
  });
}
