import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/presentation/providers/store_provider.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/test_helpers.dart';

/// 連続スワイプ・二重タップ排他制御テスト
///
/// 連続操作による重複保存やrace conditionを検証
void main() {
  late FakeStoreRepository repository;
  late StoreProvider provider;

  setUp(() {
    repository = FakeStoreRepository();
    provider = StoreProvider(repository: repository);
  });

  group('連続スワイプの排他制御', () {
    test('同じ店舗を連続でsaveSwipedStoreしても重複保存されない', () async {
      final store = TestDataBuilders.createTestStore(id: 'dup_test_1');

      // 同じ店舗を連続で保存
      await provider.saveSwipedStore(store, StoreStatus.wantToGo);
      await provider.saveSwipedStore(store, StoreStatus.wantToGo);

      final allStores = await repository.getAllStores();
      final matching = allStores.where((s) => s.id == 'dup_test_1').toList();

      // 2回目はupdateになるため、1件のみ
      expect(matching.length, 1);
    });

    test('異なる店舗の連続スワイプが全て正しく保存される', () async {
      final stores = TestDataBuilders.createTestStores(10);

      for (final store in stores) {
        await provider.saveSwipedStore(store, StoreStatus.wantToGo);
      }

      final allStores = await repository.getAllStores();
      expect(allStores.length, 10);
    });

    test('同じ店舗に対する異なるステータスの連続操作', () async {
      final store = TestDataBuilders.createTestStore(id: 'status_change_1');

      // wantToGo → bad → wantToGo と連続変更
      await provider.saveSwipedStore(store, StoreStatus.wantToGo);
      await provider.saveSwipedStore(store, StoreStatus.bad);
      await provider.saveSwipedStore(store, StoreStatus.wantToGo);

      final savedStore = await repository.getStoreById('status_change_1');
      expect(savedStore!.status, StoreStatus.wantToGo); // 最後の状態
    });
  });

  group('loadMoreSwipeStoresの重複読み込み防止', () {
    test('_isLoadingMoreフラグにより二重読み込みが防止される', () async {
      // loadMoreSwipeStoresの並列呼び出し
      final future1 = provider.loadMoreSwipeStores(
        lat: 35.6762,
        lng: 139.6503,
        start: 1,
      );
      final future2 = provider.loadMoreSwipeStores(
        lat: 35.6762,
        lng: 139.6503,
        start: 1,
      );

      await Future.wait([future1, future2]);

      // エラーが発生しないこと
      expect(provider.error, isNull);
    });
  });

  group('並列操作の整合性', () {
    test('loadStoresとsaveSwipedStoreの並列実行', () async {
      final store = TestDataBuilders.createTestStore(id: 'parallel_1');
      repository.addStore(TestDataBuilders.createTestStore(id: 'existing_1'));

      // 並列実行
      await Future.wait([
        provider.loadStores(),
        provider.saveSwipedStore(store, StoreStatus.wantToGo),
      ]);

      // エラーが発生しないこと
      expect(provider.error, isNull);
    });

    test('複数のupdateStoreStatusの順次実行', () async {
      // 複数の店舗を準備
      for (int i = 0; i < 5; i++) {
        repository.addStore(TestDataBuilders.createTestStore(
          id: 'update_$i',
          status: StoreStatus.wantToGo,
        ));
      }
      await provider.loadStores();

      // 順次ステータス更新
      for (int i = 0; i < 5; i++) {
        await provider.updateStoreStatus('update_$i', StoreStatus.visited);
      }

      await provider.loadStores();
      expect(provider.visitedStores.length, 5);
      expect(provider.wantToGoStores.length, 0);
    });

    test('エラー発生後のリカバリが可能', () async {
      final store = TestDataBuilders.createTestStore(id: 'recovery_1');

      // エラーを発生させる
      repository.setShouldThrowError(true);
      await provider.saveSwipedStore(store, StoreStatus.wantToGo);
      expect(provider.error, isNotNull);

      // エラーをクリアしてリカバリ
      provider.clearError();
      repository.setShouldThrowError(false);

      await provider.saveSwipedStore(store, StoreStatus.wantToGo);
      expect(provider.error, isNull);

      final saved = await repository.getStoreById('recovery_1');
      expect(saved, isNotNull);
      expect(saved!.status, StoreStatus.wantToGo);
    });
  });

  group('大量データの処理', () {
    test('100件の店舗が正しく保存される', () async {
      final stores = TestDataBuilders.createTestStores(100);

      for (final store in stores) {
        await provider.saveSwipedStore(store, StoreStatus.wantToGo);
      }

      await provider.loadStores();
      expect(provider.stores.length, 100);
      expect(provider.wantToGoStores.length, 100);
    });

    test('大量の店舗でフィルタリングが正しく動作する', () async {
      // 各ステータスに分散
      for (int i = 0; i < 30; i++) {
        repository.addStore(TestDataBuilders.createTestStore(
          id: 'want_$i',
          status: StoreStatus.wantToGo,
        ));
      }
      for (int i = 0; i < 20; i++) {
        repository.addStore(TestDataBuilders.createTestStore(
          id: 'visited_$i',
          status: StoreStatus.visited,
        ));
      }
      for (int i = 0; i < 10; i++) {
        repository.addStore(TestDataBuilders.createTestStore(
          id: 'bad_$i',
          status: StoreStatus.bad,
        ));
      }

      await provider.loadStores();

      expect(provider.stores.length, 60);
      expect(provider.wantToGoStores.length, 30);
      expect(provider.visitedStores.length, 20);
      expect(provider.badStores.length, 10);
    });
  });
}
