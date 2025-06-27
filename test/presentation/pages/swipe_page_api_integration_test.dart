import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:chinese_food_app/presentation/pages/swipe/swipe_page.dart';
import 'package:chinese_food_app/presentation/providers/store_provider.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/domain/entities/location.dart';
import 'package:chinese_food_app/domain/repositories/store_repository.dart';
import 'package:chinese_food_app/domain/services/location_service.dart';

/// 🔴 RED: SwipePageでHotPepper APIから新しい店舗データを表示するための失敗するテスト
void main() {
  group('SwipePage API Integration Tests', () {
    late FakeStoreRepository fakeRepository;
    late StoreProvider storeProvider;
    late MockLocationService mockLocationService;

    setUp(() {
      fakeRepository = FakeStoreRepository();
      // 初期サンプルデータを設定
      fakeRepository.setStores([
        Store(
          id: 'sample_001',
          name: 'サンプル店舗1',
          address: '東京都新宿区1-1-1',
          lat: 35.6917,
          lng: 139.7006,
          status: null,
          createdAt: DateTime.now(),
        ),
        Store(
          id: 'sample_002',
          name: 'サンプル店舗2',
          address: '東京都新宿区2-2-2',
          lat: 35.6895,
          lng: 139.6917,
          status: null,
          createdAt: DateTime.now(),
        ),
      ]);
      storeProvider = StoreProvider(repository: fakeRepository);
      mockLocationService = MockLocationService();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<StoreProvider>.value(value: storeProvider),
            Provider<LocationService>.value(value: mockLocationService),
          ],
          child: SwipePage(),
        ),
      );
    }

    testWidgets('should load API stores for swiping',
        (WidgetTester tester) async {
      // このテストは現在失敗するはずです
      // SwipePageが新しいAPI店舗データを表示できるようになる必要があります

      // API から取得される新しい店舗データをセットアップ
      final newApiStores = [
        Store(
          id: 'api_001',
          name: 'HotPepper API店舗 1',
          address: '東京都新宿区API1-1-1',
          lat: 35.6917,
          lng: 139.7006,
          status: null, // 新しい店舗なのでステータス未設定
          createdAt: DateTime.now(),
        ),
        Store(
          id: 'api_002',
          name: 'HotPepper API店舗 2',
          address: '東京都新宿区API2-2-2',
          lat: 35.6895,
          lng: 139.6917,
          status: null, // 新しい店舗なのでステータス未設定
          createdAt: DateTime.now(),
        ),
      ];

      // APIデータのみを設定
      fakeRepository.setApiStores(newApiStores);

      await tester.pumpWidget(createTestWidget());

      // 直接APIから店舗データを読み込み（サンプルデータ初期化をスキップ）
      await storeProvider.loadNewStoresFromApi(
        lat: 35.6917,
        lng: 139.7006,
        count: 10,
      );

      await tester.pumpAndSettle();

      // 期待する結果：APIデータが追加されて、店舗数が増加している
      // 初期のサンプルデータ(2つ) + APIデータ(2つ) = 4つ
      expect(storeProvider.stores.length, 4);
      expect(storeProvider.newStores.length, 4);

      // APIデータが含まれていることを確認
      bool hasApiStore1 = storeProvider.stores
          .any((store) => store.name == 'HotPepper API店舗 1');
      bool hasApiStore2 = storeProvider.stores
          .any((store) => store.name == 'HotPepper API店舗 2');
      expect(hasApiStore1, true);
      expect(hasApiStore2, true);

      // スワイプカードが表示されていることを確認
      expect(find.byType(Card), findsAtLeastNWidgets(1));
    });

    testWidgets('should show loading during API fetch',
        (WidgetTester tester) async {
      // API データ取得中のローディング表示をテスト
      final apiStores = [
        Store(
          id: 'loading_test_001',
          name: 'ローディングテスト店舗',
          address: '東京都テスト区1-1-1',
          lat: 35.6762,
          lng: 139.6503,
          status: null,
          createdAt: DateTime.now(),
        ),
      ];

      fakeRepository.setApiStores(apiStores);
      fakeRepository.setShouldDelayApiResponse(true);

      await tester.pumpWidget(createTestWidget());

      // 最初のフレームを待つ
      await tester.pump();

      // ローディング状態をテスト（位置情報取得中またはデータ読み込み中のいずれか）
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));

      // データ読み込み完了を待つ
      await tester.pumpAndSettle(Duration(seconds: 3));

      // 最終的に店舗データが表示されることを確認（サンプルデータ + APIデータ）
      expect(find.byType(Card), findsAtLeastNWidgets(1));
    });

    testWidgets('should handle API errors with retry option',
        (WidgetTester tester) async {
      // API エラー時の適切なハンドリングをテスト
      fakeRepository.setShouldThrowOnApiSearch(true);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // エラー表示の確認（実際の実装では「エラーが発生しました」）
      expect(find.text('エラーが発生しました'), findsOneWidget);
      expect(find.text('再試行'), findsOneWidget);

      // リトライボタンをタップ
      await tester.tap(find.text('再試行'));
      await tester.pumpAndSettle();
    });

    testWidgets('should refresh API data on pull-to-refresh',
        (WidgetTester tester) async {
      // プルトゥリフレッシュでAPIデータを再取得するテスト
      final initialApiStores = [
        Store(
          id: 'api_initial_001',
          name: 'プルリフレッシュテスト店舗',
          address: '東京都テスト区1-1-1',
          lat: 35.6762,
          lng: 139.6503,
          status: null,
          createdAt: DateTime.now(),
        ),
      ];

      fakeRepository.setApiStores(initialApiStores);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 初期状態の確認（RefreshIndicatorが存在することを確認）
      expect(find.byType(RefreshIndicator), findsOneWidget);

      // プルトゥリフレッシュのトリガー（RefreshIndicator自体にフリングを実行）
      await tester.fling(find.byType(RefreshIndicator), Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      // リフレッシュ機能が動作することを確認（Cardが表示されることで確認）
      expect(find.byType(Card), findsAtLeastNWidgets(1));
    });
  });
}

