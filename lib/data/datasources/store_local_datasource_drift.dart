import 'package:drift/drift.dart';
import '../../core/database/schema/app_database.dart';
import '../../domain/entities/store.dart' as entities;
import 'store_local_datasource.dart';

/// Drift版のローカルデータベースでの店舗データアクセス
class StoreLocalDatasourceDrift implements StoreLocalDatasource {
  final AppDatabase _database;

  StoreLocalDatasourceDrift(this._database);

  @override
  Future<void> insertStore(entities.Store store) async {
    await _database.into(_database.stores).insert(_storeToCompanion(store));
  }

  @override
  Future<void> updateStore(entities.Store store) async {
    await (_database.update(_database.stores)
          ..where((tbl) => tbl.id.equals(store.id)))
        .write(_storeToCompanion(store));
  }

  @override
  Future<void> deleteStore(String storeId) async {
    await (_database.delete(_database.stores)
          ..where((tbl) => tbl.id.equals(storeId)))
        .go();
  }

  @override
  Future<entities.Store?> getStoreById(String storeId) async {
    final query = _database.select(_database.stores)
      ..where((tbl) => tbl.id.equals(storeId));

    final result = await query.getSingleOrNull();
    return result != null ? _driftStoreToEntity(result) : null;
  }

  @override
  Future<List<entities.Store>> getAllStores() async {
    final query = _database.select(_database.stores)
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);

    final results = await query.get();
    return results.map((store) => _driftStoreToEntity(store)).toList();
  }

  @override
  Future<List<entities.Store>> getStoresByStatus(
      entities.StoreStatus status) async {
    final query = _database.select(_database.stores)
      ..where((tbl) => tbl.status.equals(status.value))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);

    final results = await query.get();
    return results.map((store) => _driftStoreToEntity(store)).toList();
  }

  @override
  Future<List<entities.Store>> searchStores(String query) async {
    final searchQuery = _database.select(_database.stores)
      ..where((tbl) =>
          tbl.name.like('%$query%') |
          tbl.address.like('%$query%') |
          tbl.memo.like('%$query%'))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);

    final results = await searchQuery.get();
    return results.map((store) => _driftStoreToEntity(store)).toList();
  }

  /// Store エンティティを Drift Companion に変換
  StoresCompanion _storeToCompanion(entities.Store store) {
    return StoresCompanion(
      id: Value(store.id),
      name: Value(store.name),
      address: Value(store.address),
      lat: Value(store.lat),
      lng: Value(store.lng),
      imageUrl: Value(store.imageUrl),
      status: Value(store.status?.value ?? 'want_to_go'),
      memo: Value(store.memo ?? ''),
      createdAt: Value(store.createdAt.toIso8601String()),
    );
  }

  /// Drift Store を Entity に変換
  entities.Store _driftStoreToEntity(Store store) {
    return entities.Store(
      id: store.id,
      name: store.name,
      address: store.address,
      lat: store.lat,
      lng: store.lng,
      imageUrl: store.imageUrl,
      status: entities.StoreStatus.values.firstWhere(
        (s) => s.value == store.status,
        orElse: () => entities.StoreStatus.wantToGo,
      ),
      memo: store.memo.isEmpty ? null : store.memo,
      createdAt: DateTime.parse(store.createdAt),
    );
  }
}
