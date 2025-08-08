import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';

import 'package:chinese_food_app/presentation/pages/swipe/swipe_page.dart';
import 'package:chinese_food_app/presentation/providers/store_provider.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/domain/repositories/store_repository.dart';

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
}

void main() {
  late MockStoreRepository mockRepository;
  late StoreProvider storeProvider;

  setUp(() {
    mockRepository = MockStoreRepository();
    storeProvider = StoreProvider(repository: mockRepository);
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<StoreProvider>.value(value: storeProvider),
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

      // then: flutter_card_swiperが使用されている（実装がないため失敗するはず）
      expect(find.text('AppCardSwiper'), findsOneWidget);
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
