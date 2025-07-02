import 'package:flutter/foundation.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/domain/repositories/store_repository.dart';

class MockStoreRepository implements StoreRepository {
  @override
  Future<List<Store>> getAllStores() async => [];

  @override
  Future<void> insertStore(Store store) async {}

  @override
  Future<void> updateStore(Store store) async {}

  @override
  Future<void> deleteStore(String id) async {}

  @override
  Future<Store?> getStoreById(String id) async => null;

  @override
  Future<List<Store>> getStoresByStatus(StoreStatus status) async => [];

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
