import '../../domain/entities/store.dart';
import '../../domain/repositories/store_repository.dart';
import '../datasources/hotpepper_proxy_datasource.dart';
import '../datasources/store_local_datasource.dart';

/// セキュア版Store Repository の実装クラス
///
/// プロキシサーバー経由でのAPI呼び出しを行うセキュアなリポジトリ実装
class SecureStoreRepositoryImpl implements StoreRepository {
  final HotpepperProxyDatasource proxyDatasource;
  final StoreLocalDatasource localDatasource;

  SecureStoreRepositoryImpl({
    required this.proxyDatasource,
    required this.localDatasource,
  });

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
    try {
      // プロキシサーバー経由でのみAPI呼び出しを行う
      final response = await proxyDatasource.searchStores(
        lat: lat,
        lng: lng,
        address: address,
        keyword: keyword,
        range: range,
        count: count,
        start: start,
      );

      return _convertToStoreEntities(response.shops);
    } catch (e) {
      rethrow; // Usecaseレイヤーでハンドリング
    }
  }

  /// HotpepperStoreModelのリストをStoreエンティティのリストに変換
  List<Store> _convertToStoreEntities(List<dynamic> hotpepperStores) {
    return hotpepperStores.map((hotpepperStore) {
      return Store(
        id: hotpepperStore.id,
        name: hotpepperStore.name,
        address: hotpepperStore.address,
        lat: hotpepperStore.lat ?? 0.0,
        lng: hotpepperStore.lng ?? 0.0,
        imageUrl: hotpepperStore.photo,
        status: StoreStatus.wantToGo,
        memo: hotpepperStore.catch_,
        createdAt: DateTime.now(),
      );
    }).toList();
  }

  // ローカルデータ操作メソッドは従来のまま
  @override
  Future<void> insertStore(Store store) async {
    try {
      await localDatasource.insertStore(store);
    } catch (e) {
      throw Exception('店舗の保存に失敗しました: ${e.toString()}');
    }
  }

  @override
  Future<List<Store>> searchStores(String query) async {
    try {
      return await localDatasource.searchStores(query);
    } catch (e) {
      throw Exception('店舗検索に失敗しました: ${e.toString()}');
    }
  }

  @override
  Future<void> updateStore(Store store) async {
    try {
      await localDatasource.updateStore(store);
    } catch (e) {
      throw Exception('店舗の更新に失敗しました: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteStore(String storeId) async {
    try {
      await localDatasource.deleteStore(storeId);
    } catch (e) {
      throw Exception('店舗の削除に失敗しました: ${e.toString()}');
    }
  }

  @override
  Future<Store?> getStoreById(String storeId) async {
    try {
      return await localDatasource.getStoreById(storeId);
    } catch (e) {
      throw Exception('店舗の取得に失敗しました: ${e.toString()}');
    }
  }

  @override
  Future<List<Store>> getStoresByStatus(StoreStatus status) async {
    try {
      return await localDatasource.getStoresByStatus(status);
    } catch (e) {
      throw Exception('店舗一覧の取得に失敗しました: ${e.toString()}');
    }
  }

  @override
  Future<List<Store>> getAllStores() async {
    try {
      return await localDatasource.getAllStores();
    } catch (e) {
      throw Exception('全店舗の取得に失敗しました: ${e.toString()}');
    }
  }

  /// 店舗が存在するかチェック
  Future<bool> isStoreExists(String storeId) async {
    try {
      final store = await localDatasource.getStoreById(storeId);
      return store != null;
    } catch (e) {
      return false;
    }
  }
}
