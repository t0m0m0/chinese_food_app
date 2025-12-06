import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:chinese_food_app/presentation/providers/area_search_provider.dart';
import 'package:chinese_food_app/presentation/providers/store_provider.dart';
import 'package:chinese_food_app/domain/entities/area.dart';
import 'package:chinese_food_app/core/constants/area_data.dart';

@GenerateMocks([StoreProvider])
import 'area_search_provider_test.mocks.dart';

void main() {
  late AreaSearchProvider provider;
  late MockStoreProvider mockStoreProvider;

  setUp(() {
    mockStoreProvider = MockStoreProvider();
    when(mockStoreProvider.searchResults).thenReturn([]);
    provider = AreaSearchProvider(storeProvider: mockStoreProvider);
  });

  tearDown(() {
    provider.dispose();
  });

  group('AreaSearchProvider', () {
    group('initial state', () {
      test('should have null selected prefecture initially', () {
        expect(provider.selectedPrefecture, isNull);
      });

      test('should have null selected city initially', () {
        expect(provider.selectedCity, isNull);
      });

      test('should not be loading initially', () {
        expect(provider.isLoading, isFalse);
      });

      test('should have no search results initially', () {
        expect(provider.searchResults, isEmpty);
      });

      test('should not have searched initially', () {
        expect(provider.hasSearched, isFalse);
      });

      test('should have all prefectures available', () {
        expect(provider.prefectures, equals(AreaData.prefectures));
      });
    });

    group('selectPrefecture', () {
      test('should update selected prefecture', () {
        const tokyo = Prefecture(code: '13', name: '東京都');

        provider.selectPrefecture(tokyo);

        expect(provider.selectedPrefecture, tokyo);
      });

      test('should clear selected city when prefecture changes', () {
        const tokyo = Prefecture(code: '13', name: '東京都');
        const shinjuku = City(
          prefectureCode: '13',
          code: '13104',
          name: '新宿区',
        );

        provider.selectPrefecture(tokyo);
        provider.selectCity(shinjuku);
        expect(provider.selectedCity, shinjuku);

        const osaka = Prefecture(code: '27', name: '大阪府');
        provider.selectPrefecture(osaka);

        expect(provider.selectedPrefecture, osaka);
        expect(provider.selectedCity, isNull);
      });

      test('should update available cities', () {
        const tokyo = Prefecture(code: '13', name: '東京都');

        provider.selectPrefecture(tokyo);

        expect(provider.availableCities, isNotEmpty);
        expect(
          provider.availableCities.every((c) => c.prefectureCode == '13'),
          isTrue,
        );
      });

      test('should notify listeners', () {
        const tokyo = Prefecture(code: '13', name: '東京都');
        var notified = false;
        provider.addListener(() => notified = true);

        provider.selectPrefecture(tokyo);

        expect(notified, isTrue);
      });
    });

    group('selectCity', () {
      test('should update selected city', () {
        const tokyo = Prefecture(code: '13', name: '東京都');
        const shinjuku = City(
          prefectureCode: '13',
          code: '13104',
          name: '新宿区',
        );

        provider.selectPrefecture(tokyo);
        provider.selectCity(shinjuku);

        expect(provider.selectedCity, shinjuku);
      });

      test('should notify listeners', () {
        const tokyo = Prefecture(code: '13', name: '東京都');
        const shinjuku = City(
          prefectureCode: '13',
          code: '13104',
          name: '新宿区',
        );
        provider.selectPrefecture(tokyo);

        var notified = false;
        provider.addListener(() => notified = true);

        provider.selectCity(shinjuku);

        expect(notified, isTrue);
      });
    });

    group('clearCity', () {
      test('should clear selected city', () {
        const tokyo = Prefecture(code: '13', name: '東京都');
        const shinjuku = City(
          prefectureCode: '13',
          code: '13104',
          name: '新宿区',
        );

        provider.selectPrefecture(tokyo);
        provider.selectCity(shinjuku);
        provider.clearCity();

        expect(provider.selectedCity, isNull);
      });
    });

    group('currentSelection', () {
      test('should return null when no prefecture selected', () {
        expect(provider.currentSelection, isNull);
      });

      test('should return AreaSelection with prefecture only', () {
        const tokyo = Prefecture(code: '13', name: '東京都');
        provider.selectPrefecture(tokyo);

        final selection = provider.currentSelection;
        expect(selection, isNotNull);
        expect(selection!.prefecture, tokyo);
        expect(selection.city, isNull);
      });

      test('should return AreaSelection with prefecture and city', () {
        const tokyo = Prefecture(code: '13', name: '東京都');
        const shinjuku = City(
          prefectureCode: '13',
          code: '13104',
          name: '新宿区',
        );

        provider.selectPrefecture(tokyo);
        provider.selectCity(shinjuku);

        final selection = provider.currentSelection;
        expect(selection, isNotNull);
        expect(selection!.prefecture, tokyo);
        expect(selection.city, shinjuku);
      });
    });

    group('canSearch', () {
      test('should return false when no prefecture selected', () {
        expect(provider.canSearch, isFalse);
      });

      test('should return true when prefecture is selected', () {
        const tokyo = Prefecture(code: '13', name: '東京都');
        provider.selectPrefecture(tokyo);

        expect(provider.canSearch, isTrue);
      });
    });

    group('performSearch', () {
      test('should not search when no prefecture selected', () async {
        await provider.performSearch();

        verifyNever(mockStoreProvider.loadNewStoresFromApi(
          address: anyNamed('address'),
          keyword: anyNamed('keyword'),
          range: anyNamed('range'),
          count: anyNamed('count'),
        ));
      });

      test('should search with prefecture address', () async {
        const tokyo = Prefecture(code: '13', name: '東京都');
        provider.selectPrefecture(tokyo);

        when(mockStoreProvider.loadNewStoresFromApi(
          address: anyNamed('address'),
          keyword: anyNamed('keyword'),
          range: anyNamed('range'),
          count: anyNamed('count'),
        )).thenAnswer((_) async {});

        await provider.performSearch();

        verify(mockStoreProvider.loadNewStoresFromApi(
          address: '東京都',
          keyword: '中華',
          range: anyNamed('range'),
          count: anyNamed('count'),
        )).called(1);
      });

      test('should search with full address when city selected', () async {
        const tokyo = Prefecture(code: '13', name: '東京都');
        const shinjuku = City(
          prefectureCode: '13',
          code: '13104',
          name: '新宿区',
        );

        provider.selectPrefecture(tokyo);
        provider.selectCity(shinjuku);

        when(mockStoreProvider.loadNewStoresFromApi(
          address: anyNamed('address'),
          keyword: anyNamed('keyword'),
          range: anyNamed('range'),
          count: anyNamed('count'),
        )).thenAnswer((_) async {});

        await provider.performSearch();

        verify(mockStoreProvider.loadNewStoresFromApi(
          address: '東京都新宿区',
          keyword: '中華',
          range: anyNamed('range'),
          count: anyNamed('count'),
        )).called(1);
      });

      test('should set isLoading during search', () async {
        const tokyo = Prefecture(code: '13', name: '東京都');
        provider.selectPrefecture(tokyo);

        var loadingStates = <bool>[];
        provider.addListener(() {
          loadingStates.add(provider.isLoading);
        });

        when(mockStoreProvider.loadNewStoresFromApi(
          address: anyNamed('address'),
          keyword: anyNamed('keyword'),
          range: anyNamed('range'),
          count: anyNamed('count'),
        )).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 10));
        });

        await provider.performSearch();

        expect(loadingStates, contains(true));
        expect(provider.isLoading, isFalse);
      });

      test('should set hasSearched after search', () async {
        const tokyo = Prefecture(code: '13', name: '東京都');
        provider.selectPrefecture(tokyo);

        when(mockStoreProvider.loadNewStoresFromApi(
          address: anyNamed('address'),
          keyword: anyNamed('keyword'),
          range: anyNamed('range'),
          count: anyNamed('count'),
        )).thenAnswer((_) async {});

        await provider.performSearch();

        expect(provider.hasSearched, isTrue);
      });
    });

    group('search filters', () {
      test('should have default search range', () {
        expect(provider.searchRange, 3);
      });

      test('should have default result count', () {
        expect(provider.resultCount, 20);
      });

      test('should update search range', () {
        provider.setSearchRange(5);
        expect(provider.searchRange, 5);
      });

      test('should update result count', () {
        provider.setResultCount(50);
        expect(provider.resultCount, 50);
      });
    });
  });
}
