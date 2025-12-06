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
  Future<Location> getCurrentLocation() async => Location(
        latitude: 35.6762,
        longitude: 139.6503,
        timestamp: DateTime.now(),
      );

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
        child: const SearchPage(),
      ),
    );
  }

  group('SearchPage (Area Search)', () {
    testWidgets('should display area selection UI', (tester) async {
      // when: SearchPageを表示
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // then: 都道府県選択UIが表示される
      expect(find.text('都道府県を選択'), findsOneWidget);
      expect(find.text('選択してください'), findsOneWidget);
    });

    testWidgets('should display initial state message for area search',
        (tester) async {
      // when: SearchPageを表示
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // then: 初期状態のメッセージが表示される
      expect(find.text('エリアを選択して検索してください'), findsOneWidget);
    });

    testWidgets('should show no loading state initially', (tester) async {
      // when: SearchPageを表示
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // then: 初期状態ではローディングが表示されない
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('should display app bar with "エリア" title', (tester) async {
      // when: SearchPageを表示
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // then: AppBarに「エリア」タイトルが表示される
      expect(find.text('エリア'), findsOneWidget);
    });

    testWidgets('should show prefecture selection dialog when tapped',
        (tester) async {
      // when: SearchPageを表示
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // when: 都道府県選択エリアをタップ
      await tester.tap(find.text('選択してください'));
      await tester.pumpAndSettle();

      // then: 都道府県選択ダイアログが表示される
      expect(find.text('都道府県を選択'), findsNWidgets(2)); // 1つはUIラベル、1つはダイアログタイトル
      // 関東はinitiallyExpanded: trueなので直接見える
      expect(find.text('関東'), findsOneWidget);
      // ダイアログが開いていることを確認（AlertDialogの存在）
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('should select prefecture from dialog', (tester) async {
      // when: SearchPageを表示
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // when: 都道府県選択エリアをタップ
      await tester.tap(find.text('選択してください'));
      await tester.pumpAndSettle();

      // 関東はinitiallyExpanded: trueなので直接東京都をタップ
      // when: 東京都を選択（スクロールしてから）
      final tokyoFinder = find.text('東京都');
      await tester.ensureVisible(tokyoFinder);
      await tester.pumpAndSettle();
      await tester.tap(tokyoFinder);
      await tester.pumpAndSettle();

      // then: 東京都が選択される
      expect(find.text('東京都'), findsOneWidget);
      expect(find.text('選択してください'), findsNothing);
    });

    testWidgets('should show city selector after prefecture selection',
        (tester) async {
      // when: SearchPageを表示
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // when: 都道府県選択エリアをタップ
      await tester.tap(find.text('選択してください'));
      await tester.pumpAndSettle();

      // 関東はinitiallyExpanded: trueなので直接東京都をタップ
      final tokyoFinder = find.text('東京都');
      await tester.ensureVisible(tokyoFinder);
      await tester.pumpAndSettle();
      await tester.tap(tokyoFinder);
      await tester.pumpAndSettle();

      // then: 市区町村選択UIが表示される
      expect(find.text('市区町村を選択（任意）'), findsOneWidget);
      expect(find.text('全域'), findsOneWidget);
    });

    testWidgets('should display selected area chip', (tester) async {
      // when: SearchPageを表示
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // when: 都道府県を選択
      await tester.tap(find.text('選択してください'));
      await tester.pumpAndSettle();

      // 関東はinitiallyExpanded: trueなので直接東京都をタップ
      // 東京都を見つけてスクロールしてからタップ
      final tokyoFinder = find.text('東京都');
      await tester.ensureVisible(tokyoFinder);
      await tester.pumpAndSettle();
      await tester.tap(tokyoFinder);
      await tester.pumpAndSettle();

      // then: エリアチップが表示される
      expect(find.text('東京都の中華料理店'), findsOneWidget);
    });
  });
}
