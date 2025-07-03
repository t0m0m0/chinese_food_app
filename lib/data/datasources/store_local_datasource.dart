import '../../domain/entities/store.dart';

/// 店舗データのローカルデータソースインターフェース
abstract class StoreLocalDatasource {
  /// 店舗を挿入
  Future<void> insertStore(Store store);

  /// 店舗を更新
  Future<void> updateStore(Store store);

  /// 店舗を削除
  Future<void> deleteStore(String id);

  /// IDで店舗を取得
  Future<Store?> getStoreById(String id);

  /// ステータスで店舗を検索
  Future<List<Store>> getStoresByStatus(StoreStatus status);

  /// 店舗をクエリで検索
  Future<List<Store>> searchStores(String query);

  /// 全店舗を取得
  Future<List<Store>> getAllStores();
}
