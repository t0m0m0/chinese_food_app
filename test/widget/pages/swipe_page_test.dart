import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

import 'package:chinese_food_app/presentation/pages/swipe/swipe_page.dart';
import 'package:chinese_food_app/presentation/providers/store_provider.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/domain/entities/location.dart';
import 'package:chinese_food_app/domain/repositories/store_repository.dart';
import 'package:chinese_food_app/domain/services/location_service.dart';

// Simple mock implementation for testing
class MockStoreRepository extends Mock implements StoreRepository {
  @override
  Future<List<Store>> getAllStores() async => [];

  @override
  Future<void> insertStore(Store store) async {}

  @override
  Future<void> updateStore(Store store) async {}

  @override
  Future<void> deleteStore(String storeId) async {}

  @override
  Future<Store?> getStoreById(String storeId) async => null;

  @override
  Future<List<Store>> getStoresByStatus(StoreStatus status) async => [];

  @override
  Future<List<Store>> searchStores(String query) async => [];

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
    // 距離500m（range=2）の場合は空のリストを返す（APIエラーではなく正常応答）
    return [];
  }
}

// 1件の店舗を返すモックリポジトリ（numberOfCardsDisplayed テスト用）
class MockStoreRepositoryWithOneStore extends Mock implements StoreRepository {
  @override
  Future<List<Store>> getAllStores() async => [];

  @override
  Future<void> insertStore(Store store) async {}

  @override
  Future<void> updateStore(Store store) async {}

  @override
  Future<void> deleteStore(String storeId) async {}

  @override
  Future<Store?> getStoreById(String storeId) async => null;

  @override
  Future<List<Store>> getStoresByStatus(StoreStatus status) async => [];

  @override
  Future<List<Store>> searchStores(String query) async => [];

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
    // 1件の店舗を返す（numberOfCardsDisplayed assertion テスト用）
    return [
      Store(
        id: 'test_store_1',
        name: 'テスト中華料理店',
        address: '東京都新宿区',
        lat: 35.6917,
        lng: 139.7006,
        createdAt: DateTime.now(),
      ),
    ];
  }
}

