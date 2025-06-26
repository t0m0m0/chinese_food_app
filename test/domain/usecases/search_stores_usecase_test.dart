import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/domain/repositories/store_repository.dart';
import 'package:chinese_food_app/domain/usecases/search_stores_usecase.dart';

import 'search_stores_usecase_test.mocks.dart';

@GenerateMocks([StoreRepository])
void main() {
  late SearchStoresUsecase usecase;
  late MockStoreRepository mockRepository;

  setUp(() {
    mockRepository = MockStoreRepository();
    usecase = SearchStoresUsecase(mockRepository);
  });

  group('SearchStoresUsecase Tests', () {
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
        status: StoreStatus.wantToGo,
        createdAt: DateTime(2025, 6, 23, 16, 0, 0),
      ),
    ];

    test('should return success result when stores are found by location', () async {
      // Red: This test should fail - we need to implement the functionality
      final params = SearchStoresParams(
        lat: 35.6762,
        lng: 139.6503,
        range: 3,
        count: 20,
      );

      when(mockRepository.searchStoresFromApi(
        lat: params.lat,
        lng: params.lng,
        address: params.address,
        keyword: params.keyword,
        range: params.range,
        count: params.count,
        start: params.start,
      )).thenAnswer((_) async => testStores);

      final result = await usecase.execute(params);

      expect(result.isSuccess, true);
      expect(result.stores, testStores);
      expect(result.error, isNull);
      expect(result.hasStores, true);
    });

    test('should return success result when stores are found by address', () async {
      final params = SearchStoresParams(
        address: '東京都渋谷区',
        keyword: '中華',
        range: 3,
        count: 20,
      );

      when(mockRepository.searchStoresFromApi(
        lat: params.lat,
        lng: params.lng,
        address: params.address,
        keyword: params.keyword,
        range: params.range,
        count: params.count,
        start: params.start,
      )).thenAnswer((_) async => testStores);

      final result = await usecase.execute(params);

      expect(result.isSuccess, true);
      expect(result.stores, testStores);
      expect(result.error, isNull);
    });

    test('should return success result with empty list when no stores found', () async {
      final params = SearchStoresParams(
        lat: 35.6762,
        lng: 139.6503,
        range: 1,
        count: 20,
      );

      when(mockRepository.searchStoresFromApi(
        lat: params.lat,
        lng: params.lng,
        address: params.address,
        keyword: params.keyword,
        range: params.range,
        count: params.count,
        start: params.start,
      )).thenAnswer((_) async => []);

      final result = await usecase.execute(params);

      expect(result.isSuccess, true);
      expect(result.stores, isEmpty);
      expect(result.error, isNull);
      expect(result.hasStores, false);
    });

    test('should return failure result when repository throws exception', () async {
      final params = SearchStoresParams(
        lat: 35.6762,
        lng: 139.6503,
        range: 3,
        count: 20,
      );

      when(mockRepository.searchStoresFromApi(
        lat: params.lat,
        lng: params.lng,
        address: params.address,
        keyword: params.keyword,
        range: params.range,
        count: params.count,
        start: params.start,
      )).thenThrow(Exception('API Error'));

      final result = await usecase.execute(params);

      expect(result.isSuccess, false);
      expect(result.stores, isNull);
      expect(result.error, '店舗検索中にエラーが発生しました: Exception: API Error');
    });

    test('should call repository with correct parameters', () async {
      final params = SearchStoresParams(
        lat: 35.6762,
        lng: 139.6503,
        address: '東京都渋谷区',
        keyword: '中華',
        range: 5,
        count: 10,
        start: 21,
      );

      when(mockRepository.searchStoresFromApi(
        lat: params.lat,
        lng: params.lng,
        address: params.address,
        keyword: params.keyword,
        range: params.range,
        count: params.count,
        start: params.start,
      )).thenAnswer((_) async => testStores);

      await usecase.execute(params);

      verify(mockRepository.searchStoresFromApi(
        lat: 35.6762,
        lng: 139.6503,
        address: '東京都渋谷区',
        keyword: '中華',
        range: 5,
        count: 10,
        start: 21,
      )).called(1);
    });

    test('should return failure when search criteria is invalid', () async {
      final params = SearchStoresParams(); // No lat/lng or address

      final result = await usecase.execute(params);

      expect(result.isSuccess, false);
      expect(result.error, '検索条件が不正です。位置情報または住所を指定してください。');
      expect(result.stores, isNull);
      
      // Repository should not be called
      verifyNever(mockRepository.searchStoresFromApi(
        lat: anyNamed('lat'),
        lng: anyNamed('lng'),
        address: anyNamed('address'),
        keyword: anyNamed('keyword'),
        range: anyNamed('range'),
        count: anyNamed('count'),
        start: anyNamed('start'),
      ));
    });
  });

  group('SearchStoresParams Tests', () {
    test('should identify location search correctly', () {
      final paramsWithLocation = SearchStoresParams(
        lat: 35.6762,
        lng: 139.6503,
      );
      
      final paramsWithoutLocation = SearchStoresParams(
        address: '東京都渋谷区',
      );

      expect(paramsWithLocation.hasLocationSearch, true);
      expect(paramsWithoutLocation.hasLocationSearch, false);
    });

    test('should identify address search correctly', () {
      final paramsWithAddress = SearchStoresParams(
        address: '東京都渋谷区',
      );
      
      final paramsWithEmptyAddress = SearchStoresParams(
        address: '',
      );

      final paramsWithoutAddress = SearchStoresParams(
        lat: 35.6762,
        lng: 139.6503,
      );

      expect(paramsWithAddress.hasAddressSearch, true);
      expect(paramsWithEmptyAddress.hasAddressSearch, false);
      expect(paramsWithoutAddress.hasAddressSearch, false);
    });

    test('should validate search criteria correctly', () {
      final validLocationParams = SearchStoresParams(
        lat: 35.6762,
        lng: 139.6503,
      );
      
      final validAddressParams = SearchStoresParams(
        address: '東京都渋谷区',
      );

      final invalidParams = SearchStoresParams();

      expect(validLocationParams.hasValidSearchCriteria, true);
      expect(validAddressParams.hasValidSearchCriteria, true);
      expect(invalidParams.hasValidSearchCriteria, false);
    });

    test('should have correct default values', () {
      final params = SearchStoresParams();

      expect(params.range, 3);
      expect(params.count, 20);
      expect(params.start, 1);
      expect(params.lat, isNull);
      expect(params.lng, isNull);
      expect(params.address, isNull);
      expect(params.keyword, isNull);
    });
  });

  group('SearchStoresResult Tests', () {
    test('should create success result correctly', () {
      final stores = [
        Store(
          id: 'test-id',
          name: 'Test Store',
          address: 'Test Address',
          lat: 35.6762,
          lng: 139.6503,
          status: StoreStatus.wantToGo,
          createdAt: DateTime.now(),
        ),
      ];

      final result = SearchStoresResult.success(stores);

      expect(result.isSuccess, true);
      expect(result.stores, stores);
      expect(result.error, isNull);
      expect(result.hasStores, true);
    });

    test('should create failure result correctly', () {
      const errorMessage = 'Something went wrong';
      final result = SearchStoresResult.failure(errorMessage);

      expect(result.isSuccess, false);
      expect(result.stores, isNull);
      expect(result.error, errorMessage);
      expect(result.hasStores, false);
    });

    test('should identify empty stores correctly', () {
      final resultWithStores = SearchStoresResult.success([
        Store(
          id: 'test-id',
          name: 'Test Store',
          address: 'Test Address',
          lat: 35.6762,
          lng: 139.6503,
          status: StoreStatus.wantToGo,
          createdAt: DateTime.now(),
        ),
      ]);

      final resultWithEmptyStores = SearchStoresResult.success([]);

      expect(resultWithStores.hasStores, true);
      expect(resultWithEmptyStores.hasStores, false);
    });
  });
}