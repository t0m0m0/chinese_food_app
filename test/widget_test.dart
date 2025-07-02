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
import 'package:chinese_food_app/core/di/di_container_interface.dart';

void main() {
  testWidgets('町中華アプリの基本構造テスト', (WidgetTester tester) async {
    // モックサービスを作成
    final mockLocationService = MockLocationService();
    final fakeRepository = FakeStoreRepository();
    final storeProvider = StoreProvider(repository: fakeRepository);
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
    expect(find.text('スワイプ'), findsWidgets);
    expect(find.text('検索'), findsWidgets);
    expect(find.text('マイメニュー'), findsWidgets);
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