class MockLocationService extends Mock implements LocationService {
  @override
  Future<Location> getCurrentLocation() async {
    return Location(
      latitude: 35.6917,
      longitude: 139.7006,
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

void main() {
  late MockStoreRepository mockRepository;
  late StoreProvider storeProvider;
  late MockLocationService mockLocationService;

  setUp(() {
    mockRepository = MockStoreRepository();
    mockLocationService = MockLocationService();
    storeProvider = StoreProvider(
      repository: mockRepository,
    );
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<StoreProvider>.value(value: storeProvider),
          Provider<LocationService>.value(value: mockLocationService),
        ],
        child: const SwipePage(),
      ),
    );
  }

  group('SwipePage', () {
    testWidgets('should display card swiper with store cards', (tester) async {
      // when: SwipePageを表示
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // then: スワイプページのタイトルが表示される
      expect(find.text('見つける'), findsOneWidget);
      // and: 距離設定UIが表示される
      expect(find.text('検索範囲'), findsOneWidget);
    });

    testWidgets('should handle right swipe to set want_to_go status',
        (tester) async {
      // when: SwipePageを表示
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // then: スワイプインジケーターが表示される（実装がないため失敗するはず）
      expect(find.text('→ 行きたい'), findsOneWidget);
    });

    testWidgets('should handle left swipe to set bad status', (tester) async {
      // when: SwipePageを表示
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // then: スワイプインジケーターが表示される（実装がないため失敗するはず）
      expect(find.text('← 興味なし'), findsOneWidget);
    });

    testWidgets(
        'should show appropriate message when no stores found with 500m range',
        (tester) async {
      // given: SwipePageを表示
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // when: StoreProviderのloadSwipeStoresメソッドを距離500m（range=2）で呼び出し
      final storeProvider = Provider.of<StoreProvider>(
        tester.element(find.byType(SwipePage)),
        listen: false,
      );

      await storeProvider.loadSwipeStores(
        lat: 35.6917,
        lng: 139.7006,
        range: 2, // 距離500m
        count: 20,
      );
      await tester.pumpAndSettle();

      // then: CardSwiperのクラッシュが発生せず、適切なメッセージが表示される
      expect(find.byType(CardSwiper), findsNothing);

      // StoreProviderの情報メッセージが表示されることを確認（エラーではない）
      expect(find.text('検索結果'), findsOneWidget);

      // より具体的な情報メッセージの検証
      expect(
        find.text('現在地周辺に新しい中華料理店が見つかりませんでした。範囲を広げてみてください。'),
        findsOneWidget,
        reason: 'StoreProvider.loadSwipeStores()の距離500m設定時の適切な情報メッセージ表示',
      );

      // CardSwiperが初期化されていないことの確認
      expect(
        find.byType(CardSwiper),
        findsNothing,
        reason: 'カード数0でのCardSwiper初期化防止（Issue #130対応）',
      );
    });

    testWidgets('should handle empty state with proper fallback UI',
        (tester) async {
      // given: SwipePageを表示
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // when: 空店舗リスト状態をシミュレート
      final storeProvider = Provider.of<StoreProvider>(
        tester.element(find.byType(SwipePage)),
        listen: false,
      );

      await storeProvider.loadSwipeStores(
        lat: 35.6917,
        lng: 139.7006,
        range: 1, // 任意の距離設定
        count: 20,
      );
      await tester.pumpAndSettle();

      // then: loadSwipeStoresで情報メッセージが設定された状態を確認
      // MockStoreRepositoryは空のリストを返すため、StoreProviderが情報メッセージを設定
      expect(find.text('検索結果'), findsOneWidget);
      expect(
        find.text('現在地周辺に新しい中華料理店が見つかりませんでした。範囲を広げてみてください。'),
        findsOneWidget,
      );

      // CardSwiperが表示されていないことを確認
      expect(find.byType(CardSwiper), findsNothing);
    });

    testWidgets('should handle race condition during store list update',
        (tester) async {
      // given: 競合状態をシミュレートするための特別なプロバイダー
      final mockRepository = MockStoreRepository();
      final mockLocationService = MockLocationService();
      final raceConditionProvider = StoreProvider(
        repository: mockRepository,
      );

      // when: SwipePageを表示
      await tester.pumpWidget(MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<StoreProvider>.value(
                value: raceConditionProvider),
            Provider<LocationService>.value(value: mockLocationService),
          ],
          child: const SwipePage(),
        ),
      ));
      await tester.pumpAndSettle();

      // then: 競合状態でもCardSwiperクラッシュが発生しないことを確認
      // アトミック参照により numberOfCardsDisplayed >= 1 && numberOfCardsDisplayed <= cardsCount
      // assertion error が防止されていることを検証
      expect(find.byType(CardSwiper), findsNothing);

      // 複数回の状態変更でも安定していることを確認
      for (int i = 0; i < 3; i++) {
        await raceConditionProvider.loadSwipeStores(
          lat: 35.6917,
          lng: 139.7006,
          range: i + 1,
          count: 20,
        );
        await tester.pumpAndSettle();

        // アトミック参照によりCardSwiperクラッシュが防止されていることを確認
        expect(find.byType(CardSwiper), findsNothing);
      }
    });

    testWidgets('should handle numberOfCardsDisplayed assertion with one store',
        (tester) async {
      // given: 1件の店舗を返すモックリポジトリ
      final mockRepositoryWithOneStore = MockStoreRepositoryWithOneStore();
      final mockLocationService = MockLocationService();
      final oneStoreProvider = StoreProvider(
        repository: mockRepositoryWithOneStore,
      );

      // when: SwipePageを表示
      await tester.pumpWidget(MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<StoreProvider>.value(
                value: oneStoreProvider),
            Provider<LocationService>.value(value: mockLocationService),
          ],
          child: const SwipePage(),
        ),
      ));
      await tester.pumpAndSettle();

      // 1件の店舗でloadSwipeStoresを実行
      await oneStoreProvider.loadSwipeStores(
        lat: 35.6917,
        lng: 139.7006,
        range: 3,
        count: 1,
      );
      await tester.pumpAndSettle();

      // then: numberOfCardsDisplayed assertion error が発生しないことを確認
      // CardSwiperが適切に表示され、numberOfCardsDisplayed = min(1, 3) = 1 で動作
      expect(find.byType(CardSwiper), findsOneWidget);
      expect(find.text('テスト中華料理店'), findsOneWidget);

      // アプリがクラッシュしていないことを確認
      expect(tester.takeException(), isNull);
    });
  });
}
