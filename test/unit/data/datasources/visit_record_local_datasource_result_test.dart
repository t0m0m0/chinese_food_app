import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/database/schema/app_database.dart'
    hide Store, VisitRecord;
import 'package:chinese_food_app/core/types/result.dart';
import 'package:chinese_food_app/data/datasources/visit_record_local_datasource.dart';
import 'package:chinese_food_app/data/datasources/store_local_datasource.dart';
import 'package:chinese_food_app/domain/entities/visit_record.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import '../../../helpers/test_database_factory.dart';

/// テスト用店舗データを作成
Future<void> createTestStores(StoreLocalDatasourceImpl storeDatasource) async {
  final testStores = [
    Store(
      id: 'store_123',
      name: 'テスト店舗123',
      address: '東京都渋谷区',
      lat: 35.6580339,
      lng: 139.7016358,
      status: StoreStatus.wantToGo,
      memo: '',
      createdAt: DateTime.now(),
    ),
    Store(
      id: 'store_456',
      name: 'テスト店舗456',
      address: '東京都新宿区',
      lat: 35.6812362,
      lng: 139.7649361,
      status: StoreStatus.wantToGo,
      memo: '',
      createdAt: DateTime.now(),
    ),
    Store(
      id: 'store_789',
      name: 'テスト店舗789',
      address: '東京都世田谷区',
      lat: 35.6464311,
      lng: 139.6532341,
      status: StoreStatus.wantToGo,
      memo: '',
      createdAt: DateTime.now(),
    ),
    Store(
      id: 'store_101',
      name: 'テスト店舗101',
      address: '東京都品川区',
      lat: 35.6284713,
      lng: 139.7387843,
      status: StoreStatus.wantToGo,
      memo: '',
      createdAt: DateTime.now(),
    ),
    Store(
      id: 'store_result_test',
      name: 'テスト店舗Result',
      address: '東京都中野区',
      lat: 35.7090259,
      lng: 139.6634618,
      status: StoreStatus.wantToGo,
      memo: '',
      createdAt: DateTime.now(),
    ),
    Store(
      id: 'other_store',
      name: 'その他店舗',
      address: '東京都杉並区',
      lat: 35.7000694,
      lng: 139.6365002,
      status: StoreStatus.wantToGo,
      memo: '',
      createdAt: DateTime.now(),
    ),
    Store(
      id: 'store_update',
      name: '更新用店舗',
      address: '東京都豊島区',
      lat: 35.7295351,
      lng: 139.7156468,
      status: StoreStatus.wantToGo,
      memo: '',
      createdAt: DateTime.now(),
    ),
    Store(
      id: 'store_delete',
      name: '削除用店舗',
      address: '東京都文京区',
      lat: 35.7081104,
      lng: 139.7586547,
      status: StoreStatus.wantToGo,
      memo: '',
      createdAt: DateTime.now(),
    ),
  ];

  for (final store in testStores) {
    await storeDatasource.insertStore(store);
  }
}

