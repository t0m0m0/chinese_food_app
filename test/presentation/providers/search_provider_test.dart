import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:chinese_food_app/domain/services/location_service.dart';
import 'package:chinese_food_app/presentation/providers/search_provider.dart';
import 'package:chinese_food_app/presentation/providers/store_provider.dart';

class MockStoreProvider extends Mock implements StoreProvider {}

class MockLocationService extends Mock implements LocationService {}

void main() {
  group('SearchProvider Tests', () {
    late SearchProvider searchProvider;
    late MockStoreProvider mockStoreProvider;
    late MockLocationService mockLocationService;

    setUp(() {
      mockStoreProvider = MockStoreProvider();
      mockLocationService = MockLocationService();
      // この行は失敗する - SearchProviderがまだ実装されていない
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

      // 住所検索に切り替え - このメソッドはまだ実装されていないので失敗する
      searchProvider.setUseCurrentLocation(false);
      expect(searchProvider.useCurrentLocation, false);

      // 現在地検索に戻す
      searchProvider.setUseCurrentLocation(true);
      expect(searchProvider.useCurrentLocation, true);
    });

    test('should perform search with address', () async {
      // 住所検索モードに設定
      searchProvider.setUseCurrentLocation(false);

      // アドレス検索を実行 - このメソッドはまだ実装されていないので失敗する
      await searchProvider.performSearch(address: '東京都新宿区');

      // 検索後の状態確認
      expect(searchProvider.hasSearched, true);
      expect(searchProvider.isLoading, false);
    });
  });
}
