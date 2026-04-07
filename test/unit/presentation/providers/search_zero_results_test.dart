import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/presentation/providers/store_provider.dart';
import 'package:chinese_food_app/presentation/providers/search_provider.dart';
import 'package:chinese_food_app/presentation/providers/area_search_provider.dart';
import 'package:chinese_food_app/domain/entities/area.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/test_helpers.dart';

/// 検索結果0件テスト
///
/// 各種検索で結果0件時の動作を検証
void main() {
  group('SearchProvider 検索結果0件', () {
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

    test('住所検索で結果0件の場合、hasSearchedがtrueで結果が空', () async {
      await searchProvider.performSearch(address: '存在しない町');

      expect(searchProvider.hasSearched, true);
      expect(searchProvider.searchResults, isEmpty);
      expect(searchProvider.isLoading, false);
      expect(searchProvider.errorMessage, isNull);
    });

    test('現在地検索で結果0件の場合', () async {
      locationService.setCurrentLocation(
        TestDataBuilders.createTestLocation(
          latitude: 0.0,
          longitude: 0.0, // 海の上
        ),
      );

      await searchProvider.performSearchWithCurrentLocation();

      expect(searchProvider.hasSearched, true);
      expect(searchProvider.searchResults, isEmpty);
    });

    test('結果0件時にページネーションが無効になる', () async {
      await searchProvider.performSearch(address: '空結果住所');

      expect(searchProvider.hasMoreResults, false);

      // loadMoreResultsを呼んでも何も起きない
      await searchProvider.loadMoreResults();
      expect(searchProvider.searchResults, isEmpty);
    });

    test('結果0件後に別の検索を実行できる', () async {
      // 最初の検索: 0件
      await searchProvider.performSearch(address: '空結果');
      expect(searchProvider.searchResults, isEmpty);

      // データを追加して再検索
      storeRepository.addStore(
        TestDataBuilders.createTestStore(
          id: 'found_1',
          name: '見つかる店',
          address: '東京都渋谷区',
        ),
      );

      await searchProvider.performSearch(address: '東京');

      expect(searchProvider.hasSearched, true);
      // FakeStoreRepositoryのsearchStoresFromApiはtake(count)を返すので
      // データがあれば結果が返る
    });

    test('空文字での検索はperformSearchが呼ばれない', () async {
      // address が空文字の場合のハンドリング
      await searchProvider.performSearch(address: '');

      // 住所が空なのでAPIは呼ばれないが、hasSearchedはtrue
      expect(searchProvider.hasSearched, true);
      expect(searchProvider.isLoading, false);
    });
  });

  group('AreaSearchProvider 検索結果0件', () {
    late FakeStoreRepository storeRepository;
    late StoreProvider storeProvider;
    late AreaSearchProvider areaSearchProvider;

    setUp(() {
      storeRepository = FakeStoreRepository();
      storeProvider = StoreProvider(repository: storeRepository);
      areaSearchProvider = AreaSearchProvider(storeProvider: storeProvider);
    });

    test('都道府県選択後に結果0件', () async {
      const prefecture = Prefecture(code: '47', name: '沖縄県');
      areaSearchProvider.selectPrefecture(prefecture);

      // 自動検索が非同期で実行される
      await Future.delayed(Duration.zero);

      expect(areaSearchProvider.hasSearched, true);
      expect(areaSearchProvider.searchResults, isEmpty);
    });

    test('市区町村選択後に結果0件', () async {
      const prefecture = Prefecture(code: '13', name: '東京都');
      areaSearchProvider.selectPrefecture(prefecture);
      await Future.delayed(Duration.zero);

      const city = City(
        prefectureCode: '13',
        code: '13101',
        name: '千代田区',
      );
      areaSearchProvider.selectCity(city);
      await Future.delayed(Duration.zero);

      expect(areaSearchProvider.hasSearched, true);
      expect(areaSearchProvider.searchResults, isEmpty);
    });

    test('結果0件時にloadMoreResultsが実行されない', () async {
      const prefecture = Prefecture(code: '13', name: '東京都');
      areaSearchProvider.selectPrefecture(prefecture);
      await Future.delayed(Duration.zero);

      // 結果が0件なのでhasMoreResultsがfalse
      await areaSearchProvider.loadMoreResults();
      expect(areaSearchProvider.searchResults, isEmpty);
    });
  });

  group('StoreProvider スワイプ店舗0件', () {
    late FakeStoreRepository repository;
    late StoreProvider provider;

    setUp(() {
      repository = FakeStoreRepository();
      provider = StoreProvider(repository: repository);
    });

    test('スワイプ店舗0件でinfoMessageが設定される', () async {
      await provider.loadSwipeStores(
        lat: 35.6762,
        lng: 139.6503,
      );

      expect(provider.swipeStores, isEmpty);
      expect(provider.infoMessage, isNotNull);
    });

    test('全店舗がスワイプ済みの場合もスワイプリストが空', () async {
      // 全てステータス付きの店舗を追加
      repository.addStore(TestDataBuilders.createTestStore(
        id: 'swiped_1',
        status: StoreStatus.wantToGo,
      ));
      repository.addStore(TestDataBuilders.createTestStore(
        id: 'swiped_2',
        status: StoreStatus.bad,
      ));
      await provider.loadStores();

      // loadSwipeStoresはAPIから取得するが、FakeRepositoryは空を返す
      await provider.loadSwipeStores(
        lat: 35.6762,
        lng: 139.6503,
      );

      expect(provider.swipeStores, isEmpty);
    });

    test('radiusMeters指定でも0件時にinfoMessageが設定される', () async {
      await provider.loadSwipeStoresWithRadius(
        lat: 35.6762,
        lng: 139.6503,
        radiusMeters: 1000,
      );

      expect(provider.swipeStores, isEmpty);
      expect(provider.infoMessage, isNotNull);
    });
  });
}
