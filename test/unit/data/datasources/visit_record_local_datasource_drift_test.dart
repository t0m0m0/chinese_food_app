import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:chinese_food_app/core/database/schema/app_database.dart'
    hide VisitRecord;
import 'package:chinese_food_app/data/datasources/visit_record_local_datasource_drift.dart';
import 'package:chinese_food_app/domain/entities/visit_record.dart';

void main() {
  late AppDatabase database;
  late VisitRecordLocalDatasourceDrift datasource;

  setUp(() async {
    database = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
    datasource = VisitRecordLocalDatasourceDrift(database);

    // 外部キー制約のためにテスト用のstoreレコードを作成
    await database.into(database.stores).insert(StoresCompanion(
          id: const Value('store_1'),
          name: const Value('テスト店舗1'),
          address: const Value('テスト住所1'),
          lat: const Value(35.6812362),
          lng: const Value(139.7649361),
          status: const Value('want_to_go'),
          memo: const Value(''),
          createdAt: Value(DateTime.now().toIso8601String()),
        ));

    await database.into(database.stores).insert(StoresCompanion(
          id: const Value('store_2'),
          name: const Value('テスト店舗2'),
          address: const Value('テスト住所2'),
          lat: const Value(35.6580339),
          lng: const Value(139.7016358),
          status: const Value('want_to_go'),
          memo: const Value(''),
          createdAt: Value(DateTime.now().toIso8601String()),
        ));
  });

  tearDown(() async {
    await database.close();
  });

  group('VisitRecordLocalDatasourceDrift Tests', () {
    test('should insert visit record successfully', () async {
      // TDD: Red - Drift版での訪問記録挿入テスト
      final visitRecord = VisitRecord(
        id: 'visit_1',
        storeId: 'store_1',
        visitedAt: DateTime.now().subtract(const Duration(days: 1)),
        menu: 'チャーハン',
        memo: '美味しかった',
        createdAt: DateTime.now(),
      );

      await datasource.insertVisitRecord(visitRecord);

      final retrieved = await datasource.getVisitRecordById('visit_1');
      expect(retrieved, isNotNull);
      expect(retrieved!.menu, equals('チャーハン'));
      expect(retrieved.memo, equals('美味しかった'));
    });

    test('should get all visit records', () async {
      // TDD: Red - 全訪問記録取得テスト
      final records = [
        VisitRecord(
          id: 'visit_1',
          storeId: 'store_1',
          visitedAt: DateTime(2023, 12, 1),
          menu: 'ラーメン',
          memo: '醤油ラーメン',
          createdAt: DateTime.now(),
        ),
        VisitRecord(
          id: 'visit_2',
          storeId: 'store_2',
          visitedAt: DateTime(2023, 12, 2),
          menu: '餃子',
          createdAt: DateTime.now(),
        ),
      ];

      for (final record in records) {
        await datasource.insertVisitRecord(record);
      }

      final allRecords = await datasource.getAllVisitRecords();
      expect(allRecords.length, equals(2));

      // 訪問日時の降順でソートされていることを確認
      expect(allRecords.first.visitedAt.isAfter(allRecords.last.visitedAt),
          isTrue);
    });

    test('should get visit records by store ID', () async {
      // TDD: Red - 店舗ID別訪問記録取得テスト
      final records = [
        VisitRecord(
          id: 'visit_1',
          storeId: 'store_1',
          visitedAt: DateTime(2023, 12, 1),
          menu: 'ラーメン',
          createdAt: DateTime.now(),
        ),
        VisitRecord(
          id: 'visit_2',
          storeId: 'store_1',
          visitedAt: DateTime(2023, 12, 2),
          menu: '餃子',
          createdAt: DateTime.now(),
        ),
        VisitRecord(
          id: 'visit_3',
          storeId: 'store_2',
          visitedAt: DateTime(2023, 12, 3),
          menu: 'チャーハン',
          createdAt: DateTime.now(),
        ),
      ];

      for (final record in records) {
        await datasource.insertVisitRecord(record);
      }

      final store1Records =
          await datasource.getVisitRecordsByStoreId('store_1');
      expect(store1Records.length, equals(2));
      expect(store1Records.every((r) => r.storeId == 'store_1'), isTrue);
    });

    test('should update visit record successfully', () async {
      // TDD: Red - 訪問記録更新テスト
      final original = VisitRecord(
        id: 'visit_update',
        storeId: 'store_1',
        visitedAt: DateTime.now().subtract(const Duration(days: 1)),
        menu: '元のメニュー',
        memo: '元のメモ',
        createdAt: DateTime.now(),
      );

      await datasource.insertVisitRecord(original);

      final updated = original.copyWith(
        menu: '更新されたメニュー',
        memo: '更新されたメモ',
      );

      await datasource.updateVisitRecord(updated);

      final retrieved = await datasource.getVisitRecordById('visit_update');
      expect(retrieved!.menu, equals('更新されたメニュー'));
      expect(retrieved.memo, equals('更新されたメモ'));
    });

    test('should delete visit record successfully', () async {
      // TDD: Red - 訪問記録削除テスト
      final visitRecord = VisitRecord(
        id: 'visit_delete',
        storeId: 'store_1',
        visitedAt: DateTime.now().subtract(const Duration(days: 1)),
        menu: '削除テストメニュー',
        createdAt: DateTime.now(),
      );

      await datasource.insertVisitRecord(visitRecord);
      expect(await datasource.getVisitRecordById('visit_delete'), isNotNull);

      await datasource.deleteVisitRecord('visit_delete');
      expect(await datasource.getVisitRecordById('visit_delete'), isNull);
    });

    test('should return null for non-existent visit record', () async {
      // TDD: Red - 存在しない訪問記録の取得テスト
      final result = await datasource.getVisitRecordById('non_existent');
      expect(result, isNull);
    });
  });
}
