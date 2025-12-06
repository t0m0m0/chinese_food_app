import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/domain/entities/location.dart';
import 'package:chinese_food_app/domain/services/location_service.dart';
import 'package:chinese_food_app/presentation/providers/search_provider.dart';
import 'package:chinese_food_app/presentation/providers/store_provider.dart';

class MockStoreProvider extends Mock implements StoreProvider {
  @override
  Future<void> loadNewStoresFromApi({
    double? lat,
    double? lng,
    String? address,
    String? keyword = '中華',
    int range = 3,
    int count = 10,
    int start = 1,
  }) =>
      super.noSuchMethod(
        Invocation.method(#loadNewStoresFromApi, [], {
          #lat: lat,
          #lng: lng,
          #address: address,
          #keyword: keyword,
          #range: range,
          #count: count,
          #start: start,
        }),
        returnValue: Future<void>.value(),
      );

  @override
  List<Store> get newStores => super.noSuchMethod(
        Invocation.getter(#newStores),
        returnValue: <Store>[],
      );
}

class MockLocationService extends Mock implements LocationService {
  @override
  Future<Location> getCurrentLocation() => super.noSuchMethod(
        Invocation.method(#getCurrentLocation, []),
        returnValue: Future<Location>.value(
          Location(
            latitude: 0.0,
            longitude: 0.0,
            timestamp: DateTime.now(),
          ),
        ),
      );
}

void main() {
  group('SearchProvider Tests', () {
    late SearchProvider searchProvider;
    late MockStoreProvider mockStoreProvider;
    late MockLocationService mockLocationService;

    setUp(() {
      mockStoreProvider = MockStoreProvider();
      mockLocationService = MockLocationService();
      searchProvider = SearchProvider(
        storeProvider: mockStoreProvider,
        locationService: mockLocationService,
      );
    });

    test('should be created with initial state', () {
      // 初期状態のテスト
      expect(searchProvider.isLoading, false);
      expect(searchProvider.isGettingLocation, false);
      expect(searchProvider.errorMessage, null);
      expect(searchProvider.searchResults, isEmpty);
      expect(searchProvider.useCurrentLocation, true);
      expect(searchProvider.hasSearched, false);
    });

    test('should toggle search mode between current location and address', () {
      // 最初は現在地検索
      expect(searchProvider.useCurrentLocation, true);

      // 住所検索に切り替え
      searchProvider.setUseCurrentLocation(false);
      expect(searchProvider.useCurrentLocation, false);

      // 現在地検索に戻す
      searchProvider.setUseCurrentLocation(true);
      expect(searchProvider.useCurrentLocation, true);
    });

    test('should perform search with address', () async {
      // 住所検索モードに設定
      searchProvider.setUseCurrentLocation(false);

      // アドレス検索を実行
      await searchProvider.performSearch(address: '東京都新宿区');

      // 検索後の状態確認
      expect(searchProvider.hasSearched, true);
      expect(searchProvider.isLoading, false);
    });

    test('should call StoreProvider.loadNewStoresFromApi during search',
        () async {
      // StoreProviderのモックメソッドを設定
      when(mockStoreProvider.loadNewStoresFromApi(
        address: anyNamed('address'),
        keyword: anyNamed('keyword'),
      )).thenAnswer((_) async {});
      when(mockStoreProvider.newStores).thenReturn([]);

      // 住所検索を実行
      searchProvider.setUseCurrentLocation(false);
      await searchProvider.performSearch(address: '東京都新宿区');

      // StoreProviderのloadNewStoresFromApiが呼ばれたことを確認
      verify(mockStoreProvider.loadNewStoresFromApi(
        address: '東京都新宿区',
        keyword: '中華',
        range: 3,
        count: 20,
        start: 1,
      )).called(1);
    });

    test('should perform search with current location', () async {
      // 現在地検索の設定
      searchProvider.setUseCurrentLocation(true);

      // LocationServiceのモックを設定
      when(mockLocationService.getCurrentLocation()).thenAnswer(
        (_) async => Location(
          latitude: 35.6762,
          longitude: 139.6503,
          timestamp: DateTime.now(),
        ),
      );

      // 現在地検索を実行
      await searchProvider.performSearchWithCurrentLocation();

      // LocationServiceが呼ばれたことを確認
      verify(mockLocationService.getCurrentLocation()).called(1);

      // StoreProviderが位置情報で呼ばれたことを確認
      verify(mockStoreProvider.loadNewStoresFromApi(
        lat: 35.6762,
        lng: 139.6503,
        keyword: '中華',
        range: 3,
        count: 20,
        start: 1,
      )).called(1);
    });

    test('should handle location service error', () async {
      // LocationServiceでエラーが発生するように設定
      when(mockLocationService.getCurrentLocation())
          .thenThrow(Exception('位置情報の取得に失敗しました'));

      // 現在地検索を実行
      await searchProvider.performSearchWithCurrentLocation();

      // エラーメッセージが設定されることを確認
      expect(searchProvider.errorMessage, contains('位置情報の取得に失敗しました'));
      expect(searchProvider.isLoading, false);
      expect(searchProvider.isGettingLocation, false);
    });

    test('should handle store provider error during address search', () async {
      // StoreProviderでエラーが発生するように設定
      when(mockStoreProvider.loadNewStoresFromApi(
        address: anyNamed('address'),
        keyword: anyNamed('keyword'),
      )).thenThrow(Exception('API通信エラー'));

      // 住所検索を実行
      searchProvider.setUseCurrentLocation(false);
      await searchProvider.performSearch(address: '東京都新宿区');

      // エラーメッセージが設定されることを確認
      expect(searchProvider.errorMessage, contains('予期しないエラーが発生しました'));
      expect(searchProvider.isLoading, false);
    });

    // 検索フィルター機能のテスト
    test('should have default search filter settings', () {
      // デフォルトのフィルター設定を確認
      expect(searchProvider.searchRange, 3); // デフォルト検索範囲: 1000m
      expect(searchProvider.resultCount,
          20); // デフォルト結果数: 20件（SearchConfig.defaultPageSize）
    });

    test('should allow changing search range', () {
      // 検索範囲を変更
      searchProvider.setSearchRange(5); // 3000m
      expect(searchProvider.searchRange, 5);

      // 別の範囲に変更
      searchProvider.setSearchRange(1); // 300m
      expect(searchProvider.searchRange, 1);
    });

    test('should allow changing result count', () {
      // 結果数を変更
      searchProvider.setResultCount(20);
      expect(searchProvider.resultCount, 20);

      // 別の数に変更
      searchProvider.setResultCount(5);
      expect(searchProvider.resultCount, 5);
    });

    test('should apply filter settings in address search', () async {
      // フィルター設定を変更
      searchProvider.setSearchRange(2); // 500m
      searchProvider.setResultCount(15);

      // 住所検索を実行
      await searchProvider.performSearch(address: '東京都新宿区');

      // 正しいパラメータでAPIが呼ばれたことを確認
      verify(mockStoreProvider.loadNewStoresFromApi(
        address: '東京都新宿区',
        keyword: '中華',
        range: 2,
        count: 15,
        start: 1,
      )).called(1);
    });

    test('should apply filter settings in current location search', () async {
      // モック位置情報の設定
      when(mockLocationService.getCurrentLocation()).thenAnswer(
        (_) async => Location(
          latitude: 35.6762,
          longitude: 139.6503,
          timestamp: DateTime.now(),
        ),
      );

      // フィルター設定を変更
      searchProvider.setSearchRange(4); // 2000m
      searchProvider.setResultCount(25);

      // 現在地検索を実行
      await searchProvider.performSearchWithCurrentLocation();

      // 正しいパラメータでAPIが呼ばれたことを確認
      verify(mockStoreProvider.loadNewStoresFromApi(
        lat: 35.6762,
        lng: 139.6503,
        keyword: '中華',
        range: 4,
        count: 25,
        start: 1,
      )).called(1);
    });

    test('should validate search range values', () {
      // 有効な範囲（1-5）のテスト
      searchProvider.setSearchRange(1);
      expect(searchProvider.searchRange, 1);

      searchProvider.setSearchRange(5);
      expect(searchProvider.searchRange, 5);

      // 無効な値は変更されない
      searchProvider.setSearchRange(0);
      expect(searchProvider.searchRange, 5); // 前の値のまま

      searchProvider.setSearchRange(6);
      expect(searchProvider.searchRange, 5); // 前の値のまま
    });

    test('should validate result count values', () {
      // 有効な範囲（1-100）のテスト
      searchProvider.setResultCount(1);
      expect(searchProvider.resultCount, 1);

      searchProvider.setResultCount(100);
      expect(searchProvider.resultCount, 100);

      // 無効な値は変更されない
      searchProvider.setResultCount(0);
      expect(searchProvider.resultCount, 100); // 前の値のまま

      searchProvider.setResultCount(101);
      expect(searchProvider.resultCount, 100); // 前の値のまま
    });
  });
}
