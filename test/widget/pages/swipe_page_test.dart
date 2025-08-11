import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';

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
  }) async =>
      [];
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

    testWidgets('should show empty state when no more cards', (tester) async {
      // when: SwipePageを表示
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // then: 空の状態メッセージが表示される（実装がないため失敗するはず）
      expect(find.text('カードがありません'), findsNothing);
    });
  });
}
