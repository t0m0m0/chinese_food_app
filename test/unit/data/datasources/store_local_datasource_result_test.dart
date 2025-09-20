import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/database/schema/app_database.dart'
    hide Store;
import 'package:chinese_food_app/core/types/result.dart';
import 'package:chinese_food_app/data/datasources/store_local_datasource.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import '../../../helpers/test_database_factory.dart';

void main() {
  late AppDatabase database;
  late StoreLocalDatasourceImpl datasource;

  setUp(() {
    database = TestDatabaseFactory.createTestDatabase();
    datasource = StoreLocalDatasourceImpl(database);
  });

  tearDown(() async {
    await TestDatabaseFactory.disposeTestDatabase(database);
  });

  group('StoreLocalDatasource Result<T> Pattern Tests', () {
    test(
        'insertStoreResult should return Success when store is inserted successfully',
        () async {
      // TDD Red: Result<T>版の挿入メソッドテスト
      final store = Store(
        id: 'test_store_result_1',
        name: 'Result<T>テスト店',
        address: '東京都渋谷区',
        lat: 35.6580339,
        lng: 139.7016358,
        status: StoreStatus.wantToGo,
        memo: 'Result<T>テストメモ',
        createdAt: DateTime.now(),
      );

      final result = await datasource.insertStoreResult(store);

      expect(result.isSuccess, true);
      expect(result, isA<Success<void>>());

      // データが正しく挿入されているか確認
      final retrieved = await datasource.getStoreById('test_store_result_1');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, equals('Result<T>テスト店'));
    });

    test('getStoreByIdResult should return Success with store when found',
        () async {
      // TDD Red: Result<T>版の取得メソッドテスト
      final store = Store(
        id: 'test_store_result_2',
        name: 'Result<T>取得テスト店',
        address: '東京都新宿区',
        lat: 35.6812362,
        lng: 139.7649361,
        status: StoreStatus.visited,
        memo: '',
        createdAt: DateTime.now(),
      );

      await datasource.insertStore(store);

      final result = await datasource.getStoreByIdResult('test_store_result_2');

      expect(result.isSuccess, true);
      expect(result, isA<Success<Store?>>());
      final retrievedStore = (result as Success<Store?>).data;
      expect(retrievedStore, isNotNull);
      expect(retrievedStore!.name, equals('Result<T>取得テスト店'));
    });

    test(
        'getStoreByIdResult should return Success with null when store not found',
        () async {
      // TDD Red: 存在しない店舗のResult<T>版取得テスト
      final result = await datasource.getStoreByIdResult('non_existent_store');

      expect(result.isSuccess, true);
      expect(result, isA<Success<Store?>>());
      final retrievedStore = (result as Success<Store?>).data;
      expect(retrievedStore, isNull);
    });

    test('getAllStoresResult should return Success with store list', () async {
      // TDD Red: Result<T>版の全店舗取得テスト
      final store1 = Store(
        id: 'test_store_result_3',
        name: 'Result<T>店舗1',
        address: '東京都世田谷区',
        lat: 35.6464311,
        lng: 139.6532341,
        status: StoreStatus.wantToGo,
        memo: '',
        createdAt: DateTime.now(),
      );

      final store2 = Store(
        id: 'test_store_result_4',
        name: 'Result<T>店舗2',
        address: '東京都品川区',
        lat: 35.6284713,
        lng: 139.7387843,
        status: StoreStatus.visited,
        memo: '',
        createdAt: DateTime.now(),
      );

      await datasource.insertStore(store1);
      await datasource.insertStore(store2);

      final result = await datasource.getAllStoresResult();

      expect(result.isSuccess, true);
      expect(result, isA<Success<List<Store>>>());
      final stores = (result as Success<List<Store>>).data;
      expect(stores.length, greaterThanOrEqualTo(2));

      final storeNames = stores.map((s) => s.name).toList();
      expect(storeNames, containsAll(['Result<T>店舗1', 'Result<T>店舗2']));
    });

    test(
        'updateStoreResult should return Success when store is updated successfully',
        () async {
      // TDD Red: Result<T>版の更新メソッドテスト
      final originalStore = Store(
        id: 'test_store_result_5',
        name: '更新前店名',
        address: '東京都中野区',
        lat: 35.7090259,
        lng: 139.6634618,
        status: StoreStatus.wantToGo,
        memo: '更新前メモ',
        createdAt: DateTime.now(),
      );

      await datasource.insertStore(originalStore);

      final updatedStore = originalStore.copyWith(
        name: '更新後店名',
        status: StoreStatus.visited,
        memo: '更新後メモ',
      );

      final result = await datasource.updateStoreResult(updatedStore);

      expect(result.isSuccess, true);
      expect(result, isA<Success<void>>());

      // データが正しく更新されているか確認
      final retrieved = await datasource.getStoreById('test_store_result_5');
      expect(retrieved!.name, equals('更新後店名'));
      expect(retrieved.status, equals(StoreStatus.visited));
      expect(retrieved.memo, equals('更新後メモ'));
    });

    test(
        'deleteStoreResult should return Success when store is deleted successfully',
        () async {
      // TDD Red: Result<T>版の削除メソッドテスト
      final store = Store(
        id: 'test_store_result_6',
        name: '削除テスト店',
        address: '東京都杉並区',
        lat: 35.7000694,
        lng: 139.6365002,
        status: StoreStatus.bad,
        memo: '',
        createdAt: DateTime.now(),
      );

      await datasource.insertStore(store);

      final result = await datasource.deleteStoreResult('test_store_result_6');

      expect(result.isSuccess, true);
      expect(result, isA<Success<void>>());

      // データが正しく削除されているか確認
      final retrieved = await datasource.getStoreById('test_store_result_6');
      expect(retrieved, isNull);
    });

    test('getStoresByStatusResult should return Success with filtered stores',
        () async {
      // TDD Red: Result<T>版のステータス別取得テスト
      final wantToGoStore = Store(
        id: 'test_store_result_7',
        name: '行きたい店',
        address: '東京都豊島区',
        lat: 35.7295351,
        lng: 139.7156468,
        status: StoreStatus.wantToGo,
        memo: '',
        createdAt: DateTime.now(),
      );

      final visitedStore = Store(
        id: 'test_store_result_8',
        name: '訪問済み店',
        address: '東京都文京区',
        lat: 35.7081104,
        lng: 139.7586547,
        status: StoreStatus.visited,
        memo: '',
        createdAt: DateTime.now(),
      );

      await datasource.insertStore(wantToGoStore);
      await datasource.insertStore(visitedStore);

      final result =
          await datasource.getStoresByStatusResult(StoreStatus.wantToGo);

      expect(result.isSuccess, true);
      expect(result, isA<Success<List<Store>>>());
      final stores = (result as Success<List<Store>>).data;
      expect(stores.any((s) => s.name == '行きたい店'), true);
      expect(stores.every((s) => s.status == StoreStatus.wantToGo), true);
    });
  });
}
