import 'package:chinese_food_app/core/entities/store.dart';

/// 店舗データへのアクセスを抽象化するRepository interface
abstract class StoreRepository {
  /// 全ての店舗を取得
  Future<List<Store>> getAllStores();

  /// ステータス別で店舗を取得
  Future<List<Store>> getStoresByStatus(StoreStatus status);

  /// IDで店舗を取得
  Future<Store?> getStoreById(String id);

  /// 店舗を挿入
  Future<String> insertStore(Store store);

  /// 店舗を更新
  Future<bool> updateStore(Store store);

  /// 店舗を削除
  Future<bool> deleteStore(String id);

  /// 店舗を検索（店名、住所、メモから）
  Future<List<Store>> searchStores(String query);
}
