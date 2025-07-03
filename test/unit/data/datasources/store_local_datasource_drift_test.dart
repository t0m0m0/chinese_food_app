import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:chinese_food_app/core/database/schema/app_database.dart'
    hide Store;
import 'package:chinese_food_app/data/datasources/store_local_datasource_drift.dart';
import 'package:chinese_food_app/domain/entities/store.dart';

void main() {
  late AppDatabase database;
  late StoreLocalDatasourceDrift datasource;

  setUp(() {
    database = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
    datasource = StoreLocalDatasourceDrift(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('StoreLocalDatasourceDrift Tests', () {
    test('should insert store successfully', () async {
      // TDD: Red - Drift版での店舗挿入テスト
      final store = Store(
        id: 'test_store_1',
        name: 'テスト中華店',
        address: '東京都渋谷区',
        lat: 35.6580339,
        lng: 139.7016358,
        status: StoreStatus.wantToGo,
        memo: 'テストメモ',
        createdAt: DateTime.now(),
      );

      await datasource.insertStore(store);

      final retrieved = await datasource.getStoreById('test_store_1');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, equals('テスト中華店'));
      expect(retrieved.status, equals(StoreStatus.wantToGo));
    });

    test('should update store successfully', () async {
      // TDD: Red - Drift版での店舗更新テスト
      final store = Store(
        id: 'test_store_2',
        name: '更新前の店名',
        address: '東京都新宿区',
        lat: 35.6812362,
        lng: 139.7649361,
        status: StoreStatus.wantToGo,
        memo: '更新前メモ',
        createdAt: DateTime.now(),
      );

      await datasource.insertStore(store);

      final updatedStore = store.copyWith(
        name: '更新後の店名',
        status: StoreStatus.visited,
        memo: '更新後メモ',
      );

      await datasource.updateStore(updatedStore);

      final retrieved = await datasource.getStoreById('test_store_2');
      expect(retrieved!.name, equals('更新後の店名'));
      expect(retrieved.status, equals(StoreStatus.visited));
      expect(retrieved.memo, equals('更新後メモ'));
    });

    test('should get stores by status', () async {
      // TDD: Red - ステータス別店舗取得テスト
      final store1 = Store(
        id: 'store_want_to_go',
        name: '行きたい店',
        address: '東京都港区',
        lat: 35.6684415,
        lng: 139.6833123,
        status: StoreStatus.wantToGo,
        createdAt: DateTime.now(),
      );

      final store2 = Store(
        id: 'store_visited',
        name: '行った店',
        address: '東京都中央区',
        lat: 35.6762115,
        lng: 139.7649361,
        status: StoreStatus.visited,
        createdAt: DateTime.now(),
      );

      await datasource.insertStore(store1);
      await datasource.insertStore(store2);

      final wantToGoStores =
          await datasource.getStoresByStatus(StoreStatus.wantToGo);
      final visitedStores =
          await datasource.getStoresByStatus(StoreStatus.visited);

      expect(wantToGoStores.length, equals(1));
      expect(visitedStores.length, equals(1));
      expect(wantToGoStores.first.name, equals('行きたい店'));
      expect(visitedStores.first.name, equals('行った店'));
    });

    test('should search stores by query', () async {
      // TDD: Red - 店舗検索テスト
      final stores = [
        Store(
          id: 'ramen_store',
          name: 'ラーメン大王',
          address: '東京都豊島区池袋',
          lat: 35.7295408,
          lng: 139.7100574,
          status: StoreStatus.wantToGo,
          memo: '美味しいラーメン',
          createdAt: DateTime.now(),
        ),
        Store(
          id: 'gyoza_store',
          name: '餃子の王将',
          address: '東京都渋谷区恵比寿',
          lat: 35.6464132,
          lng: 139.7102002,
          status: StoreStatus.visited,
          memo: '餃子が絶品',
          createdAt: DateTime.now(),
        ),
        Store(
          id: 'pasta_store',
          name: 'パスタ専門店',
          address: '東京都目黒区',
          lat: 35.6334117,
          lng: 139.7156235,
          status: StoreStatus.bad,
          createdAt: DateTime.now(),
        ),
      ];

      for (final store in stores) {
        await datasource.insertStore(store);
      }

      final ramenResults = await datasource.searchStores('ラーメン');
      final poolResults = await datasource.searchStores('池袋');
      final gyozaResults = await datasource.searchStores('餃子');

      expect(ramenResults.length, equals(1));
      expect(poolResults.length, equals(1));
      expect(gyozaResults.length, equals(1));
      expect(ramenResults.first.name, equals('ラーメン大王'));
    });

    test('should delete store successfully', () async {
      // TDD: Red - 店舗削除テスト
      final store = Store(
        id: 'delete_test_store',
        name: '削除テスト店',
        address: '東京都品川区',
        lat: 35.6284713,
        lng: 139.7385753,
        status: StoreStatus.wantToGo,
        createdAt: DateTime.now(),
      );

      await datasource.insertStore(store);
      expect(await datasource.getStoreById('delete_test_store'), isNotNull);

      await datasource.deleteStore('delete_test_store');
      expect(await datasource.getStoreById('delete_test_store'), isNull);
    });
  });
}
