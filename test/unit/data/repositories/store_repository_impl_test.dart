import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:chinese_food_app/data/repositories/store_repository_impl.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/data/models/hotpepper_store_model.dart';
import '../../../helpers/mocks.mocks.dart';

void main() {
  late StoreRepositoryImpl repository;
  late MockHotpepperProxyDatasource mockApiDatasource;
  late MockStoreLocalDatasource mockLocalDatasource;

  setUp(() {
    mockApiDatasource = MockHotpepperProxyDatasource();
    mockLocalDatasource = MockStoreLocalDatasource();
    repository = StoreRepositoryImpl(
      apiDatasource: mockApiDatasource,
      localDatasource: mockLocalDatasource,
    );
  });

  group('StoreRepositoryImpl - searchStoresFromApi', () {
    final testHotpepperStores = [
      HotpepperStoreModel(
        id: 'api-store-1',
        name: 'API中華料理店1',
        address: '東京都渋谷区1-1-1',
        lat: 35.6762,
        lng: 139.6503,
        photo: 'https://example.com/photo1.jpg',
        catch_: 'おすすめの中華料理店',
      ),
      HotpepperStoreModel(
        id: 'api-store-2',
        name: 'API中華料理店2',
        address: '東京都新宿区2-2-2',
        lat: 35.6895,
        lng: 139.6917,
        photo: 'https://example.com/photo2.jpg',
        catch_: '本格中華の味',
      ),
    ];

    final testResponse = HotpepperSearchResponse(
      shops: testHotpepperStores,
      resultsAvailable: 2,
      resultsReturned: 2,
      resultsStart: 1,
    );

    test('should return stores with null status from API', () async {
      // Arrange
      when(mockApiDatasource.searchStores(
        lat: 35.6762,
        lng: 139.6503,
        keyword: '中華',
        range: 3,
        count: 20,
        start: 1,
      )).thenAnswer((_) async => testResponse);

      // Act
      final result = await repository.searchStoresFromApi(
        lat: 35.6762,
        lng: 139.6503,
        keyword: '中華',
        range: 3,
        count: 20,
      );

      // Assert
      expect(result, hasLength(2));
      expect(result.every((store) => store.status == null), true);
      expect(result[0].id, 'api-store-1');
      expect(result[0].name, 'API中華料理店1');
      expect(result[1].id, 'api-store-2');
      verify(mockApiDatasource.searchStores(
        lat: 35.6762,
        lng: 139.6503,
        keyword: '中華',
        range: 3,
        count: 20,
        start: 1,
      )).called(1);
    });

    test('should convert HotpepperStore to Store entity correctly', () async {
      // Arrange
      when(mockApiDatasource.searchStores(
        lat: anyNamed('lat'),
        lng: anyNamed('lng'),
        keyword: anyNamed('keyword'),
        range: anyNamed('range'),
        count: anyNamed('count'),
        start: anyNamed('start'),
      )).thenAnswer((_) async => testResponse);

      // Act
      final result = await repository.searchStoresFromApi(
        lat: 35.6762,
        lng: 139.6503,
        keyword: '中華',
      );

      // Assert
      final firstStore = result.first;
      expect(firstStore.id, 'api-store-1');
      expect(firstStore.name, 'API中華料理店1');
      expect(firstStore.address, '東京都渋谷区1-1-1');
      expect(firstStore.lat, 35.6762);
      expect(firstStore.lng, 139.6503);
      expect(firstStore.imageUrl, 'https://example.com/photo1.jpg');
      expect(firstStore.status, isNull);
      expect(firstStore.memo, 'おすすめの中華料理店');
      expect(firstStore.createdAt, isNotNull);
    });

    test('should handle API search with address parameter', () async {
      // Arrange
      when(mockApiDatasource.searchStores(
        address: '新宿',
        keyword: '中華',
        range: 3,
        count: 10,
        start: 1,
      )).thenAnswer((_) async => testResponse);

      // Act
      final result = await repository.searchStoresFromApi(
        address: '新宿',
        keyword: '中華',
        count: 10,
      );

      // Assert
      expect(result, hasLength(2));
      verify(mockApiDatasource.searchStores(
        address: '新宿',
        keyword: '中華',
        range: 3,
        count: 10,
        start: 1,
      )).called(1);
    });

    test('should throw exception when API call fails', () async {
      // Arrange
      when(mockApiDatasource.searchStores(
        lat: anyNamed('lat'),
        lng: anyNamed('lng'),
        keyword: anyNamed('keyword'),
        range: anyNamed('range'),
        count: anyNamed('count'),
        start: anyNamed('start'),
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

    test('should handle empty API response', () async {
      // Arrange
      final emptyResponse = HotpepperSearchResponse(
        shops: [],
        resultsAvailable: 0,
        resultsReturned: 0,
        resultsStart: 1,
      );
      when(mockApiDatasource.searchStores(
        lat: anyNamed('lat'),
        lng: anyNamed('lng'),
        keyword: anyNamed('keyword'),
        range: anyNamed('range'),
        count: anyNamed('count'),
        start: anyNamed('start'),
      )).thenAnswer((_) async => emptyResponse);

      // Act
      final result = await repository.searchStoresFromApi(
        lat: 35.6762,
        lng: 139.6503,
        keyword: '中華',
      );

      // Assert
      expect(result, isEmpty);
    });
  });

  group('StoreRepositoryImpl - local operations', () {
    final testStore = Store(
      id: 'test-store',
      name: 'テスト中華料理店',
      address: '東京都港区テスト1-1-1',
      lat: 35.6584,
      lng: 139.7454,
      status: StoreStatus.wantToGo,
      createdAt: DateTime.now(),
    );

    test('should insert store to local datasource', () async {
      // Arrange
      when(mockLocalDatasource.insertStore(testStore))
          .thenAnswer((_) async => {});

      // Act
      await repository.insertStore(testStore);

      // Assert
      verify(mockLocalDatasource.insertStore(testStore)).called(1);
    });

    test('should throw exception when insert fails', () async {
      // Arrange
      when(mockLocalDatasource.insertStore(any))
          .thenThrow(Exception('Database error'));

      // Act & Assert
      expect(
        () => repository.insertStore(testStore),
        throwsA(isA<Exception>()),
      );
    });

    test('should get all stores from local datasource', () async {
      // Arrange
      when(mockLocalDatasource.getAllStores())
          .thenAnswer((_) async => [testStore]);

      // Act
      final result = await repository.getAllStores();

      // Assert
      expect(result, [testStore]);
      verify(mockLocalDatasource.getAllStores()).called(1);
    });

    test('should update store in local datasource', () async {
      // Arrange
      when(mockLocalDatasource.updateStore(testStore))
          .thenAnswer((_) async => {});

      // Act
      await repository.updateStore(testStore);

      // Assert
      verify(mockLocalDatasource.updateStore(testStore)).called(1);
    });

    test('should delete store from local datasource', () async {
      // Arrange
      when(mockLocalDatasource.deleteStore('test-store'))
          .thenAnswer((_) async => {});

      // Act
      await repository.deleteStore('test-store');

      // Assert
      verify(mockLocalDatasource.deleteStore('test-store')).called(1);
    });

    test('should get store by id from local datasource', () async {
      // Arrange
      when(mockLocalDatasource.getStoreById('test-store'))
          .thenAnswer((_) async => testStore);

      // Act
      final result = await repository.getStoreById('test-store');

      // Assert
      expect(result, testStore);
      verify(mockLocalDatasource.getStoreById('test-store')).called(1);
    });

    test('should get stores by status from local datasource', () async {
      // Arrange
      when(mockLocalDatasource.getStoresByStatus(StoreStatus.wantToGo))
          .thenAnswer((_) async => [testStore]);

      // Act
      final result = await repository.getStoresByStatus(StoreStatus.wantToGo);

      // Assert
      expect(result, [testStore]);
      verify(mockLocalDatasource.getStoresByStatus(StoreStatus.wantToGo))
          .called(1);
    });
  });
}
