import '../entities/store.dart';

abstract class StoreRepository {
  Future<List<Store>> getAllStores();
  Future<List<Store>> getStoresByStatus(StoreStatus status);
  Future<Store?> getStoreById(String id);
  Future<void> insertStore(Store store);
  Future<void> updateStore(Store store);
  Future<void> deleteStore(String id);
  Future<List<Store>> searchStores(String query);
}
