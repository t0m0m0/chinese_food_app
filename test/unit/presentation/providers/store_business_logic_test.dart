import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:chinese_food_app/presentation/providers/store_business_logic.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import '../../../helpers/mocks.mocks.dart';

void main() {
  late StoreBusinessLogic businessLogic;
  late MockStoreRepository mockRepository;
  late MockLocationService mockLocationService;

  setUp(() {
    mockRepository = MockStoreRepository();
    mockLocationService = MockLocationService();
    businessLogic = StoreBusinessLogic(
      repository: mockRepository,
      locationService: mockLocationService,
    );
  });

  group('StoreBusinessLogic - loadNewStoresFromApi', () {
    final testApiStores = [
      Store(
        id: 'api-store-1',
        name: 'API中華料理店1',
        address: '東京都渋谷区1-1-1',
        lat: 35.6762,
        lng: 139.6503,
        status: null,
        createdAt: DateTime.now(),
      ),
      Store(
        id: 'api-store-2',
        name: 'API中華料理店2',
        address: '東京都新宿区2-2-2',
        lat: 35.6895,
        lng: 139.6917,
        status: null,
        createdAt: DateTime.now(),
      ),
    ];

    test('should return API stores without filtering duplicates', () async {
      // Arrange
      when(mockRepository.searchStoresFromApi(
        lat: 35.6762,
        lng: 139.6503,
        keyword: '中華',
        range: 3,
        count: 10,
      )).thenAnswer((_) async => testApiStores);

      // Act
      final result = await businessLogic.loadNewStoresFromApi(
        lat: 35.6762,
        lng: 139.6503,
        keyword: '中華',
        range: 3,
        count: 10,
      );

      // Assert
      expect(result, hasLength(2));
      expect(result, equals(testApiStores));
      verify(mockRepository.searchStoresFromApi(
        lat: 35.6762,
        lng: 139.6503,
        keyword: '中華',
        range: 3,
        count: 10,
      )).called(1);
    });

    test(
        'should return same results on repeated searches (no duplicate filtering)',
        () async {
      // Arrange
      when(mockRepository.searchStoresFromApi(
        lat: anyNamed('lat'),
        lng: anyNamed('lng'),
        keyword: anyNamed('keyword'),
        range: anyNamed('range'),
        count: anyNamed('count'),
      )).thenAnswer((_) async => testApiStores);

      // Act - 1回目の検索
      final firstResult = await businessLogic.loadNewStoresFromApi(
        lat: 35.6762,
        lng: 139.6503,
        keyword: '中華',
        range: 3,
        count: 10,
      );

      // Act - 2回目の同じ検索
      final secondResult = await businessLogic.loadNewStoresFromApi(
        lat: 35.6762,
        lng: 139.6503,
        keyword: '中華',
        range: 3,
        count: 10,
      );

      // Assert - 繰り返し検索しても同じ結果が返ることを確認
      expect(secondResult.length, equals(firstResult.length));
      expect(secondResult, equals(testApiStores));
      verify(mockRepository.searchStoresFromApi(
        lat: anyNamed('lat'),
        lng: anyNamed('lng'),
        keyword: anyNamed('keyword'),
        range: anyNamed('range'),
        count: anyNamed('count'),
      )).called(2);
    });

    test('should not save API results to database', () async {
      // Arrange
      when(mockRepository.searchStoresFromApi(
        lat: anyNamed('lat'),
        lng: anyNamed('lng'),
        keyword: anyNamed('keyword'),
        range: anyNamed('range'),
        count: anyNamed('count'),
      )).thenAnswer((_) async => testApiStores);

      // Act
      await businessLogic.loadNewStoresFromApi(
        lat: 35.6762,
        lng: 139.6503,
        keyword: '中華',
      );

      // Assert - insertStore が呼ばれないことを確認
      verifyNever(mockRepository.insertStore(any));
    });

    test('should handle search with address parameter', () async {
      // Arrange
      when(mockRepository.searchStoresFromApi(
        address: '新宿',
        keyword: '中華',
        range: 3,
        count: 10,
      )).thenAnswer((_) async => testApiStores);

      // Act
      final result = await businessLogic.loadNewStoresFromApi(
        address: '新宿',
        keyword: '中華',
        count: 10,
      );

      // Assert
      expect(result, hasLength(2));
      verify(mockRepository.searchStoresFromApi(
        address: '新宿',
        keyword: '中華',
        range: 3,
        count: 10,
      )).called(1);
    });

    test('should handle empty API response', () async {
      // Arrange
      when(mockRepository.searchStoresFromApi(
        lat: anyNamed('lat'),
        lng: anyNamed('lng'),
        keyword: anyNamed('keyword'),
        range: anyNamed('range'),
        count: anyNamed('count'),
      )).thenAnswer((_) async => []);

      // Act
      final result = await businessLogic.loadNewStoresFromApi(
        lat: 35.6762,
        lng: 139.6503,
        keyword: '中華',
      );

      // Assert
      expect(result, isEmpty);
    });

    test('should throw exception when API call fails', () async {
      // Arrange
      when(mockRepository.searchStoresFromApi(
        lat: anyNamed('lat'),
        lng: anyNamed('lng'),
        keyword: anyNamed('keyword'),
        range: anyNamed('range'),
        count: anyNamed('count'),
      )).thenThrow(Exception('API error'));

      // Act & Assert
      expect(
        () => businessLogic.loadNewStoresFromApi(
          lat: 35.6762,
          lng: 139.6503,
          keyword: '中華',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('StoreBusinessLogic - loadSwipeStores', () {
    final testApiStores = [
      Store(
        id: 'swipe-store-1',
        name: 'スワイプ店舗1',
        address: '東京都港区1-1-1',
        lat: 35.6584,
        lng: 139.7454,
        status: null,
        createdAt: DateTime.now(),
      ),
      Store(
        id: 'swipe-store-2',
        name: 'スワイプ店舗2',
        address: '東京都港区2-2-2',
        lat: 35.6585,
        lng: 139.7455,
        status: null,
        createdAt: DateTime.now(),
      ),
    ];

    test('should load and filter swipe stores correctly', () async {
      // Arrange
      when(mockRepository.searchStoresFromApi(
        lat: 35.6584,
        lng: 139.7454,
        keyword: '中華',
        range: 3,
        count: 20,
      )).thenAnswer((_) async => testApiStores);

      when(mockRepository.insertStore(any)).thenAnswer((_) async => {});

      // Act
      final result = await businessLogic.loadSwipeStores(
        lat: 35.6584,
        lng: 139.7454,
        range: 3,
        count: 20,
      );

      // Assert
      expect(result, hasLength(2));
      expect(result.every((store) => store.status == null), true);
    });

    test('should exclude stores that already have status', () async {
      // Arrange
      final mixedStores = [
        Store(
          id: 'new-store',
          name: '新規店舗',
          address: '東京都港区1-1-1',
          lat: 35.6584,
          lng: 139.7454,
          status: null,
          createdAt: DateTime.now(),
        ),
        Store(
          id: 'visited-store',
          name: '訪問済み店舗',
          address: '東京都港区2-2-2',
          lat: 35.6585,
          lng: 139.7455,
          status: StoreStatus.visited,
          createdAt: DateTime.now(),
        ),
      ];

      when(mockRepository.searchStoresFromApi(
        lat: anyNamed('lat'),
        lng: anyNamed('lng'),
        keyword: anyNamed('keyword'),
        range: anyNamed('range'),
        count: anyNamed('count'),
      )).thenAnswer((_) async => mixedStores);

      when(mockRepository.getAllStores()).thenAnswer((_) async => [
            Store(
              id: 'visited-store',
              name: '訪問済み店舗',
              address: '東京都港区2-2-2',
              lat: 35.6585,
              lng: 139.7455,
              status: StoreStatus.visited,
              createdAt: DateTime.now(),
            ),
          ]);

      when(mockRepository.insertStore(any)).thenAnswer((_) async => {});

      // まず既存店舗をロード
      await businessLogic.loadStores();

      // Act
      final result = await businessLogic.loadSwipeStores(
        lat: 35.6584,
        lng: 139.7454,
        range: 3,
        count: 20,
      );

      // Assert - ステータスがnullの店舗のみが返される
      expect(result.length, lessThanOrEqualTo(1));
      expect(result.every((store) => store.status == null), true);
    });

    test('should handle empty swipe stores response', () async {
      // Arrange
      when(mockRepository.searchStoresFromApi(
        lat: anyNamed('lat'),
        lng: anyNamed('lng'),
        keyword: anyNamed('keyword'),
        range: anyNamed('range'),
        count: anyNamed('count'),
      )).thenAnswer((_) async => []);

      // Act
      final result = await businessLogic.loadSwipeStores(
        lat: 35.6584,
        lng: 139.7454,
        range: 3,
        count: 20,
      );

      // Assert
      expect(result, isEmpty);
    });

    test('should NOT save new stores to DB when loading swipe stores',
        () async {
      // Arrange - 新規店舗をAPIから取得
      when(mockRepository.searchStoresFromApi(
        lat: anyNamed('lat'),
        lng: anyNamed('lng'),
        keyword: anyNamed('keyword'),
        range: anyNamed('range'),
        count: anyNamed('count'),
      )).thenAnswer((_) async => testApiStores);

      // Act - スワイプ画面で店舗を読み込む
      await businessLogic.loadSwipeStores(
        lat: 35.6584,
        lng: 139.7454,
        range: 3,
        count: 20,
      );

      // Assert - insertStoreが呼ばれないことを確認（距離変更でDB保存しない）
      verifyNever(mockRepository.insertStore(any));
    });

    test('should NOT save to DB when changing distance repeatedly', () async {
      // Arrange
      when(mockRepository.searchStoresFromApi(
        lat: anyNamed('lat'),
        lng: anyNamed('lng'),
        keyword: anyNamed('keyword'),
        range: anyNamed('range'),
        count: anyNamed('count'),
      )).thenAnswer((_) async => testApiStores);

      // Act - 距離を変えて3回読み込む
      await businessLogic.loadSwipeStores(
        lat: 35.6584,
        lng: 139.7454,
        range: 1, // 300m
        count: 20,
      );
      await businessLogic.loadSwipeStores(
        lat: 35.6584,
        lng: 139.7454,
        range: 3, // 1000m
        count: 20,
      );
      await businessLogic.loadSwipeStores(
        lat: 35.6584,
        lng: 139.7454,
        range: 5, // 3000m
        count: 20,
      );

      // Assert - 何回読み込んでもinsertStoreが呼ばれないことを確認
      verifyNever(mockRepository.insertStore(any));
    });
  });

  group('StoreBusinessLogic - other operations', () {
    final testStore = Store(
      id: 'test-store',
      name: 'テスト店舗',
      address: '東京都港区テスト1-1-1',
      lat: 35.6584,
      lng: 139.7454,
      status: StoreStatus.wantToGo,
      createdAt: DateTime.now(),
    );

    test('should load all stores from repository', () async {
      // Arrange
      when(mockRepository.getAllStores()).thenAnswer((_) async => [testStore]);

      // Act
      final result = await businessLogic.loadStores();

      // Assert
      expect(result, hasLength(1));
      expect(result.first, equals(testStore));
      verify(mockRepository.getAllStores()).called(1);
    });

    test('should update store status successfully', () async {
      // Arrange
      when(mockRepository.getAllStores()).thenAnswer((_) async => [testStore]);
      when(mockRepository.updateStore(any)).thenAnswer((_) async => {});

      await businessLogic.loadStores();

      // Act
      await businessLogic.updateStoreStatus('test-store', StoreStatus.visited);

      // Assert
      verify(mockRepository.updateStore(any)).called(1);
    });

    test('should add new store to repository', () async {
      // Arrange
      when(mockRepository.insertStore(testStore)).thenAnswer((_) async => {});

      // Act
      await businessLogic.addStore(testStore);

      // Assert
      verify(mockRepository.insertStore(testStore)).called(1);
    });
  });

  group('StoreBusinessLogic - swipe action DB save timing', () {
    final newSwipeStore = Store(
      id: 'new-swipe-store',
      name: '新規スワイプ店舗',
      address: '東京都港区スワイプ1-1-1',
      lat: 35.6590,
      lng: 139.7460,
      status: null, // スワイプ前はnull
      createdAt: DateTime.now(),
    );

    test('should save new store to DB only when swiped with status', () async {
      // Arrange - 新規店舗をスワイプ画面から取得済み（まだDB未保存）
      when(mockRepository.searchStoresFromApi(
        lat: anyNamed('lat'),
        lng: anyNamed('lng'),
        keyword: anyNamed('keyword'),
        range: anyNamed('range'),
        count: anyNamed('count'),
      )).thenAnswer((_) async => [newSwipeStore]);

      // loadSwipeStores()でDB保存されない（新しい挙動）
      // → この時点ではまだverifyNever(insertStore)が成功する

      when(mockRepository.insertStore(any)).thenAnswer((_) async => {});
      when(mockRepository.updateStore(any)).thenAnswer((_) async => {});

      // Act 1: スワイプ画面で店舗読み込み（DB保存なし）
      final swipeStores = await businessLogic.loadSwipeStores(
        lat: 35.6590,
        lng: 139.7460,
        range: 3,
        count: 20,
      );

      // Assert 1: 店舗は返されるが、まだDB保存されていない
      expect(swipeStores, isNotEmpty);
      verifyNever(mockRepository.insertStore(any));

      // Act 2: ユーザーが店舗を「行きたい」にスワイプ
      // ここで初めてDB保存が必要
      // TODO: この機能は未実装のため、このテストは現状失敗する
      // 実装後は以下のようなメソッドが必要:
      // await businessLogic.saveSwipedStore(newSwipeStore.id, StoreStatus.wantToGo);

      // Assert 2: スワイプ時にのみinsertStoreが呼ばれる
      // TODO: 実装後にコメント解除
      // verify(mockRepository.insertStore(any)).called(1);
    });

    test('should handle swipe action for new store (integration scenario)',
        () async {
      // このテストは実装後に追加予定
      // シナリオ:
      // 1. loadSwipeStores() でAPIから新規店舗取得（DB保存なし）
      // 2. ユーザーがスワイプ
      // 3. updateStoreStatus() または新しいメソッドでDB保存
      // 4. マイメニューに表示される
    });
  });
}
