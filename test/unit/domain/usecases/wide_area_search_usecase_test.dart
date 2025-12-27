import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:chinese_food_app/domain/usecases/wide_area_search_usecase.dart';
import 'package:chinese_food_app/domain/repositories/store_repository.dart';
import 'package:chinese_food_app/domain/entities/store.dart';

@GenerateMocks([StoreRepository])
import 'wide_area_search_usecase_test.mocks.dart';

void main() {
  late WideAreaSearchUsecase usecase;
  late MockStoreRepository mockRepository;

  setUp(() {
    mockRepository = MockStoreRepository();
    usecase = WideAreaSearchUsecase(repository: mockRepository);
  });

  group('WideAreaSearchUsecase', () {
    const center = LatLng(35.6812, 139.7671);
    const keyword = '中華';

    group('execute', () {
      test('should use single search for radius <= 3km', () async {
        // Arrange
        final stores = [
          _createStore('1', 'Store1', 35.6812, 139.7671),
          _createStore('2', 'Store2', 35.6820, 139.7680),
        ];

        when(mockRepository.searchStoresFromApi(
          lat: anyNamed('lat'),
          lng: anyNamed('lng'),
          keyword: anyNamed('keyword'),
          range: anyNamed('range'),
          count: anyNamed('count'),
          start: anyNamed('start'),
        )).thenAnswer((_) async => stores);

        // Act
        final result = await usecase.execute(
          center: center,
          radiusMeters: 3000,
          keyword: keyword,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull?.length, 2);
        // 単一検索なのでsearchStoresFromApiは1回だけ呼ばれる
        verify(mockRepository.searchStoresFromApi(
          lat: anyNamed('lat'),
          lng: anyNamed('lng'),
          keyword: anyNamed('keyword'),
          range: anyNamed('range'),
          count: anyNamed('count'),
          start: anyNamed('start'),
        )).called(1);
      });

      test('should use multiple searches for radius > 3km', () async {
        // Arrange
        final stores = [
          _createStore('1', 'Store1', 35.6812, 139.7671),
        ];

        when(mockRepository.searchStoresFromApi(
          lat: anyNamed('lat'),
          lng: anyNamed('lng'),
          keyword: anyNamed('keyword'),
          range: anyNamed('range'),
          count: anyNamed('count'),
          start: anyNamed('start'),
        )).thenAnswer((_) async => stores);

        // Act
        final result = await usecase.execute(
          center: center,
          radiusMeters: 10000, // 10km - requires multiple searches
          keyword: keyword,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        // 複数ポイント検索なのでsearchStoresFromApiは複数回呼ばれる
        verify(mockRepository.searchStoresFromApi(
          lat: anyNamed('lat'),
          lng: anyNamed('lng'),
          keyword: anyNamed('keyword'),
          range: anyNamed('range'),
          count: anyNamed('count'),
          start: anyNamed('start'),
        )).called(greaterThan(1));
      });

      test('should remove duplicate stores from wide area search', () async {
        // Arrange
        // 同じIDの店舗が複数検索で返される場合
        final storeFromPoint1 = _createStore('1', 'Store1', 35.6812, 139.7671);
        final storeFromPoint2 =
            _createStore('1', 'Store1', 35.6812, 139.7671); // 重複
        final storeFromPoint3 = _createStore('2', 'Store2', 35.6900, 139.7800);

        int callCount = 0;
        when(mockRepository.searchStoresFromApi(
          lat: anyNamed('lat'),
          lng: anyNamed('lng'),
          keyword: anyNamed('keyword'),
          range: anyNamed('range'),
          count: anyNamed('count'),
          start: anyNamed('start'),
        )).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) return [storeFromPoint1];
          if (callCount == 2) return [storeFromPoint2, storeFromPoint3];
          return [];
        });

        // Act
        final result = await usecase.execute(
          center: center,
          radiusMeters: 10000,
          keyword: keyword,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        final stores = result.dataOrNull!;
        // 重複が除去されて2店舗のみ
        expect(stores.length, 2);
        expect(stores.map((s) => s.id).toSet().length, 2);
      });

      test('should handle partial failures gracefully', () async {
        // Arrange
        final stores = [
          _createStore('1', 'Store1', 35.6812, 139.7671),
        ];

        int callCount = 0;
        when(mockRepository.searchStoresFromApi(
          lat: anyNamed('lat'),
          lng: anyNamed('lng'),
          keyword: anyNamed('keyword'),
          range: anyNamed('range'),
          count: anyNamed('count'),
          start: anyNamed('start'),
        )).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) return stores;
          // 2回目以降はエラー
          throw Exception('API Error');
        });

        // Act
        final result = await usecase.execute(
          center: center,
          radiusMeters: 10000,
          keyword: keyword,
        );

        // Assert
        // 部分的なエラーでも、取得できた店舗は返す
        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull!.isNotEmpty, isTrue);
      });
    });

    group('estimateSearchCount', () {
      test('should return 1 for radius <= 3km', () {
        final count = usecase.estimateSearchCount(
          center: center,
          radiusMeters: 3000,
        );
        expect(count, 1);
      });

      test('should return multiple for radius > 3km', () {
        final count = usecase.estimateSearchCount(
          center: center,
          radiusMeters: 10000,
        );
        expect(count, greaterThan(1));
      });
    });

    group('isWideAreaSearch', () {
      test('should return false for radius <= 3km', () {
        expect(usecase.isWideAreaSearch(3000), isFalse);
        expect(usecase.isWideAreaSearch(1000), isFalse);
      });

      test('should return true for radius > 3km', () {
        expect(usecase.isWideAreaSearch(3001), isTrue);
        expect(usecase.isWideAreaSearch(50000), isTrue);
      });
    });
  });
}

Store _createStore(String id, String name, double lat, double lng) {
  return Store(
    id: id,
    name: name,
    address: 'Test Address',
    lat: lat,
    lng: lng,
    createdAt: DateTime.now(),
  );
}
