import '../../core/database/database_helper.dart';
import '../../domain/entities/photo.dart';
import '../../domain/entities/store.dart';
import '../../domain/repositories/store_repository.dart';
import '../datasources/hotpepper_api_datasource.dart';
import '../datasources/store_local_datasource.dart';
import '../models/photo_model.dart';
import '../models/store_model.dart';

class StoreRepositoryImpl implements StoreRepository {
  final StoreLocalDatasource _localDatasource;
  final DatabaseHelper _databaseHelper;
  final HotpepperApiDatasource _apiDatasource;

  StoreRepositoryImpl(
    this._localDatasource,
    this._databaseHelper,
    this._apiDatasource,
  );

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
    final response = await _apiDatasource.searchStores(
      lat: lat,
      lng: lng,
      address: address,
      keyword: keyword,
      range: range,
      count: count,
      start: start,
    );

    return response.shops.map((hotpepperStore) {
      return Store(
        id: hotpepperStore.id,
        name: hotpepperStore.name,
        address: hotpepperStore.address,
        lat: hotpepperStore.lat ?? 0.0,
        lng: hotpepperStore.lng ?? 0.0,
        status: null,
        memo: hotpepperStore.catch_,
        createdAt: DateTime.now(),
      );
    }).toList();
  }

  // ページネーション対応メソッド
  Future<List<Store>> getStoresPaginated({
    int page = 0,
    int pageSize = 20,
  }) async {
    final storeModels = await _localDatasource.getStoresPaginated(
      page: page,
      pageSize: pageSize,
    );
    return storeModels.cast<Store>();
  }

  // トランザクション対応メソッド
  Future<void> insertStoreWithPhotos(
    Store store,
    List<Photo> photos,
  ) async {
    try {
      final db = await _databaseHelper.database;
      await db.transaction((txn) async {
        // Store insertion
        await txn.insert(
          'stores',
          StoreModel.fromEntity(store).toMap(),
        );

        // Photos insertion
        for (final photo in photos) {
          await txn.insert(
            'photos',
            PhotoModel.fromEntity(photo).toMap(),
          );
        }
      });
    } catch (e) {
      throw Exception('Failed to insert store with photos: ${e.toString()}');
    }
  }

  Future<void> deleteStoreWithRelatedData(String storeId) async {
    try {
      final db = await _databaseHelper.database;
      await db.transaction((txn) async {
        // Delete related photos first
        await txn.delete(
          'photos',
          where: 'store_id = ?',
          whereArgs: [storeId],
        );

        // Delete related visit records
        await txn.delete(
          'visit_records',
          where: 'store_id = ?',
          whereArgs: [storeId],
        );

        // Finally delete the store
        await txn.delete(
          'stores',
          where: 'id = ?',
          whereArgs: [storeId],
        );
      });
    } catch (e) {
      throw Exception(
          'Failed to delete store with related data: ${e.toString()}');
    }
  }
}
