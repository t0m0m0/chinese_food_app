import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/domain/repositories/store_repository.dart';
import 'package:chinese_food_app/data/repositories/store_repository_impl.dart';
import 'package:chinese_food_app/data/datasources/store_local_datasource.dart';
import 'package:chinese_food_app/data/datasources/hotpepper_api_datasource.dart'
    show HotpepperApiDatasource;
import 'package:chinese_food_app/data/models/store_model.dart';
import 'package:chinese_food_app/data/models/hotpepper_store_model.dart';
import 'package:chinese_food_app/core/database/database_helper.dart';

// Mockクラスを生成するためのアノテーション
@GenerateMocks([StoreLocalDatasource, DatabaseHelper, HotpepperApiDatasource])
import 'store_repository_test.mocks.dart';

void main() {
  group('StoreRepository Tests', () {
    late StoreRepository repository;
    late MockStoreLocalDatasource mockLocalDataSource;
    late MockDatabaseHelper mockDatabaseHelper;
    late MockHotpepperApiDatasource mockApiDataSource;

    setUp(() {
      mockLocalDataSource = MockStoreLocalDatasource();
      mockDatabaseHelper = MockDatabaseHelper();
      mockApiDataSource = MockHotpepperApiDatasource();
      repository = StoreRepositoryImpl(
        mockLocalDataSource,
        mockDatabaseHelper,
        mockApiDataSource,
      );
    });

    group('getAllStores', () {
      test('should return all stores from local datasource', () async {
        // Red: This test should fail initially - interfaces don't exist yet
        final testStoreModels = [
          StoreModel(
            id: 'store-1',
            name: '中華料理 テスト1',
            address: '東京都渋谷区テスト1-1-1',
            lat: 35.6762,
            lng: 139.6503,
            status: StoreStatus.wantToGo,
            memo: 'テスト用店舗1',
            createdAt: DateTime(2025, 6, 23, 16, 0, 0),
          ),
          StoreModel(
            id: 'store-2',
            name: '中華料理 テスト2',
            address: '東京都新宿区テスト2-2-2',
            lat: 35.6895,
            lng: 139.6917,
            status: StoreStatus.visited,
            memo: 'テスト用店舗2',
            createdAt: DateTime(2025, 6, 23, 17, 0, 0),
          ),
        ];

        // Arrange
        when(mockLocalDataSource.getAllStores())
            .thenAnswer((_) async => testStoreModels);

        // Act
        final result = await repository.getAllStores();

        // Assert
        expect(result, testStoreModels);
        verify(mockLocalDataSource.getAllStores()).called(1);
      });

      test('should propagate exception from datasource', () async {
        // Arrange
        when(mockLocalDataSource.getAllStores())
            .thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => repository.getAllStores(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getStoresByStatus', () {
      test('should return stores filtered by status', () async {
        final wantToGoStoreModels = [
          StoreModel(
            id: 'store-1',
            name: '中華料理 テスト1',
            address: '東京都渋谷区テスト1-1-1',
            lat: 35.6762,
            lng: 139.6503,
            status: StoreStatus.wantToGo,
            memo: 'テスト用店舗1',
            createdAt: DateTime(2025, 6, 23, 16, 0, 0),
          ),
        ];

        // Arrange
        when(mockLocalDataSource.getStoresByStatus(StoreStatus.wantToGo))
            .thenAnswer((_) async => wantToGoStoreModels);

        // Act
        final result = await repository.getStoresByStatus(StoreStatus.wantToGo);

        // Assert
        expect(result, wantToGoStoreModels);
        verify(mockLocalDataSource.getStoresByStatus(StoreStatus.wantToGo))
            .called(1);
      });
    });

    group('getStoreById', () {
      test('should return store when found', () async {
        final testStoreModel = StoreModel(
          id: 'store-1',
          name: '中華料理 テスト1',
          address: '東京都渋谷区テスト1-1-1',
          lat: 35.6762,
          lng: 139.6503,
          status: StoreStatus.wantToGo,
          memo: 'テスト用店舗1',
          createdAt: DateTime(2025, 6, 23, 16, 0, 0),
        );

        // Arrange
        when(mockLocalDataSource.getStoreById('store-1'))
            .thenAnswer((_) async => testStoreModel);

        // Act
        final result = await repository.getStoreById('store-1');

        // Assert
        expect(result, testStoreModel);
        verify(mockLocalDataSource.getStoreById('store-1')).called(1);
      });

      test('should return null when store not found', () async {
        // Arrange
        when(mockLocalDataSource.getStoreById('non-existent'))
            .thenAnswer((_) async => null);

        // Act
        final result = await repository.getStoreById('non-existent');

        // Assert
        expect(result, isNull);
        verify(mockLocalDataSource.getStoreById('non-existent')).called(1);
      });
    });

    group('insertStore', () {
      test('should insert store successfully', () async {
        final testStore = Store(
          id: 'store-1',
          name: '中華料理 テスト1',
          address: '東京都渋谷区テスト1-1-1',
          lat: 35.6762,
          lng: 139.6503,
          status: StoreStatus.wantToGo,
          memo: 'テスト用店舗1',
          createdAt: DateTime(2025, 6, 23, 16, 0, 0),
        );

        // Arrange
        when(mockLocalDataSource.insertStore(any)).thenAnswer((_) async {});

        // Act
        await repository.insertStore(testStore);

        // Assert
        verify(mockLocalDataSource.insertStore(any)).called(1);
      });

      test('should propagate exception on insert failure', () async {
        final testStore = Store(
          id: 'store-1',
          name: '中華料理 テスト1',
          address: '東京都渋谷区テスト1-1-1',
          lat: 35.6762,
          lng: 139.6503,
          status: StoreStatus.wantToGo,
          memo: 'テスト用店舗1',
          createdAt: DateTime(2025, 6, 23, 16, 0, 0),
        );

        // Arrange
        when(mockLocalDataSource.insertStore(any))
            .thenThrow(Exception('Duplicate key error'));

        // Act & Assert
        expect(
          () => repository.insertStore(testStore),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('updateStore', () {
      test('should update store successfully', () async {
        final testStore = Store(
          id: 'store-1',
          name: '中華料理 テスト1 Updated',
          address: '東京都渋谷区テスト1-1-1',
          lat: 35.6762,
          lng: 139.6503,
          status: StoreStatus.visited,
          memo: '更新されたテスト用店舗1',
          createdAt: DateTime(2025, 6, 23, 16, 0, 0),
        );

        // Arrange
        when(mockLocalDataSource.updateStore(any)).thenAnswer((_) async {});

        // Act
        await repository.updateStore(testStore);

        // Assert
        verify(mockLocalDataSource.updateStore(any)).called(1);
      });

      test('should propagate exception on update failure', () async {
        final testStore = Store(
          id: 'non-existent',
          name: '中華料理 テスト',
          address: '東京都渋谷区テスト1-1-1',
          lat: 35.6762,
          lng: 139.6503,
          status: StoreStatus.visited,
          memo: 'テスト用店舗',
          createdAt: DateTime(2025, 6, 23, 16, 0, 0),
        );

        // Arrange
        when(mockLocalDataSource.updateStore(any))
            .thenThrow(Exception('Update failed'));

        // Act & Assert
        expect(
          () => repository.updateStore(testStore),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('deleteStore', () {
      test('should delete store successfully', () async {
        // Arrange
        when(mockLocalDataSource.deleteStore('store-1'))
            .thenAnswer((_) async {});

        // Act
        await repository.deleteStore('store-1');

        // Assert
        verify(mockLocalDataSource.deleteStore('store-1')).called(1);
      });

      test('should propagate exception on delete failure', () async {
        // Arrange
        when(mockLocalDataSource.deleteStore('non-existent'))
            .thenThrow(Exception('Delete failed'));

        // Act & Assert
        expect(
          () => repository.deleteStore('non-existent'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('searchStores', () {
      test('should return stores matching search query', () async {
        final searchResults = [
          StoreModel(
            id: 'store-1',
            name: '中華料理 ラーメン店',
            address: '東京都渋谷区テスト1-1-1',
            lat: 35.6762,
            lng: 139.6503,
            status: StoreStatus.wantToGo,
            memo: 'ラーメンが美味しい',
            createdAt: DateTime(2025, 6, 23, 16, 0, 0),
          ),
        ];

        // Arrange
        when(mockLocalDataSource.searchStores('ラーメン'))
            .thenAnswer((_) async => searchResults);

        // Act
        final result = await repository.searchStores('ラーメン');

        // Assert
        expect(result, searchResults);
        verify(mockLocalDataSource.searchStores('ラーメン')).called(1);
      });

      test('should return empty list when no matches found', () async {
        // Arrange
        when(mockLocalDataSource.searchStores('存在しない'))
            .thenAnswer((_) async => []);

        // Act
        final result = await repository.searchStores('存在しない');

        // Assert
        expect(result, isEmpty);
        verify(mockLocalDataSource.searchStores('存在しない')).called(1);
      });
    });

    group('searchStoresFromApi', () {
      test('should return stores from API with valid coordinates', () async {
        // Arrange
        final mockApiResponse = HotpepperSearchResponse(
          shops: [
            HotpepperStoreModel(
              id: 'api-store-1',
              name: 'API中華料理店',
              address: '東京都渋谷区API1-1-1',
              lat: 35.6762,
              lng: 139.6503,
              catch_: 'API経由の店舗',
            ),
            HotpepperStoreModel(
              id: 'api-store-2',
              name: 'API中華料理店2',
              address: '東京都新宿区API2-2-2',
              lat: 0.0, // 無効な座標 - フィルタリングされるべき
              lng: 0.0,
              catch_: 'フィルタされる店舗',
            ),
          ],
          resultsAvailable: 2,
          resultsReturned: 2,
          resultsStart: 1,
        );

        when(mockApiDataSource.searchStores(
          lat: 35.6762,
          lng: 139.6503,
          keyword: '中華',
        )).thenAnswer((_) async => mockApiResponse);

        // Act
        final result = await repository.searchStoresFromApi(
          lat: 35.6762,
          lng: 139.6503,
          keyword: '中華',
        );

        // Assert
        expect(result.length, 1); // 有効な座標の店舗のみ
        expect(result.first.id, 'api-store-1');
        expect(result.first.name, 'API中華料理店');
        expect(result.first.lat, 35.6762);
        expect(result.first.lng, 139.6503);
        verify(mockApiDataSource.searchStores(
          lat: 35.6762,
          lng: 139.6503,
          keyword: '中華',
        )).called(1);
      });

      test('should propagate exception from API datasource', () async {
        // Arrange
        when(mockApiDataSource.searchStores(
          lat: anyNamed('lat'),
          lng: anyNamed('lng'),
          keyword: anyNamed('keyword'),
        )).thenThrow(Exception('API error'));

        // Act & Assert
        expect(
          () => repository.searchStoresFromApi(
            lat: 35.6762,
            lng: 139.6503,
            keyword: '中華',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
