import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/database/schema/app_database.dart'
    hide Store;
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

  group('Transaction Management Tests - Issue #84', () {
    test('should handle batch insert with transaction rollback on error',
        () async {
      // TDD: Red - バッチ処理でエラー時にロールバックが動作することを確認

      final stores = [
        Store(
          id: 'store_1',
          name: '正常な店舗1',
          address: '東京都港区',
          lat: 35.6580339,
          lng: 139.7016358,
          status: StoreStatus.wantToGo,
          createdAt: DateTime.now(),
        ),
        Store(
          id: 'store_2',
          name: '正常な店舗2',
          address: '東京都渋谷区',
          lat: 35.6580339,
          lng: 139.7016358,
          status: StoreStatus.visited,
          createdAt: DateTime.now(),
        ),
        // 意図的に無効なデータを追加（同じIDで重複エラーを発生させる）
        Store(
          id: 'store_1', // 重複ID
          name: '重複する店舗',
          address: '東京都新宿区',
          lat: 35.6580339,
          lng: 139.7016358,
          status: StoreStatus.bad,
          createdAt: DateTime.now(),
        ),
      ];

      // バッチ挿入実行（エラーが発生するはず）
      bool errorOccurred = false;
      try {
        await datasource.insertStoresBatch(stores);
      } catch (e) {
        errorOccurred = true;
        expect(e, isA<Exception>(),
            reason: 'Should throw exception for duplicate ID');
      }

      expect(errorOccurred, isTrue,
          reason: 'Batch insert should fail with duplicate ID');

      // ロールバック確認：どの店舗も挿入されていないはず
      final allStores = await datasource.getAllStores();
      expect(allStores.isEmpty, isTrue,
          reason: 'Transaction rollback should prevent any data insertion');
    });

    test('should handle status update with store modification atomically',
        () async {
      // TDD: Red - ステータス更新と店舗情報変更が原子的に実行されることを確認

      final originalStore = Store(
        id: 'atomic_test_store',
        name: '原子性テスト店',
        address: '東京都千代田区',
        lat: 35.6580339,
        lng: 139.7016358,
        status: StoreStatus.wantToGo,
        memo: '元のメモ',
        createdAt: DateTime.now(),
      );

      await datasource.insertStore(originalStore);

      final updatedStore = originalStore.copyWith(
        status: StoreStatus.visited,
        memo: '訪問済みメモ',
      );

      // 原子的な更新実行
      await datasource.updateStoreAtomic(updatedStore);

      // 結果確認：全ての変更が反映されているはず
      final result = await datasource.getStoreById('atomic_test_store');
      expect(result, isNotNull);
      expect(result!.status, equals(StoreStatus.visited));
      expect(result.memo, equals('訪問済みメモ'));

      // データベースの整合性確認
      final allStores = await datasource.getAllStores();
      expect(allStores.length, equals(1),
          reason: 'Should have exactly one store after atomic update');
    });

    test('should handle concurrent access with proper locking', () async {
      // TDD: Red - 並行アクセス時のデータ整合性確認

      final testStore = Store(
        id: 'concurrent_test_store',
        name: '並行テスト店',
        address: '東京都品川区',
        lat: 35.6580339,
        lng: 139.7016358,
        status: StoreStatus.wantToGo,
        memo: '初期メモ',
        createdAt: DateTime.now(),
      );

      await datasource.insertStore(testStore);

      // 並行して複数の更新を実行
      final futures = <Future>[];
      for (int i = 0; i < 10; i++) {
        final updatedStore = testStore.copyWith(
          memo: '更新メモ_$i',
          status: i % 2 == 0 ? StoreStatus.visited : StoreStatus.bad,
        );
        futures.add(datasource.updateStore(updatedStore));
      }

      // 全ての更新を並行実行
      await Future.wait(futures);

      // 最終的にデータが一貫した状態であることを確認
      final result = await datasource.getStoreById('concurrent_test_store');
      expect(result, isNotNull);
      expect(result!.memo, startsWith('更新メモ_'),
          reason: 'Memo should be updated to one of the concurrent values');

      // データベースが破損していないことを確認
      final allStores = await datasource.getAllStores();
      expect(allStores.length, equals(1),
          reason:
              'Should still have exactly one store after concurrent updates');
    });
  });
}
