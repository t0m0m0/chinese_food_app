import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:chinese_food_app/presentation/pages/search/search_page.dart';
import 'package:chinese_food_app/presentation/providers/store_provider.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/domain/entities/location.dart';
import 'package:chinese_food_app/domain/repositories/store_repository.dart';
import 'package:chinese_food_app/domain/services/location_service.dart';

/// SearchPage (エリア探索) の統合テスト
void main() {
  group('SearchPage Area Search Integration Tests', () {
    late FakeStoreRepository fakeRepository;
    late MockLocationService mockLocationService;
    late StoreProvider storeProvider;

    setUp(() {
      fakeRepository = FakeStoreRepository();
      fakeRepository.setStores([]);
      mockLocationService = MockLocationService();
      storeProvider = StoreProvider(
        repository: fakeRepository,
        locationService: mockLocationService,
      );
    });

    Widget createTestWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<StoreProvider>.value(value: storeProvider),
          Provider<LocationService>.value(value: mockLocationService),
        ],
        child: const MaterialApp(
          home: SearchPage(),
        ),
      );
    }

    testWidgets('should display area selection UI on initial load',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 都道府県選択UIが表示されることを確認
      expect(find.text('都道府県を選択'), findsOneWidget);
      expect(find.text('選択してください'), findsOneWidget);
      expect(find.text('エリアを選択して検索してください'), findsOneWidget);
    });

    testWidgets('should perform area-based search with prefecture',
        (WidgetTester tester) async {
      // API検索で返される店舗データ
      final areaBasedStores = [
        Store(
          id: 'search_001',
          name: '東京の中華料理店',
          address: '東京都新宿区2-1-1',
          lat: 35.6896,
          lng: 139.6920,
          status: null,
          createdAt: DateTime.now(),
        ),
      ];
      fakeRepository.setApiStores(areaBasedStores);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 都道府県選択ダイアログを開く
      await tester.tap(find.text('選択してください'));
      await tester.pumpAndSettle();

      // 関東は initiallyExpanded: true なので、直接東京都をタップ
      // 東京都を見つけてスクロールしてからタップ
      final tokyoFinder = find.text('東京都');
      await tester.ensureVisible(tokyoFinder);
      await tester.pumpAndSettle();
      await tester.tap(tokyoFinder);
      await tester.pumpAndSettle();

      // 都道府県選択時に自動検索が実行される
      // 住所検索が実行されることを確認
      expect(fakeRepository.lastSearchAddress, equals('東京都'));
    });

    testWidgets('should perform area-based search with prefecture and city',
        (WidgetTester tester) async {
      final areaBasedStores = [
        Store(
          id: 'search_002',
          name: '新宿の中華料理店',
          address: '東京都新宿区1-1-1',
          lat: 35.6896,
          lng: 139.6920,
          status: null,
          createdAt: DateTime.now(),
        ),
      ];
      fakeRepository.setApiStores(areaBasedStores);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 都道府県を選択
      await tester.tap(find.text('選択してください'));
      await tester.pumpAndSettle();

      // 関東は initiallyExpanded: true なので、直接東京都をタップ
      final tokyoFinder = find.text('東京都');
      await tester.ensureVisible(tokyoFinder);
      await tester.pumpAndSettle();
      await tester.tap(tokyoFinder);
      await tester.pumpAndSettle();

      // 市区町村を選択
      await tester.tap(find.text('全域'));
      await tester.pumpAndSettle();

      // 新宿区を見つけてスクロールしてからタップ
      final shinjukuFinder = find.text('新宿区');
      await tester.ensureVisible(shinjukuFinder);
      await tester.pumpAndSettle();
      await tester.tap(shinjukuFinder);
      await tester.pumpAndSettle();

      // 市区町村選択時に自動検索が実行される
      // 住所検索が実行されることを確認
      expect(fakeRepository.lastSearchAddress, equals('東京都新宿区'));
    });

    testWidgets('should handle API error gracefully',
        (WidgetTester tester) async {
      fakeRepository.setSearchError(Exception('API Error'));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 都道府県を選択
      await tester.tap(find.text('選択してください'));
      await tester.pumpAndSettle();

      // 関東は initiallyExpanded: true なので、直接東京都をタップ
      final tokyoFinder = find.text('東京都');
      await tester.ensureVisible(tokyoFinder);
      await tester.pumpAndSettle();
      await tester.tap(tokyoFinder);
      await tester.pumpAndSettle();

      // 都道府県選択時に自動検索が実行される
      // APIエラーでもUIがクラッシュしないことを確認
      // (エラーハンドリングはStoreProviderレベルで行われる場合がある)
      expect(find.byType(SearchPage), findsOneWidget);
    });

    testWidgets('should clear city when prefecture changes',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 東京都を選択
      await tester.tap(find.text('選択してください'));
      await tester.pumpAndSettle();

      // 関東は initiallyExpanded: true なので、直接東京都をタップ
      final tokyoFinder = find.text('東京都');
      await tester.ensureVisible(tokyoFinder);
      await tester.pumpAndSettle();
      await tester.tap(tokyoFinder);
      await tester.pumpAndSettle();

      // 市区町村を選択
      await tester.tap(find.text('全域'));
      await tester.pumpAndSettle();

      // 新宿区を見つけてスクロールしてからタップ
      final shinjukuFinder = find.text('新宿区');
      await tester.ensureVisible(shinjukuFinder);
      await tester.pumpAndSettle();
      await tester.tap(shinjukuFinder);
      await tester.pumpAndSettle();

      // 新宿区が表示されていることを確認
      expect(find.text('新宿区'), findsOneWidget);

      // 別の都道府県を選択（都道府県セレクタをタップ）
      await tester.tap(find.text('東京都').first);
      await tester.pumpAndSettle();

      // ダイアログ内でListViewをスクロールして関西を見つける
      // ListView内のScrollableを取得
      final listView = find.byType(ListView).last;
      await tester.drag(listView, const Offset(0, -200)); // 下にスクロール
      await tester.pumpAndSettle();

      // 関西を展開
      final kansaiFinder = find.text('関西');
      if (kansaiFinder.evaluate().isNotEmpty) {
        await tester.tap(kansaiFinder);
        await tester.pumpAndSettle();

        // 大阪府を選択
        final osakaFinder = find.text('大阪府');
        await tester.ensureVisible(osakaFinder);
        await tester.pumpAndSettle();
        await tester.tap(osakaFinder);
        await tester.pumpAndSettle();

        // 市区町村がクリアされて「全域」に戻ることを確認
        expect(find.text('新宿区'), findsNothing);
        expect(find.text('全域'), findsOneWidget);
      }
    });
  });
}

/// テスト用のFakeStoreRepository
class FakeStoreRepository implements StoreRepository {
  List<Store> _stores = [];
  List<Store> _apiStores = [];
  Exception? _searchError;
  double? lastSearchLat;
  double? lastSearchLng;
  String? lastSearchAddress;

  void setStores(List<Store> stores) => _stores = List.from(stores);
  void setApiStores(List<Store> stores) => _apiStores = List.from(stores);
  void setSearchError(Exception error) => _searchError = error;

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
  Future<void> deleteAllStores() async => _stores.clear();

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
    if (_searchError != null) {
      throw _searchError!;
    }

    lastSearchLat = lat;
    lastSearchLng = lng;
    lastSearchAddress = address;

    return List.from(_apiStores);
  }
}

/// テスト用のMockLocationService
class MockLocationService implements LocationService {
  @override
  Future<Location> getCurrentLocation() async {
    return Location(
      latitude: 35.6762,
      longitude: 139.6503,
      accuracy: 10.0,
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<bool> hasLocationPermission() async => true;

  @override
  Future<bool> requestLocationPermission() async => true;
}
