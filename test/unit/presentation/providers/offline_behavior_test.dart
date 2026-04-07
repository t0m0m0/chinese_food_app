import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/presentation/providers/store_provider.dart';
import 'package:chinese_food_app/presentation/providers/search_provider.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/test_helpers.dart';

/// オフライン動作テスト
///
/// ネットワーク切断時の検索・表示挙動を検証
void main() {
  group('オフライン時のStoreProvider', () {
    late FakeStoreRepository repository;
    late StoreProvider provider;

    setUp(() {
      repository = FakeStoreRepository();
      provider = StoreProvider(repository: repository);
    });

    test('API検索がネットワークエラーで失敗した場合、エラーメッセージが設定される', () async {
      repository.setShouldThrowError(
        true,
        Exception('ネットワークエラー: 接続が利用できません'),
      );

      await provider.loadNewStoresFromApi(
        lat: 35.6762,
        lng: 139.6503,
      );

      expect(provider.error, isNotNull);
      expect(provider.isLoading, false);
    });

    test('API検索失敗後もローカルDB読み込みは可能', () async {
      // まずローカルにデータを追加
      final store = TestDataBuilders.createTestStore(
        id: 'local_1',
        status: StoreStatus.wantToGo,
      );
      repository.addStore(store);

      // API検索を失敗させる
      repository.setShouldThrowError(true);
      await provider.loadNewStoresFromApi(lat: 35.6762, lng: 139.6503);
      expect(provider.error, isNotNull);

      // エラーをクリアしてローカル読み込み
      repository.setShouldThrowError(false);
      await provider.loadStores();

      expect(provider.error, isNull);
      expect(provider.stores.length, 1);
      expect(provider.stores.first.id, 'local_1');
    });

    test('スワイプ店舗取得がネットワークエラーで失敗した場合', () async {
      repository.setShouldThrowError(true);

      await provider.loadSwipeStores(
        lat: 35.6762,
        lng: 139.6503,
      );

      expect(provider.error, isNotNull);
      expect(provider.swipeStores, isEmpty);
    });

    test('ローカルデータの保存はオフラインでも動作する', () async {
      final store = TestDataBuilders.createTestStore(id: 'offline_save_1');

      await provider.addStore(store);

      expect(provider.error, isNull);

      // 確認のためloadStores
      await provider.loadStores();
      expect(provider.stores.length, 1);
    });

    test('ステータス更新はオフラインでも動作する（ローカルDB操作）', () async {
      final store = TestDataBuilders.createTestStore(
        id: 'offline_update_1',
        status: StoreStatus.wantToGo,
      );
      repository.addStore(store);
      await provider.loadStores();

      await provider.updateStoreStatus(
        'offline_update_1',
        StoreStatus.visited,
      );

      expect(provider.error, isNull);
      final updated = await repository.getStoreById('offline_update_1');
      expect(updated!.status, StoreStatus.visited);
    });
  });

  group('オフライン時のSearchProvider', () {
    late FakeStoreRepository storeRepository;
    late StoreProvider storeProvider;
    late FakeLocationService locationService;
    late SearchProvider searchProvider;

    setUp(() {
      storeRepository = FakeStoreRepository();
      storeProvider = StoreProvider(repository: storeRepository);
      locationService = FakeLocationService();
      searchProvider = SearchProvider(
        storeProvider: storeProvider,
        locationService: locationService,
      );
    });

    test('位置情報取得後にAPI検索が失敗した場合のエラーメッセージ', () async {
      locationService.setCurrentLocation(
        TestDataBuilders.createTestLocation(),
      );
      storeRepository.setShouldThrowError(true);

      await searchProvider.performSearchWithCurrentLocation();

      // StoreProviderのエラーが伝播する
      expect(storeProvider.error, isNotNull);
    });

    test('位置情報サービス無効時のエラーメッセージ', () async {
      locationService.setServiceEnabled(false);

      await searchProvider.performSearchWithCurrentLocation();

      expect(searchProvider.errorMessage, isNotNull);
      expect(searchProvider.isLoading, false);
    });

    test('住所検索でネットワークエラーが発生した場合', () async {
      storeRepository.setShouldThrowError(true);

      await searchProvider.performSearch(address: '東京都渋谷区');

      // StoreProviderがエラーを設定
      expect(storeProvider.error, isNotNull);
    });
  });
}
