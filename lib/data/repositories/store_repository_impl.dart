import '../../domain/entities/store.dart';
import '../../domain/repositories/store_repository.dart';
import '../datasources/store_local_datasource.dart';
import '../models/store_model.dart';

class StoreRepositoryImpl implements StoreRepository {
  final StoreLocalDatasource _localDatasource;

  StoreRepositoryImpl(this._localDatasource);

  @override
  Future<List<Store>> getAllStores() async {
    final storeModels = await _localDatasource.getAllStores();
    return storeModels.cast<Store>();
  }

  @override
  Future<List<Store>> getStoresByStatus(StoreStatus status) async {
    final storeModels = await _localDatasource.getStoresByStatus(status);
    return storeModels.cast<Store>();
  }

  @override
  Future<Store?> getStoreById(String id) async {
    final storeModel = await _localDatasource.getStoreById(id);
    return storeModel;
  }

  @override
  Future<void> insertStore(Store store) async {
    final storeModel = StoreModel.fromEntity(store);
    await _localDatasource.insertStore(storeModel);
  }

  @override
  Future<void> updateStore(Store store) async {
    final storeModel = StoreModel.fromEntity(store);
    await _localDatasource.updateStore(storeModel);
  }

  @override
  Future<void> deleteStore(String id) async {
    await _localDatasource.deleteStore(id);
  }

  @override
  Future<List<Store>> searchStores(String query) async {
    final storeModels = await _localDatasource.searchStores(query);
    return storeModels.cast<Store>();
  }
}