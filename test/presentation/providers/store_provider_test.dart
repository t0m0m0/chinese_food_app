import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/domain/repositories/store_repository.dart';
import 'package:chinese_food_app/presentation/providers/store_provider.dart';

// シンプルなテストダブル
class FakeStoreRepository implements StoreRepository {
  List<Store> _stores = [];
  bool _shouldThrowOnUpdate = false;
  bool _shouldThrowOnInsert = false;
  bool _shouldThrowOnGetAll = false;

  void setShouldThrowOnUpdate(bool value) => _shouldThrowOnUpdate = value;
  void setShouldThrowOnInsert(bool value) => _shouldThrowOnInsert = value;
  void setShouldThrowOnGetAll(bool value) => _shouldThrowOnGetAll = value;

  @override
  Future<List<Store>> getAllStores() async {
    if (_shouldThrowOnGetAll) throw Exception('Database error');
    return List.from(_stores);
  }

  @override
  Future<void> insertStore(Store store) async {
    if (_shouldThrowOnInsert) throw Exception('Insert failed');
    _stores.add(store);
  }

  @override
  Future<void> updateStore(Store store) async {
    if (_shouldThrowOnUpdate) throw Exception('Update failed');
    final index = _stores.indexWhere((s) => s.id == store.id);
    if (index != -1) _stores[index] = store;
  }

  @override
  Future<void> deleteStore(String storeId) async {
    _stores.removeWhere((s) => s.id == storeId);
  }

  @override
  Future<Store?> getStoreById(String storeId) async {
    try {
      return _stores.firstWhere((s) => s.id == storeId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Store>> getStoresByStatus(StoreStatus status) async {
    return _stores.where((s) => s.status == status).toList();
  }

  @override
  Future<List<Store>> searchStores(String query) async {
    return _stores.where((s) => s.name.contains(query)).toList();
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
    // テスト用の実装
    return [];
  }

  void setStores(List<Store> stores) {
    _stores = List.from(stores);
  }
}

void main() {
  late StoreProvider storeProvider;
  late FakeStoreRepository fakeRepository;

  setUp(() {
    fakeRepository = FakeStoreRepository();
    storeProvider = StoreProvider(repository: fakeRepository);
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
      fakeRepository.setStores(testStores);

      await storeProvider.loadStores();

      expect(storeProvider.stores, hasLength(2));
      expect(storeProvider.wantToGoStores, hasLength(1));
      expect(storeProvider.visitedStores, hasLength(1));
      expect(storeProvider.badStores, isEmpty);
      expect(storeProvider.isLoading, false);
      expect(storeProvider.error, isNull);
    });

    test('should handle loading error', () async {
      fakeRepository.setShouldThrowOnGetAll(true);

      await storeProvider.loadStores();

      expect(storeProvider.stores, isEmpty);
      expect(storeProvider.isLoading, false);
      expect(storeProvider.error, isNotNull);
    });

    test('should update store status successfully', () async {
      fakeRepository.setStores(testStores);

      await storeProvider.loadStores();
      final store = testStores.first;

      await storeProvider.updateStoreStatus(store.id, StoreStatus.visited);

      expect(storeProvider.wantToGoStores, isEmpty);
      expect(storeProvider.visitedStores, hasLength(2));
      expect(storeProvider.error, isNull);
    });

    test('should handle update store status error', () async {
      fakeRepository.setStores(testStores);
      fakeRepository.setShouldThrowOnUpdate(true);

      await storeProvider.loadStores();
      final store = testStores.first;

      await storeProvider.updateStoreStatus(store.id, StoreStatus.visited);

      expect(storeProvider.error, isNotNull);
    });

    test('should maintain data consistency when update fails', () async {
      fakeRepository.setStores(testStores);
      fakeRepository.setShouldThrowOnUpdate(true);

      await storeProvider.loadStores();
      final originalStores = List<Store>.from(storeProvider.stores);
      final originalStatus = storeProvider.stores.first.status;

      await storeProvider.updateStoreStatus('store-1', StoreStatus.visited);

      // データベース更新失敗後、ローカル状態が変更されていないことを確認
      expect(storeProvider.stores.first.status, equals(originalStatus));
      expect(storeProvider.stores.length, equals(originalStores.length));
      expect(storeProvider.stores.first.id, equals(originalStores.first.id));
      expect(storeProvider.error, isNotNull);
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

      await storeProvider.loadStores();
      await storeProvider.addStore(newStore);

      expect(storeProvider.stores, contains(newStore));
      expect(storeProvider.wantToGoStores, contains(newStore));
      expect(storeProvider.error, isNull);
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

      fakeRepository.setShouldThrowOnInsert(true);

      await storeProvider.loadStores();
      await storeProvider.addStore(newStore);

      expect(storeProvider.error, isNotNull);
    });

    test('should clear error', () async {
      fakeRepository.setShouldThrowOnGetAll(true);

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

      fakeRepository.setStores(mixedStores);

      await storeProvider.loadStores();

      expect(storeProvider.stores, hasLength(3));
      expect(storeProvider.wantToGoStores, hasLength(1));
      expect(storeProvider.visitedStores, hasLength(1));
      expect(storeProvider.badStores, hasLength(1));
    });
  });
}