void main() {
  late AppDatabase database;
  late VisitRecordLocalDatasourceImpl datasource;
  late StoreLocalDatasourceImpl storeDatasource;

  setUp(() async {
    database = TestDatabaseFactory.createTestDatabase();
    datasource = VisitRecordLocalDatasourceImpl(database);
    storeDatasource = StoreLocalDatasourceImpl(database);

    // テスト用店舗データを事前作成（Foreign Key制約対応）
    await createTestStores(storeDatasource);
  });

  tearDown(() async {
    await TestDatabaseFactory.disposeTestDatabase(database);
  });

  group('VisitRecordLocalDatasource Result<T> Pattern Tests', () {
    test(
        'insertVisitRecordResult should return Success when visit record is inserted successfully',
        () async {
      // TDD Red: Result<T>版の訪問記録挿入テスト
      final visitRecord = VisitRecord(
        id: 'test_visit_result_1',
        storeId: 'store_123',
        visitedAt: DateTime.now(),
        menu: '餃子セット',
        memo: 'Result<T>テスト訪問記録',
        createdAt: DateTime.now(),
      );

      final result = await datasource.insertVisitRecordResult(visitRecord);

      expect(result.isSuccess, true);
      expect(result, isA<Success<void>>());

      // データが正しく挿入されているか確認
      final retrieved =
          await datasource.getVisitRecordById('test_visit_result_1');
      expect(retrieved, isNotNull);
      expect(retrieved!.menu, equals('餃子セット'));
    });

    test(
        'getVisitRecordByIdResult should return Success with visit record when found',
        () async {
      // TDD Red: Result<T>版の訪問記録取得テスト
      final visitRecord = VisitRecord(
        id: 'test_visit_result_2',
        storeId: 'store_456',
        visitedAt: DateTime.now().subtract(const Duration(days: 7)),
        menu: '麻婆豆腐定食',
        memo: 'Result<T>取得テスト',
        createdAt: DateTime.now(),
      );

      await datasource.insertVisitRecord(visitRecord);

      final result =
          await datasource.getVisitRecordByIdResult('test_visit_result_2');

      expect(result.isSuccess, true);
      expect(result, isA<Success<VisitRecord?>>());
      final retrievedRecord = (result as Success<VisitRecord?>).data;
      expect(retrievedRecord, isNotNull);
      expect(retrievedRecord!.menu, equals('麻婆豆腐定食'));
    });

    test(
        'getVisitRecordByIdResult should return Success with null when visit record not found',
        () async {
      // TDD Red: 存在しない訪問記録のResult<T>版取得テスト
      final result =
          await datasource.getVisitRecordByIdResult('non_existent_visit');

      expect(result.isSuccess, true);
      expect(result, isA<Success<VisitRecord?>>());
      final retrievedRecord = (result as Success<VisitRecord?>).data;
      expect(retrievedRecord, isNull);
    });

    test(
        'getAllVisitRecordsResult should return Success with visit record list',
        () async {
      // TDD Red: Result<T>版の全訪問記録取得テスト
      final visitRecord1 = VisitRecord(
        id: 'test_visit_result_3',
        storeId: 'store_789',
        visitedAt: DateTime.now(),
        menu: 'チャーハン',
        memo: '',
        createdAt: DateTime.now(),
      );

      final visitRecord2 = VisitRecord(
        id: 'test_visit_result_4',
        storeId: 'store_101',
        visitedAt: DateTime.now().subtract(const Duration(days: 3)),
        menu: '酢豚',
        memo: 'Result<T>テスト2',
        createdAt: DateTime.now(),
      );

      await datasource.insertVisitRecord(visitRecord1);
      await datasource.insertVisitRecord(visitRecord2);

      final result = await datasource.getAllVisitRecordsResult();

      expect(result.isSuccess, true);
      expect(result, isA<Success<List<VisitRecord>>>());
      final visitRecords = (result as Success<List<VisitRecord>>).data;
      expect(visitRecords.length, greaterThanOrEqualTo(2));

      final menus = visitRecords.map((r) => r.menu).toList();
      expect(menus, containsAll(['チャーハン', '酢豚']));
    });

    test(
        'getVisitRecordsByStoreIdResult should return Success with filtered visit records',
        () async {
      // TDD Red: Result<T>版の店舗別訪問記録取得テスト
      const targetStoreId = 'store_result_test';

      final visitRecord1 = VisitRecord(
        id: 'test_visit_result_5',
        storeId: targetStoreId,
        visitedAt: DateTime.now(),
        menu: 'エビチリ',
        memo: '対象店舗の記録1',
        createdAt: DateTime.now(),
      );

      final visitRecord2 = VisitRecord(
        id: 'test_visit_result_6',
        storeId: targetStoreId,
        visitedAt: DateTime.now().subtract(const Duration(days: 1)),
        menu: '青椒肉絲',
        memo: '対象店舗の記録2',
        createdAt: DateTime.now(),
      );

      final visitRecord3 = VisitRecord(
        id: 'test_visit_result_7',
        storeId: 'other_store',
        visitedAt: DateTime.now(),
        menu: '別店舗のメニュー',
        memo: '',
        createdAt: DateTime.now(),
      );

      await datasource.insertVisitRecord(visitRecord1);
      await datasource.insertVisitRecord(visitRecord2);
      await datasource.insertVisitRecord(visitRecord3);

      final result =
          await datasource.getVisitRecordsByStoreIdResult(targetStoreId);

      expect(result.isSuccess, true);
      expect(result, isA<Success<List<VisitRecord>>>());
      final filteredRecords = (result as Success<List<VisitRecord>>).data;
      expect(filteredRecords.every((r) => r.storeId == targetStoreId), true);

      final menus = filteredRecords.map((r) => r.menu).toList();
      expect(menus, containsAll(['エビチリ', '青椒肉絲']));
      expect(menus, isNot(contains('別店舗のメニュー')));
    });

    test(
        'updateVisitRecordResult should return Success when visit record is updated successfully',
        () async {
      // TDD Red: Result<T>版の訪問記録更新テスト
      final originalRecord = VisitRecord(
        id: 'test_visit_result_8',
        storeId: 'store_update',
        visitedAt: DateTime.now().subtract(const Duration(days: 10)),
        menu: '更新前メニュー',
        memo: '更新前メモ',
        createdAt: DateTime.now(),
      );

      await datasource.insertVisitRecord(originalRecord);

      final updatedRecord = originalRecord.copyWith(
        menu: '更新後メニュー',
        memo: '更新後メモ',
      );

      final result = await datasource.updateVisitRecordResult(updatedRecord);

      expect(result.isSuccess, true);
      expect(result, isA<Success<void>>());

      // データが正しく更新されているか確認
      final retrieved =
          await datasource.getVisitRecordById('test_visit_result_8');
      expect(retrieved!.menu, equals('更新後メニュー'));
      expect(retrieved.memo, equals('更新後メモ'));
    });

    test(
        'deleteVisitRecordResult should return Success when visit record is deleted successfully',
        () async {
      // TDD Red: Result<T>版の訪問記録削除テスト
      final visitRecord = VisitRecord(
        id: 'test_visit_result_9',
        storeId: 'store_delete',
        visitedAt: DateTime.now(),
        menu: '削除テストメニュー',
        memo: '',
        createdAt: DateTime.now(),
      );

      await datasource.insertVisitRecord(visitRecord);

      final result =
          await datasource.deleteVisitRecordResult('test_visit_result_9');

      expect(result.isSuccess, true);
      expect(result, isA<Success<void>>());

      // データが正しく削除されているか確認
      final retrieved =
          await datasource.getVisitRecordById('test_visit_result_9');
      expect(retrieved, isNull);
    });
  });
}
