import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';

import 'package:chinese_food_app/presentation/pages/search/search_page.dart';
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
}

class MockLocationService extends Mock implements LocationService {
  @override
  Future<Location> getCurrentLocation() async => Location(
        latitude: 35.6762,
        longitude: 139.6503,
        timestamp: DateTime.now(),
      );
}

void main() {
  late MockStoreRepository mockRepository;
  late StoreProvider storeProvider;
  late MockLocationService mockLocationService;

  setUp(() {
    mockRepository = MockStoreRepository();
    storeProvider = StoreProvider(
      repository: mockRepository,
      locationService: mockLocationService,
    );
    mockLocationService = MockLocationService();
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<StoreProvider>.value(value: storeProvider),
          Provider<LocationService>.value(value: mockLocationService),
        ],
        child: const SearchPage(),
      ),
    );
  }

  group('SearchPage', () {
    testWidgets('should display search form with location toggle',
        (tester) async {
      // when: SearchPageを表示
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // then: 検索フォームが表示される（実装がないため失敗するはず）
      expect(find.text('現在地で検索'), findsOneWidget);
      expect(find.text('住所で検索'), findsOneWidget);
    });

    testWidgets('should display initial state message', (tester) async {
      // when: SearchPageを表示
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // then: 初期状態のメッセージが表示される
      expect(find.text('検索ボタンを押して中華料理店を探しましょう'), findsOneWidget);
    });

    testWidgets('should display search button', (tester) async {
      // when: SearchPageを表示
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // then: 検索ボタンが表示される
      expect(find.text('中華料理店を検索'), findsOneWidget);
    });

    testWidgets('should show no loading state initially', (tester) async {
      // when: SearchPageを表示
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // then: 初期状態ではローディングが表示されない
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('should have both radio buttons for location selection',
        (tester) async {
      // when: SearchPageを表示
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // then: 両方のラジオボタンが存在する
      expect(find.byType(RadioListTile<bool>), findsNWidgets(2));

      // 現在地で検索がデフォルトで選択されている
      final currentLocationRadio = find.byWidgetPredicate((Widget widget) =>
          widget is RadioListTile<bool> &&
          widget.value == true &&
          widget.groupValue == true);
      expect(currentLocationRadio, findsOneWidget);
    });
  });
}
