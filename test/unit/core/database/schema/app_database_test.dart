import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/database/schema/app_database.dart';
import '../../../../helpers/test_database_factory.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = TestDatabaseFactory.createTestDatabase();
  });

  tearDown(() async {
    await TestDatabaseFactory.disposeTestDatabase(database);
  });

  group('AppDatabase Schema Tests', () {
    test('should create all tables successfully', () async {
      // TDD: Green - テーブル作成が成功することを確認
      final result = await database
          .customSelect('SELECT name FROM sqlite_master WHERE type="table"')
          .get();

      final tableNames =
          result.map((row) => row.data['name'] as String).toList();
      expect(tableNames, contains('stores'));
      expect(tableNames, contains('visit_records'));
      expect(tableNames, contains('photos'));
    });

    test('should have stores table with correct schema', () async {
      // TDD: Red - storesテーブルが正しいスキーマを持つことを確認
      final result =
          await database.customSelect('PRAGMA table_info(stores)').get();

      // 期待されるカラム
      final expectedColumns = [
        'id',
        'name',
        'address',
        'lat',
        'lng',
        'image_url',
        'status',
        'memo',
        'created_at'
      ];
      final actualColumns =
          result.map((row) => row.data['name'] as String).toList();

      for (final column in expectedColumns) {
        expect(actualColumns, contains(column));
      }
    });

    test('should have visit_records table with correct foreign key', () async {
      // TDD: Red - visit_recordsテーブルが正しい外部キーを持つことを確認
      final result = await database
          .customSelect('PRAGMA foreign_key_list(visit_records)')
          .get();

      expect(result.isNotEmpty, true);
      final fkRow = result.first;
      expect(fkRow.data['table'], 'stores');
      expect(fkRow.data['from'], 'store_id');
      expect(fkRow.data['to'], 'id');
    });

    test('should have photos table with correct foreign keys', () async {
      // TDD: Red - photosテーブルが正しい外部キーを持つことを確認
      final result =
          await database.customSelect('PRAGMA foreign_key_list(photos)').get();

      expect(result.length, 2); // stores と visit_records への外部キー
    });

    test('should have appropriate indexes for performance', () async {
      // TDD: Red - パフォーマンス用のインデックスが作成されることを確認
      final result = await database
          .customSelect(
              'SELECT name FROM sqlite_master WHERE type="index" AND name NOT LIKE "sqlite_%"')
          .get();

      final indexNames =
          result.map((row) => row.data['name'] as String).toList();
      expect(indexNames, contains('idx_stores_lat_lng'));
      expect(indexNames, contains('idx_stores_status'));
      expect(indexNames, contains('idx_stores_created_at'));
      expect(indexNames, contains('idx_visit_records_store_id'));
      expect(indexNames, contains('idx_visit_records_visited_at'));
      expect(indexNames, contains('idx_photos_store_id'));
    });
  });
}
