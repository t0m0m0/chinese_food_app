import 'package:flutter/foundation.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/domain/entities/location.dart';
import 'package:chinese_food_app/domain/repositories/store_repository.dart';
import 'package:chinese_food_app/domain/services/location_service.dart';
import 'package:chinese_food_app/presentation/providers/store_provider.dart';

class MockStoreRepository implements StoreRepository {
  final List<Store> _stores = [];

  @override
  Future<List<Store>> getAllStores() async => List.from(_stores);

  @override
  Future<void> insertStore(Store store) async {
    _stores.add(store);
  }

  @override
  Future<void> updateStore(Store store) async {
    final index = _stores.indexWhere((s) => s.id == store.id);
    if (index != -1) {
      _stores[index] = store;
    }
  }

  @override
  Future<void> deleteStore(String id) async {
    _stores.removeWhere((store) => store.id == id);
  }

  @override
  Future<void> deleteAllStores() async {
    _stores.clear();
  }

  @override
  Future<Store?> getStoreById(String id) async {
    try {
      return _stores.firstWhere((store) => store.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Store>> getStoresByStatus(StoreStatus status) async {
    return _stores.where((store) => store.status == status).toList();
  }

  @override
  Future<List<Store>> searchStores(String query) async => [];

  @override
  Future<List<Store>> searchStoresFromApi({
    double? lat,
    double? lng,
    String? address,
    String? keyword,
    int range = 3,
    int count = 20,
    int start = 1,
  }) async =>
      [];
}

class MockStoreProvider extends ChangeNotifier {
  final bool _isLoading = false;
  String? _error;

  // Callback for testing status updates
  Future<void> Function(String storeId, StoreStatus status)?
      updateStoreStatusCallback;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Store> get stores => [];
  List<Store> get wantToGoStores => [];
  List<Store> get visitedStores => [];
  List<Store> get badStores => [];

  Future<void> loadStores() async {
    // Mock implementation
  }

  Future<void> updateStoreStatus(String storeId, StoreStatus status) async {
    // Call the callback if set
    if (updateStoreStatusCallback != null) {
      await updateStoreStatusCallback!(storeId, status);
    }
    // Mock implementation
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

class MockLocationService implements LocationService {
  @override
  Future<Location> getCurrentLocation() async {
    return Location(
      latitude: 35.6917,
      longitude: 139.7006,
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

class TestsHelper {
  /// StoreProviderのインスタンスを作成（テスト用）
  static StoreProvider createStoreProvider() {
    return StoreProvider(
      repository: MockStoreRepository(),
      locationService: MockLocationService(),
    );
  }

  /// テスト用のStoreを作成
  static Store createTestStore({
    String? id,
    String? name,
    String? address,
    double lat = 35.6812,
    double lng = 139.7671,
    StoreStatus? status,
    String? memo,
  }) {
    return Store(
      id: id ?? 'test-store-${DateTime.now().millisecondsSinceEpoch}',
      name: name ?? 'Test Store',
      address: address ?? 'Test Address',
      lat: lat,
      lng: lng,
      status: status,
      memo: memo,
      createdAt: DateTime.now(),
    );
  }
}
