import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/presentation/providers/search_provider.dart';
import 'package:chinese_food_app/presentation/providers/store_provider.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/test_helpers.dart';

/// 位置情報権限拒否フローテスト
///
/// 権限拒否→再要求→永久拒否の各パスを検証
void main() {
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

  group('位置情報権限拒否フロー', () {
    test('権限が許可されている場合、正常に位置情報を取得できる', () async {
      locationService.setPermissionGranted(true);
      locationService.setServiceEnabled(true);
      locationService.setCurrentLocation(
        TestDataBuilders.createTestLocation(),
      );

      await searchProvider.performSearchWithCurrentLocation();

      expect(searchProvider.errorMessage, isNull);
      expect(searchProvider.isLoading, false);
    });

    test('権限拒否時にエラーメッセージが表示される', () async {
      locationService.setPermissionGranted(false);

      await searchProvider.performSearchWithCurrentLocation();

      expect(searchProvider.errorMessage, isNotNull);
      expect(searchProvider.errorMessage, contains('位置情報'));
      expect(searchProvider.isLoading, false);
      expect(searchProvider.isGettingLocation, false);
    });

    test('位置情報サービス無効時にエラーメッセージが表示される', () async {
      locationService.setServiceEnabled(false);

      await searchProvider.performSearchWithCurrentLocation();

      expect(searchProvider.errorMessage, isNotNull);
      expect(searchProvider.isLoading, false);
    });

    test('位置情報取得中にカスタムエラーが発生した場合', () async {
      locationService.setShouldThrowError(
        true,
        Exception('Location permission permanently denied'),
      );

      await searchProvider.performSearchWithCurrentLocation();

      expect(searchProvider.errorMessage, isNotNull);
      expect(searchProvider.isLoading, false);
      expect(searchProvider.isGettingLocation, false);
    });

    test('権限拒否後に住所検索へフォールバックできる', () async {
      // まず位置情報検索が失敗
      locationService.setPermissionGranted(false);
      await searchProvider.performSearchWithCurrentLocation();
      expect(searchProvider.errorMessage, isNotNull);

      // 住所検索に切り替え
      searchProvider.setUseCurrentLocation(false);
      await searchProvider.performSearch(address: '東京都渋谷区');

      // 住所検索は正常に動作（APIエラーがなければ）
      expect(searchProvider.isLoading, false);
      expect(searchProvider.hasSearched, true);
    });

    test('権限拒否後に再度位置情報検索を試みた場合', () async {
      // 最初の試行: 拒否
      locationService.setPermissionGranted(false);
      await searchProvider.performSearchWithCurrentLocation();
      expect(searchProvider.errorMessage, isNotNull);

      // 権限が許可された後の再試行
      locationService.setPermissionGranted(true);
      locationService.setCurrentLocation(
        TestDataBuilders.createTestLocation(),
      );
      await searchProvider.performSearchWithCurrentLocation();

      // エラーなしで完了
      expect(searchProvider.errorMessage, isNull);
      expect(searchProvider.isLoading, false);
    });

    test('isGettingLocationフラグが適切に管理される', () async {
      // 正常系：位置情報取得後にfalseになる
      locationService.setCurrentLocation(
        TestDataBuilders.createTestLocation(),
      );
      await searchProvider.performSearchWithCurrentLocation();
      expect(searchProvider.isGettingLocation, false);

      // エラー系：エラー後もfalseになる
      locationService.setShouldThrowError(true);
      await searchProvider.performSearchWithCurrentLocation();
      expect(searchProvider.isGettingLocation, false);
    });
  });
}
