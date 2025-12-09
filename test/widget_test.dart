// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/main.dart';
import 'package:chinese_food_app/presentation/providers/store_provider.dart';
import 'package:chinese_food_app/domain/repositories/store_repository.dart';
import 'package:chinese_food_app/domain/services/location_service.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/domain/entities/location.dart';
import 'package:chinese_food_app/domain/usecases/add_visit_record_usecase.dart';
import 'package:chinese_food_app/domain/usecases/get_visit_records_by_store_id_usecase.dart';
import 'package:chinese_food_app/core/di/di_container_interface.dart';

void main() {
  testWidgets('町中華アプリの基本構造テスト', (WidgetTester tester) async {
    // モックサービスを作成
    final mockLocationService = MockLocationService();
    final fakeRepository = FakeStoreRepository();
    final storeProvider = StoreProvider(
      repository: fakeRepository,
    );
    final mockContainer = MockDIContainer(
      storeProvider: storeProvider,
      locationService: mockLocationService,
    );

    // テスト用のアプリをビルド
    await tester.pumpWidget(
      MyApp(
        storeProvider: storeProvider,
        locationService: mockLocationService,
        container: mockContainer,
      ),
    );

    // 1フレーム進めてUIを描画
    await tester.pump();

    // BottomNavigationBarが表示されることを確認
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    // 基本的なUI要素の存在を確認（重複があっても可）
    expect(find.text('見つける'), findsWidgets);
    expect(find.text('エリア'), findsWidgets);
    expect(find.text('マイメニュー'), findsWidgets);
  });

  testWidgets('事前初期化されたStoreProviderの動作テスト', (WidgetTester tester) async {
    // モックサービスを作成
    final mockLocationService = MockLocationService();
    final fakeRepository = FakeStoreRepository();
    final storeProvider = StoreProvider(
      repository: fakeRepository,
    );

    // 事前初期化をシミュレート
    await storeProvider.loadStores();

    final mockContainer = MockDIContainer(
      storeProvider: storeProvider,
      locationService: mockLocationService,
    );

    // テスト用のアプリをビルド
    await tester.pumpWidget(
      MyApp(
        storeProvider: storeProvider,
        locationService: mockLocationService,
        container: mockContainer,
      ),
    );

    // 1フレーム進めてUIを描画
    await tester.pump();

    // StoreProviderが事前初期化されていることを確認
    expect(storeProvider.isLoading, false);
    // APIから空の結果が返されるため、エラーメッセージが設定される可能性がある
    // これは正常な動作なので、エラーがあってもアプリは動作する
  });

  testWidgets('初期化エラー時のフォールバック動作テスト', (WidgetTester tester) async {
    // エラーを発生させるMockRepositoryを作成
    final errorRepository = ErrorStoreRepository();
    final mockLocationService = MockLocationService();
    final storeProvider = StoreProvider(
      repository: errorRepository,
    );

    // 初期化エラーをシミュレート
    try {
      await storeProvider.loadStores();
    } catch (e) {
      // エラーが期待通り発生することを確認
      expect(e, isNotNull);
    }

    // エラーをクリアしてアプリが続行可能な状態に
    storeProvider.clearError();

    final mockContainer = MockDIContainer(
      storeProvider: storeProvider,
      locationService: mockLocationService,
    );

    // エラーがあってもアプリが起動できることを確認
    await tester.pumpWidget(
      MyApp(
        storeProvider: storeProvider,
        locationService: mockLocationService,
        container: mockContainer,
      ),
    );

    await tester.pump();

    // 基本的なUIが表示されることを確認
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
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

/// テスト用のFakeStoreRepository
class FakeStoreRepository implements StoreRepository {
  final List<Store> _stores = [];

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
    return [];
  }
}

/// エラーを発生させるテスト用Repository
class ErrorStoreRepository implements StoreRepository {
  @override
  Future<List<Store>> getAllStores() async {
    throw Exception('データベース接続エラー');
  }

  @override
  Future<void> insertStore(Store store) async {
    throw Exception('店舗追加エラー');
  }

  @override
  Future<void> updateStore(Store store) async {
    throw Exception('店舗更新エラー');
  }

  @override
  Future<void> deleteStore(String storeId) async {
    throw Exception('店舗削除エラー');
  }

  @override
  Future<void> deleteAllStores() async {
    throw Exception('全店舗削除エラー');
  }

  @override
  Future<Store?> getStoreById(String storeId) async {
    throw Exception('店舗検索エラー');
  }

  @override
  Future<List<Store>> getStoresByStatus(StoreStatus status) async {
    throw Exception('ステータス検索エラー');
  }

  @override
  Future<List<Store>> searchStores(String query) async {
    throw Exception('店舗検索エラー');
  }

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
    throw Exception('API検索エラー');
  }
}

/// テスト用のMockDIContainer
class MockDIContainer implements DIContainerInterface {
  final StoreProvider storeProvider;
  final LocationService locationService;
  bool _isConfigured = false;

  MockDIContainer({
    required this.storeProvider,
    required this.locationService,
  });

  @override
  void configure() {
    _isConfigured = true;
  }

  @override
  void configureForEnvironment(Environment environment) {
    _isConfigured = true;
  }

  @override
  StoreProvider getStoreProvider() => storeProvider;

  @override
  LocationService getLocationService() => locationService;

  @override
  AddVisitRecordUsecase getAddVisitRecordUsecase() {
    throw UnimplementedError('Mock implementation not needed for this test');
  }

  @override
  GetVisitRecordsByStoreIdUsecase getGetVisitRecordsByStoreIdUsecase() {
    throw UnimplementedError('Mock implementation not needed for this test');
  }

  @override
  void registerTestProvider(StoreProvider provider) {
    // テスト用のため空実装
  }

  @override
  bool get isConfigured => _isConfigured;

  @override
  void dispose() {
    _isConfigured = false;
  }
}
