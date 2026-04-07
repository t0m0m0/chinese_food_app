import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/presentation/providers/store_provider.dart';
import 'package:chinese_food_app/presentation/providers/search_provider.dart';
import 'package:chinese_food_app/presentation/providers/area_search_provider.dart';
import 'package:chinese_food_app/domain/entities/area.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/test_helpers.dart';

/// 空状態（Empty State）テスト
///
/// 店舗0件時のマイメニュー・スワイプ画面の動作を検証
void main() {
  group('StoreProvider 空状態テスト', () {
    late FakeStoreRepository repository;
    late StoreProvider provider;

    setUp(() {
      repository = FakeStoreRepository();
      provider = StoreProvider(repository: repository);
    });

    test('初期状態で全リストが空', () {
      expect(provider.stores, isEmpty);
      expect(provider.wantToGoStores, isEmpty);
      expect(provider.visitedStores, isEmpty);
      expect(provider.badStores, isEmpty);
      expect(provider.newStores, isEmpty);
      expect(provider.searchResults, isEmpty);
      expect(provider.swipeStores, isEmpty);
    });

    test('空のDBからloadStoresしてもエラーにならない', () async {
      await provider.loadStores();

      expect(provider.error, isNull);
      expect(provider.stores, isEmpty);
      expect(provider.isLoading, false);
    });

    test('空のDBでwantToGoStoresが空リストを返す', () async {
      await provider.loadStores();

      expect(provider.wantToGoStores, isEmpty);
      expect(provider.wantToGoStores, isA<List<Store>>());
    });

    test('空のDBでvisitedStoresが空リストを返す', () async {
      await provider.loadStores();

      expect(provider.visitedStores, isEmpty);
      expect(provider.visitedStores, isA<List<Store>>());
    });

    test('空のDBでbadStoresが空リストを返す', () async {
      await provider.loadStores();

      expect(provider.badStores, isEmpty);
      expect(provider.badStores, isA<List<Store>>());
    });

    test('全店舗削除後にリストが空になる', () async {
      // データを追加
      repository.addStore(TestDataBuilders.createTestStore(id: 'del_1'));
      repository.addStore(TestDataBuilders.createTestStore(id: 'del_2'));
      await provider.loadStores();
      expect(provider.stores.length, 2);

      // 全削除
      await provider.deleteAllStores();

      expect(provider.stores, isEmpty);
      expect(provider.wantToGoStores, isEmpty);
      expect(provider.error, isNull);
    });

    test('API検索結果0件でスワイプリストが空のままinfoMessageが設定される', () async {
      // FakeStoreRepositoryは空なので検索結果も0件
      await provider.loadSwipeStores(
        lat: 35.6762,
        lng: 139.6503,
      );

      expect(provider.swipeStores, isEmpty);
      expect(provider.infoMessage, isNotNull);
    });

    test('空状態からの店舗追加が正しく動作する', () async {
      expect(provider.stores, isEmpty);

      final store = TestDataBuilders.createTestStore(id: 'first_store');
      await provider.addStore(store);
      await provider.loadStores();

      expect(provider.stores.length, 1);
      expect(provider.stores.first.id, 'first_store');
    });
  });

  group('SearchProvider 空状態テスト', () {
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

    test('初期状態でhasSearchedがfalse', () {
      expect(searchProvider.hasSearched, false);
      expect(searchProvider.searchResults, isEmpty);
    });

    test('検索実行後に結果0件でhasSearchedがtrue', () async {
      await searchProvider.performSearch(address: '存在しない住所');

      expect(searchProvider.hasSearched, true);
      expect(searchProvider.searchResults, isEmpty);
    });

    test('現在地検索で結果0件の場合', () async {
      locationService.setCurrentLocation(
        TestDataBuilders.createTestLocation(),
      );

      await searchProvider.performSearchWithCurrentLocation();

      expect(searchProvider.hasSearched, true);
      expect(searchProvider.searchResults, isEmpty);
      expect(searchProvider.isLoading, false);
    });

    test('結果0件時にhasMoreResultsがfalse', () async {
      await searchProvider.performSearch(address: '空結果');

      expect(searchProvider.hasMoreResults, false);
    });
  });

  group('AreaSearchProvider 空状態テスト', () {
    late FakeStoreRepository storeRepository;
    late StoreProvider storeProvider;
    late AreaSearchProvider areaSearchProvider;

    setUp(() {
      storeRepository = FakeStoreRepository();
      storeProvider = StoreProvider(repository: storeRepository);
      areaSearchProvider = AreaSearchProvider(storeProvider: storeProvider);
    });

    test('初期状態で都道府県未選択', () {
      expect(areaSearchProvider.selectedPrefecture, isNull);
      expect(areaSearchProvider.selectedCity, isNull);
      expect(areaSearchProvider.canSearch, false);
      expect(areaSearchProvider.hasSearched, false);
    });

    test('初期状態で利用可能な市区町村が空', () {
      expect(areaSearchProvider.availableCities, isEmpty);
    });

    test('エリア検索で結果0件の場合', () async {
      const tokyo = Prefecture(code: '13', name: '東京都');
      areaSearchProvider.selectPrefecture(tokyo);

      // FakeStoreRepositoryは空なので0件
      // selectPrefectureで自動検索が走る
      await Future.delayed(Duration.zero); // 非同期完了待ち

      expect(areaSearchProvider.hasSearched, true);
      expect(areaSearchProvider.searchResults, isEmpty);
    });
  });
}
