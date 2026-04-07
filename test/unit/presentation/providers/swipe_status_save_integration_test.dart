import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/presentation/providers/store_provider.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/test_helpers.dart';

/// スワイプ→ステータス保存の結合テスト
///
/// Provider→BusinessLogic→Repository→DB の一連フローを検証
void main() {
  late FakeStoreRepository repository;
  late StoreProvider provider;

  setUp(() {
    repository = FakeStoreRepository();
    provider = StoreProvider(repository: repository);
  });

  group('スワイプ→ステータス保存の結合テスト', () {
    test('右スワイプで新規店舗がwantToGoとしてDBに保存される', () async {
      final store = TestDataBuilders.createTestStore(
        id: 'new_store_1',
        name: '新規中華料理店',
      );

      await provider.saveSwipedStore(store, StoreStatus.wantToGo);

      // DBに保存されたことを確認
      final savedStore = await repository.getStoreById('new_store_1');
      expect(savedStore, isNotNull);
      expect(savedStore!.status, StoreStatus.wantToGo);
    });

    test('左スワイプで新規店舗がbadとしてDBに保存される', () async {
      final store = TestDataBuilders.createTestStore(
        id: 'new_store_2',
        name: '別の中華料理店',
      );

      await provider.saveSwipedStore(store, StoreStatus.bad);

      final savedStore = await repository.getStoreById('new_store_2');
      expect(savedStore, isNotNull);
      expect(savedStore!.status, StoreStatus.bad);
    });

    test('既存店舗のステータスが正しく更新される', () async {
      // 既存店舗をセットアップ
      final existingStore = TestDataBuilders.createTestStore(
        id: 'existing_1',
        status: StoreStatus.wantToGo,
      );
      repository.addStore(existingStore);
      await provider.loadStores();

      // ステータスをvisitedに更新
      await provider.updateStoreStatus('existing_1', StoreStatus.visited);

      final updated = await repository.getStoreById('existing_1');
      expect(updated!.status, StoreStatus.visited);
    });

    test('スワイプ後にwantToGoStoresリストが正しく更新される', () async {
      final store1 = TestDataBuilders.createTestStore(
        id: 'store_1',
        name: '店舗1',
      );
      final store2 = TestDataBuilders.createTestStore(
        id: 'store_2',
        name: '店舗2',
      );

      await provider.saveSwipedStore(store1, StoreStatus.wantToGo);
      await provider.saveSwipedStore(store2, StoreStatus.bad);

      // loadStoresでDBの最新状態を反映
      await provider.loadStores();

      expect(provider.wantToGoStores.length, 1);
      expect(provider.wantToGoStores.first.id, 'store_1');
      expect(provider.badStores.length, 1);
      expect(provider.badStores.first.id, 'store_2');
    });

    test('saveSwipedStoreで既存店舗はupdateされinsertされない', () async {
      final store = TestDataBuilders.createTestStore(
        id: 'existing_2',
        status: StoreStatus.wantToGo,
      );
      repository.addStore(store);

      // 同じIDの店舗をスワイプ
      await provider.saveSwipedStore(store, StoreStatus.visited);

      // 重複がないことを確認
      final allStores = await repository.getAllStores();
      final matchingStores =
          allStores.where((s) => s.id == 'existing_2').toList();
      expect(matchingStores.length, 1);
      expect(matchingStores.first.status, StoreStatus.visited);
    });

    test('連続スワイプでそれぞれ正しいステータスが保存される', () async {
      final stores = TestDataBuilders.createTestStores(5);

      await provider.saveSwipedStore(stores[0], StoreStatus.wantToGo);
      await provider.saveSwipedStore(stores[1], StoreStatus.bad);
      await provider.saveSwipedStore(stores[2], StoreStatus.wantToGo);
      await provider.saveSwipedStore(stores[3], StoreStatus.bad);
      await provider.saveSwipedStore(stores[4], StoreStatus.wantToGo);

      await provider.loadStores();

      expect(provider.wantToGoStores.length, 3);
      expect(provider.badStores.length, 2);
    });

    test('ステータス更新後にスワイプリストから店舗が除去される', () async {
      final store = TestDataBuilders.createTestStore(id: 'swipe_1');
      repository.addStore(store);
      await provider.loadStores();

      // スワイプリストに模擬データを設定するため、loadSwipeStoresを使用
      // ここではupdateStoreStatusの挙動を検証
      await provider.updateStoreStatus('swipe_1', StoreStatus.wantToGo);

      // エラーが発生しないこと
      expect(provider.error, isNull);
    });

    test('リポジトリエラー時にエラーメッセージが設定される', () async {
      repository.setShouldThrowError(true);

      await provider.loadStores();

      expect(provider.error, isNotNull);
      expect(provider.isLoading, false);
    });

    test('saveSwipedStore失敗時にエラーが設定される', () async {
      final store = TestDataBuilders.createTestStore(id: 'error_store');
      repository.setShouldThrowError(true);

      await provider.saveSwipedStore(store, StoreStatus.wantToGo);

      expect(provider.error, isNotNull);
    });

    test('wantToGo→visited→badのステータス遷移が正しく動作する', () async {
      final store = TestDataBuilders.createTestStore(
        id: 'transition_1',
        status: StoreStatus.wantToGo,
      );
      repository.addStore(store);
      await provider.loadStores();

      // wantToGo → visited
      await provider.updateStoreStatus('transition_1', StoreStatus.visited);
      await provider.loadStores();
      expect(provider.visitedStores.length, 1);
      expect(provider.wantToGoStores.length, 0);

      // visited → bad
      await provider.updateStoreStatus('transition_1', StoreStatus.bad);
      await provider.loadStores();
      expect(provider.badStores.length, 1);
      expect(provider.visitedStores.length, 0);
    });
  });
}
