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
  }) =>
      super.noSuchMethod(
        Invocation.method(#loadNewStoresFromApi, [], {
          #lat: lat,
          #lng: lng,
          #address: address,
          #keyword: keyword,
          #range: range,
          #count: count,
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
      expect(searchProvider.errorMessage, contains('サーバーエラーが発生しました'));
      expect(searchProvider.isLoading, false);
    });
  });
}
