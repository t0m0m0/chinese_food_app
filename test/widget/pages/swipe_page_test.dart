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
      locationService: mockLocationService,
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
      expect(find.text('スワイプ'), findsOneWidget);
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

      // StoreProviderのエラーメッセージが表示されることを確認
      expect(find.text('エラーが発生しました'), findsOneWidget);

      // より具体的なエラーメッセージの検証
      expect(
        find.text('現在地周辺に新しい中華料理店が見つかりませんでした。範囲を広げてみてください。'),
        findsOneWidget,
        reason: 'StoreProvider.loadSwipeStores()の距離500m設定時の適切なエラーメッセージ表示',
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

      // then: loadSwipeStoresでエラーメッセージが設定された状態を確認
      // MockStoreRepositoryは空のリストを返すため、StoreProviderがエラーメッセージを設定
      expect(find.text('エラーが発生しました'), findsOneWidget);
      expect(
        find.text('現在地周辺に新しい中華料理店が見つかりませんでした。範囲を広げてみてください。'),
        findsOneWidget,
      );

      // CardSwiperが表示されていないことを確認
      expect(find.byType(CardSwiper), findsNothing);
    });
  });
}
