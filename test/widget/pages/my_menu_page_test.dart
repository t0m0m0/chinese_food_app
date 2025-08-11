import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:chinese_food_app/presentation/pages/my_menu/my_menu_page.dart';
import 'package:chinese_food_app/presentation/providers/store_provider.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/domain/entities/location.dart';
import 'package:chinese_food_app/domain/repositories/store_repository.dart';
import 'package:chinese_food_app/domain/services/location_service.dart';

import 'my_menu_page_test.mocks.dart';

class MockLocationService implements LocationService {
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

@GenerateMocks([StoreRepository])
void main() {
  late MockStoreRepository mockRepository;
  late MockLocationService mockLocationService;
  late StoreProvider storeProvider;

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
        ],
        child: const MyMenuPage(),
      ),
    );
  }

  group('MyMenuPage Widget Tests', () {
    group('初期表示', () {
      testWidgets('should display MyMenuPage title',
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('マイメニュー'), findsOneWidget);
      });

      testWidgets('should display tabs for "行きたい" and "行った"',
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('行きたい'), findsOneWidget);
        expect(find.text('行った'), findsOneWidget);
      });
    });

    group('データ表示', () {
      testWidgets('should display empty state when no stores',
          (WidgetTester tester) async {
        when(mockRepository.getAllStores()).thenAnswer((_) async => []);
        when(mockRepository.searchStoresFromApi(
          lat: anyNamed('lat'),
          lng: anyNamed('lng'),
          address: anyNamed('address'),
          keyword: anyNamed('keyword'),
          range: anyNamed('range'),
          count: anyNamed('count'),
          start: anyNamed('start'),
        )).thenAnswer((_) async => []);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('まだ「行きたい」店舗がありません'), findsOneWidget);
      });

      testWidgets('should display stores list when stores exist',
          (WidgetTester tester) async {
        // 十分なデータ（10件以上）を設定してAPI呼び出しを防ぐ
        final manyStores = List.generate(
            15,
            (index) => Store(
                  id: 'store_$index',
                  name: index == 0 ? '中華料理店A' : '中華料理店$index',
                  address: index == 0 ? '東京都渋谷区' : '東京都渋谷区$index',
                  lat: 35.6581 + index * 0.001,
                  lng: 139.7414 + index * 0.001,
                  status: StoreStatus.wantToGo,
                  createdAt: DateTime.now(),
                ));

        when(mockRepository.getAllStores()).thenAnswer((_) async => manyStores);
        when(mockRepository.searchStoresFromApi(
          lat: anyNamed('lat'),
          lng: anyNamed('lng'),
          address: anyNamed('address'),
          keyword: anyNamed('keyword'),
          range: anyNamed('range'),
          count: anyNamed('count'),
          start: anyNamed('start'),
        )).thenAnswer((_) async => []);

        await tester.pumpWidget(createTestWidget());

        // データを明示的にロード
        await storeProvider.loadStores();
        await tester.pumpAndSettle();

        expect(find.text('中華料理店A'), findsOneWidget);
        expect(find.text('東京都渋谷区'), findsOneWidget);
      });

      testWidgets('should display error state when data loading fails',
          (WidgetTester tester) async {
        when(mockRepository.getAllStores())
            .thenThrow(Exception('Network Error'));
        when(mockRepository.searchStoresFromApi(
          lat: anyNamed('lat'),
          lng: anyNamed('lng'),
          address: anyNamed('address'),
          keyword: anyNamed('keyword'),
          range: anyNamed('range'),
          count: anyNamed('count'),
          start: anyNamed('start'),
        )).thenAnswer((_) async => []);

        await tester.pumpWidget(createTestWidget());

        // データロードでエラーが発生
        await storeProvider.loadStores();
        await tester.pumpAndSettle();

        expect(find.text('エラーが発生しました'), findsOneWidget);
        expect(find.text('再試行'), findsOneWidget);
      });
    });

    group('インタラクション', () {
      testWidgets('should switch tabs correctly', (WidgetTester tester) async {
        // 十分なデータ（10件以上）を設定してAPI呼び出しを防ぐ
        final baseStores = [
          Store(
            id: '1',
            name: '行きたい店A',
            address: '東京都渋谷区',
            lat: 35.6581,
            lng: 139.7414,
            status: StoreStatus.wantToGo,
            createdAt: DateTime.now(),
          ),
          Store(
            id: '2',
            name: '行った店B',
            address: '東京都新宿区',
            lat: 35.6938,
            lng: 139.7036,
            status: StoreStatus.visited,
            createdAt: DateTime.now(),
          ),
        ];

        // ダミーデータを追加して10件以上にする
        final allStores = [
          ...baseStores,
          ...List.generate(
              10,
              (index) => Store(
                    id: 'dummy_$index',
                    name: 'ダミー店$index',
                    address: '東京都港区$index',
                    lat: 35.6762 + index * 0.001,
                    lng: 139.6503 + index * 0.001,
                    status: index % 2 == 0
                        ? StoreStatus.wantToGo
                        : StoreStatus.visited,
                    createdAt: DateTime.now(),
                  )),
        ];

        when(mockRepository.getAllStores()).thenAnswer((_) async => allStores);
        when(mockRepository.searchStoresFromApi(
          lat: anyNamed('lat'),
          lng: anyNamed('lng'),
          address: anyNamed('address'),
          keyword: anyNamed('keyword'),
          range: anyNamed('range'),
          count: anyNamed('count'),
          start: anyNamed('start'),
        )).thenAnswer((_) async => []);

        await tester.pumpWidget(createTestWidget());

        // データを明示的にロード
        await storeProvider.loadStores();
        await tester.pumpAndSettle();

        // 「行きたい」タブの確認（デフォルト表示）
        expect(find.text('行きたい店A'), findsOneWidget);

        // 「行った」タブをタップ
        await tester.tap(find.text('行った'));
        await tester.pumpAndSettle();

        // 「行った」タブの内容確認
        expect(find.text('行った店B'), findsOneWidget);
        expect(find.text('行きたい店A'), findsNothing);
      });
    });
  });
}
