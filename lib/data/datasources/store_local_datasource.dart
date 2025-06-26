import '../../domain/entities/store.dart';
import '../../core/database/database_helper.dart';

/// ローカルデータベースでの店舗データアクセス
///
/// SQLiteを使用した店舗情報のCRUD操作を提供
abstract class StoreLocalDatasource {
  Future<void> insertStore(Store store);
  Future<void> updateStore(Store store);
  Future<void> deleteStore(String storeId);
  Future<Store?> getStoreById(String storeId);
  Future<List<Store>> getAllStores();
  Future<List<Store>> getStoresByStatus(StoreStatus status);
  Future<List<Store>> searchStores(String query);
}

/// StoreLocalDatasource の実装クラス
class StoreLocalDatasourceImpl implements StoreLocalDatasource {
  final DatabaseHelper dbHelper;

  StoreLocalDatasourceImpl({required this.dbHelper});

  @override
  Future<void> insertStore(Store store) async {
    final db = await dbHelper.database;
    await db.insert('stores', _storeToMap(store));
  }

  @override
  Future<void> updateStore(Store store) async {
    final db = await dbHelper.database;
    await db.update(
      'stores',
      _storeToMap(store),
      where: 'id = ?',
      whereArgs: [store.id],
    );
  }

  @override
  Future<void> deleteStore(String storeId) async {
    final db = await dbHelper.database;
    await db.delete(
      'stores',
      where: 'id = ?',
      whereArgs: [storeId],
    );
  }

  @override
  Future<Store?> getStoreById(String storeId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'stores',
      where: 'id = ?',
      whereArgs: [storeId],
    );

    if (maps.isNotEmpty) {
      return _mapToStore(maps.first);
    }
    return null;
  }

  @override
  Future<List<Store>> getAllStores() async {
    final db = await dbHelper.database;
    final maps = await db.query('stores', orderBy: 'created_at DESC');
    return maps.map((map) => _mapToStore(map)).toList();
  }

  @override
  Future<List<Store>> getStoresByStatus(StoreStatus status) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'stores',
      where: 'status = ?',
      whereArgs: [status.name],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => _mapToStore(map)).toList();
  }

  @override
  Future<List<Store>> searchStores(String query) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'stores',
      where: 'name LIKE ? OR address LIKE ? OR memo LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => _mapToStore(map)).toList();
  }

  /// Store エンティティを Map に変換
  Map<String, dynamic> _storeToMap(Store store) {
    return {
      'id': store.id,
      'name': store.name,
      'address': store.address,
      'lat': store.lat,
      'lng': store.lng,
      'status': store.status?.name,
      'memo': store.memo,
      'created_at': store.createdAt.toIso8601String(),
    };
  }

  /// Map を Store エンティティに変換
  Store _mapToStore(Map<String, dynamic> map) {
    return Store(
      id: map['id'] as String,
      name: map['name'] as String,
      address: map['address'] as String,
      lat: map['lat'] as double,
      lng: map['lng'] as double,
      status: StoreStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => StoreStatus.wantToGo,
      ),
      memo: map['memo'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
