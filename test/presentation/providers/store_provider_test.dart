import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/domain/repositories/store_repository.dart';
import 'package:chinese_food_app/presentation/providers/store_provider.dart';

import 'store_provider_test.mocks.dart';

@GenerateMocks([StoreRepository])
void main() {
  late StoreProvider storeProvider;
  late MockStoreRepository mockRepository;

  setUp(() {
    mockRepository = MockStoreRepository();
    storeProvider = StoreProvider(repository: mockRepository);
  });

  group('StoreProvider Tests', () {
    final testStores = [
      Store(
        id: 'store-1',
        name: '中華料理 テスト1',
        address: '東京都渋谷区テスト1-1-1',
        lat: 35.6762,
        lng: 139.6503,
        status: StoreStatus.wantToGo,
        createdAt: DateTime(2025, 6, 23, 16, 0, 0),
      ),
      Store(
        id: 'store-2',
        name: '中華料理 テスト2',
        address: '東京都新宿区テスト2-2-2',
        lat: 35.6895,
        lng: 139.6917,
        status: StoreStatus.visited,
        createdAt: DateTime(2025, 6, 23, 16, 0, 0),
      ),
    ];

    test('should have empty stores list initially', () {
      expect(storeProvider.stores, isEmpty);
      expect(storeProvider.wantToGoStores, isEmpty);
      expect(storeProvider.visitedStores, isEmpty);
      expect(storeProvider.badStores, isEmpty);
      expect(storeProvider.isLoading, false);
      expect(storeProvider.error, isNull);
    });

    test('should load stores successfully', () async {
      when(mockRepository.getAllStores()).thenAnswer((_) async => testStores);

      await storeProvider.loadStores();

      expect(storeProvider.stores, testStores);
      expect(storeProvider.wantToGoStores, hasLength(1));
      expect(storeProvider.visitedStores, hasLength(1));
      expect(storeProvider.badStores, isEmpty);
      expect(storeProvider.isLoading, false);
      expect(storeProvider.error, isNull);
    });

    test('should handle loading error', () async {
      const errorMessage = 'Database error';
      when(mockRepository.getAllStores()).thenThrow(Exception(errorMessage));

      await storeProvider.loadStores();

      expect(storeProvider.stores, isEmpty);
      expect(storeProvider.isLoading, false);
      expect(storeProvider.error, contains(errorMessage));
    });

    test('should update store status successfully', () async {
      when(mockRepository.getAllStores()).thenAnswer((_) async => testStores);
      when(mockRepository.updateStore(any)).thenAnswer((_) async {});

      await storeProvider.loadStores();
      final store = testStores.first;

      await storeProvider.updateStoreStatus(store.id, StoreStatus.visited);

      expect(storeProvider.wantToGoStores, isEmpty);
      expect(storeProvider.visitedStores, hasLength(2));
      expect(storeProvider.error, isNull);

      verify(mockRepository.updateStore(any)).called(1);
    });

    test('should handle update store status error', () async {
      when(mockRepository.getAllStores()).thenAnswer((_) async => testStores);
      when(mockRepository.updateStore(any))
          .thenThrow(Exception('Update failed'));

      await storeProvider.loadStores();
      final store = testStores.first;

      await storeProvider.updateStoreStatus(store.id, StoreStatus.visited);

      expect(storeProvider.error, contains('Update failed'));
    });

    test('should add new store successfully', () async {
      final newStore = Store(
        id: 'new-store',
        name: '新しい中華料理店',
        address: '東京都港区テスト3-3-3',
        lat: 35.6584,
        lng: 139.7454,
        status: StoreStatus.wantToGo,
        createdAt: DateTime.now(),
      );

      when(mockRepository.getAllStores()).thenAnswer((_) async => []);
      when(mockRepository.insertStore(any)).thenAnswer((_) async {});

      await storeProvider.loadStores();
      await storeProvider.addStore(newStore);

      expect(storeProvider.stores, contains(newStore));
      expect(storeProvider.wantToGoStores, contains(newStore));
      expect(storeProvider.error, isNull);

      verify(mockRepository.insertStore(newStore)).called(1);
    });

    test('should handle add store error', () async {
      final newStore = Store(
        id: 'new-store',
        name: '新しい中華料理店',
        address: '東京都港区テスト3-3-3',
        lat: 35.6584,
        lng: 139.7454,
        status: StoreStatus.wantToGo,
        createdAt: DateTime.now(),
      );

      when(mockRepository.getAllStores()).thenAnswer((_) async => []);
      when(mockRepository.insertStore(any))
          .thenThrow(Exception('Insert failed'));

      await storeProvider.loadStores();
      await storeProvider.addStore(newStore);

      expect(storeProvider.error, contains('Insert failed'));
    });

    test('should clear error', () async {
      when(mockRepository.getAllStores()).thenThrow(Exception('Test error'));

      await storeProvider.loadStores();
      expect(storeProvider.error, isNotNull);

      storeProvider.clearError();
      expect(storeProvider.error, isNull);
    });

    test('should filter stores by status correctly', () async {
      final mixedStores = [
        Store(
          id: '1',
          name: 'Store 1',
          address: 'Address 1',
          lat: 35.0,
          lng: 139.0,
          status: StoreStatus.wantToGo,
          createdAt: DateTime.now(),
        ),
        Store(
          id: '2',
          name: 'Store 2',
          address: 'Address 2',
          lat: 35.0,
          lng: 139.0,
          status: StoreStatus.visited,
          createdAt: DateTime.now(),
        ),
        Store(
          id: '3',
          name: 'Store 3',
          address: 'Address 3',
          lat: 35.0,
          lng: 139.0,
          status: StoreStatus.bad,
          createdAt: DateTime.now(),
        ),
      ];

      when(mockRepository.getAllStores()).thenAnswer((_) async => mixedStores);

      await storeProvider.loadStores();

      expect(storeProvider.stores, hasLength(3));
      expect(storeProvider.wantToGoStores, hasLength(1));
      expect(storeProvider.visitedStores, hasLength(1));
      expect(storeProvider.badStores, hasLength(1));
    });
  });
}