/// テスト用のFakeリポジトリ（APIデータ取得機能付き）
class FakeStoreRepository implements StoreRepository {
  List<Store> _stores = [];
  List<Store> _apiStores = [];
  bool _shouldThrowOnApiSearch = false;
  bool _shouldDelayApiResponse = false;

  void setStores(List<Store> stores) => _stores = List.from(stores);
  void setApiStores(List<Store> stores) => _apiStores = List.from(stores);
  void setShouldThrowOnApiSearch(bool value) => _shouldThrowOnApiSearch = value;
  void setShouldDelayApiResponse(bool value) => _shouldDelayApiResponse = value;

  @override
  Future<List<Store>> getAllStores() async => List.from(_stores);

  @override
  Future<void> insertStore(Store store) async => _stores.add(store);

  @override
  Future<void> updateStore(Store store) async {
    final index = _stores.indexWhere((s) => s.id == store.id);
    if (index != -1) _stores[index] = store;
  }

  @override
  Future<void> deleteStore(String storeId) async =>
      _stores.removeWhere((s) => s.id == storeId);

  @override
  Future<Store?> getStoreById(String storeId) async {
    try {
      return _stores.firstWhere((s) => s.id == storeId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Store>> getStoresByStatus(StoreStatus status) async =>
      _stores.where((s) => s.status == status).toList();

  @override
  Future<List<Store>> searchStores(String query) async =>
      _stores.where((s) => s.name.contains(query)).toList();

  @override
  Future<List<Store>> searchStoresFromApi({
    double? lat,
    double? lng,
    String? address,
    String? keyword,
    int range = 3,
    int count = 20,
    int start = 1,
  }) async {
    if (_shouldDelayApiResponse) {
      await Future.delayed(Duration(seconds: 1));
    }

    if (_shouldThrowOnApiSearch) {
      throw Exception('新しい店舗の取得に失敗しました');
    }

    return List.from(_apiStores);
  }
}

/// テスト用のMockLocationService
class MockLocationService implements LocationService {
  bool _shouldThrowException = false;
  Location _mockLocation = Location(
    latitude: 35.6917,
    longitude: 139.7006,
    accuracy: 5.0,
    timestamp: DateTime.now(),
  );

  void setShouldThrowException(bool value) => _shouldThrowException = value;
  void setMockLocation(Location location) => _mockLocation = location;

  @override
  Future<Location> getCurrentLocation() async {
    if (_shouldThrowException) {
      throw LocationException(
        'Mock location error',
        LocationExceptionType.locationUnavailable,
      );
    }
    return _mockLocation;
  }

  @override
  Future<bool> isLocationServiceEnabled() async => !_shouldThrowException;

  @override
  Future<bool> hasLocationPermission() async => !_shouldThrowException;

  @override
  Future<bool> requestLocationPermission() async => !_shouldThrowException;
}
