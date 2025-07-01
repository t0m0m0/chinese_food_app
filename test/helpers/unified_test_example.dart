import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:chinese_food_app/domain/entities/location.dart';
import 'package:chinese_food_app/domain/entities/store.dart';

// 統一されたMockitoモック
import 'mocks.mocks.dart';

// 統一されたFakeクラス
import 'fakes.dart';

// 統一されたテストヘルパー
import 'test_helpers.dart';

/// 統一されたテストダブルの使用例
/// 
/// このファイルは新しいテストダブル統一化アプローチのデモンストレーションです。
void main() {
  group('Unified Test Doubles Example', () {
    group('Mockito-based Mocks', () {
      late MockLocationService mockLocationService;
      late MockStoreRepository mockStoreRepository;

      setUp(() {
        mockLocationService = MockLocationService();
        mockStoreRepository = MockStoreRepository();
      });

      test('should use MockLocationService from unified mocks', () async {
        // Given
        final expectedLocation = TestDataBuilders.createTestLocation();
        when(mockLocationService.getCurrentLocation())
            .thenAnswer((_) async => expectedLocation);

        // When
        final result = await mockLocationService.getCurrentLocation();

        // Then
        expect(result, equals(expectedLocation));
        verify(mockLocationService.getCurrentLocation()).called(1);
      });

      test('should use MockStoreRepository from unified mocks', () async {
        // Given
        final testStores = TestDataBuilders.createTestStores(3);
        when(mockStoreRepository.getAllStores())
            .thenAnswer((_) async => testStores);

        // When
        final result = await mockStoreRepository.getAllStores();

        // Then
        expect(result, hasLength(3));
        expect(result, equals(testStores));
        verify(mockStoreRepository.getAllStores()).called(1);
      });
    });

    group('Fake Classes', () {
      late FakeLocationService fakeLocationService;
      late FakeStoreRepository fakeStoreRepository;

      setUp(() {
        fakeLocationService = FakeLocationService();
        fakeStoreRepository = FakeStoreRepository();
      });

      tearDown(() {
        fakeLocationService.reset();
        fakeStoreRepository.clearStores();
      });

      test('should use configurable FakeLocationService', () async {
        // Given
        final testLocation = TestDataBuilders.createTestLocation(
          latitude: 35.123,
          longitude: 139.456,
        );
        fakeLocationService.setCurrentLocation(testLocation);

        // When
        final result = await fakeLocationService.getCurrentLocation();

        // Then
        expect(result, CustomMatchers.isLocationNear(testLocation));
        expect(result.latitude, 35.123);
        expect(result.longitude, 139.456);
      });

      test('should simulate location service errors', () async {
        // Given
        fakeLocationService.setShouldThrowError(
          true,
          Exception('GPS not available'),
        );

        // When & Then
        expect(
          () => fakeLocationService.getCurrentLocation(),
          throwsA(isA<Exception>()),
        );
      });

      test('should use configurable FakeStoreRepository', () async {
        // Given
        final testStores = TestDataBuilders.createTestStores(2);
        for (final store in testStores) {
          fakeStoreRepository.addStore(store);
        }

        // When
        final result = await fakeStoreRepository.getAllStores();

        // Then
        expect(result, hasLength(2));
        expect(result[0], CustomMatchers.hasStoreProperties(
          name: 'テスト中華料理店 1',
          status: StoreStatus.wantToGo,
        ));
      });

      test('should filter stores by status', () async {
        // Given
        final wantToGoStores = TestDataBuilders.createTestStores(2, 
          status: StoreStatus.wantToGo);
        final visitedStores = TestDataBuilders.createTestStores(1, 
          status: StoreStatus.visited);
        
        for (final store in [...wantToGoStores, ...visitedStores]) {
          fakeStoreRepository.addStore(store);
        }

        // When
        final wantToGoResult = await fakeStoreRepository
            .getStoresByStatus(StoreStatus.wantToGo);
        final visitedResult = await fakeStoreRepository
            .getStoresByStatus(StoreStatus.visited);

        // Then
        expect(wantToGoResult, hasLength(2));
        expect(visitedResult, hasLength(1));
      });
    });

    group('Test Data Builders', () {
      test('should create consistent test locations', () {
        // When
        final location1 = TestDataBuilders.createTestLocation();
        final location2 = TestDataBuilders.createTestLocation(
          latitude: 35.999,
          longitude: 139.999,
        );

        // Then
        expect(location1.latitude, 35.6762);
        expect(location1.longitude, 139.6503);
        expect(location1.accuracy, 10.0);
        
        expect(location2.latitude, 35.999);
        expect(location2.longitude, 139.999);
      });

      test('should create consistent test stores', () {
        // When
        final stores = TestDataBuilders.createTestStores(3);

        // Then
        expect(stores, hasLength(3));
        expect(stores[0].name, 'テスト中華料理店 1');
        expect(stores[1].name, 'テスト中華料理店 2');
        expect(stores[2].name, 'テスト中華料理店 3');
        
        // Verify locations are different
        expect(stores[0].lat, lessThan(stores[1].lat));
        expect(stores[1].lat, lessThan(stores[2].lat));
      });
    });

    group('Custom Matchers', () {
      test('should match locations within tolerance', () {
        // Given
        final location1 = Location(
          latitude: 35.6762,
          longitude: 139.6503,
          timestamp: DateTime.now(),
          accuracy: 10.0,
        );
        final location2 = Location(
          latitude: 35.6763, // 0.0001 difference
          longitude: 139.6504, // 0.0001 difference
          timestamp: DateTime.now(),
          accuracy: 10.0,
        );

        // Then
        expect(location2, CustomMatchers.isLocationNear(location1, 
          tolerance: 0.001));
        expect(location2, isNot(CustomMatchers.isLocationNear(location1, 
          tolerance: 0.00001)));
      });

      test('should match store properties', () {
        // Given
        final store = TestDataBuilders.createTestStore(
          name: 'カスタム店名',
          address: 'カスタム住所',
          status: StoreStatus.visited,
        );

        // Then
        expect(store, CustomMatchers.hasStoreProperties(
          name: 'カスタム店名',
          status: StoreStatus.visited,
        ));
        expect(store, CustomMatchers.hasStoreProperties(
          name: 'カスタム店名', // 部分マッチもサポート
        ));
      });
    });
  });
}