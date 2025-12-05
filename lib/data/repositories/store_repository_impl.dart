import 'package:flutter/foundation.dart';

import '../../domain/entities/store.dart';
import '../../domain/repositories/store_repository.dart';
import '../datasources/hotpepper_proxy_datasource.dart';
import '../datasources/store_local_datasource.dart';

/// Store Repository の実装クラス
///
/// ローカルデータベースとAPI通信を管理し、
/// Clean Architecture のRepository パターンを実装する
class StoreRepositoryImpl implements StoreRepository {
  final HotpepperProxyDatasource apiDatasource;
  final StoreLocalDatasource localDatasource;

  StoreRepositoryImpl({
    required this.apiDatasource,
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
      debugPrint(
          '📡 API呼び出し開始 - lat: $lat, lng: $lng, address: $address, keyword: $keyword');

      final response = await apiDatasource.searchStores(
        lat: lat,
        lng: lng,
        address: address,
        keyword: keyword,
        range: range,
        count: count,
        start: start,
      );

      debugPrint('[Repository] 📡 API応答受信 - 店舗数: ${response.shops.length}');

      // API結果をDomainエンティティに変換
      // 重要: ステータスはnullで保存（ユーザーがスワイプで決定する）
      final stores = response.shops.map((hotpepperStore) {
        return Store(
          id: hotpepperStore.id,
          name: hotpepperStore.name,
          address: hotpepperStore.address,
          lat: hotpepperStore.lat ?? 0.0,
          lng: hotpepperStore.lng ?? 0.0,
          imageUrl: hotpepperStore.photo, // 画像URLを追加
          status: null, // スワイプ前はステータスなし
          memo: hotpepperStore.catch_,
          createdAt: DateTime.now(),
        );
      }).toList();

      debugPrint('[Repository] 📡 エンティティ変換完了 - 変換後店舗数: ${stores.length}');
      for (var i = 0; i < stores.length && i < 5; i++) {
        debugPrint(
            '[Repository]   [$i] ${stores[i].name} (${stores[i].address})');
      }
      if (stores.length > 5) {
        debugPrint('[Repository]   ... 他 ${stores.length - 5}件');
      }

      return stores;
    } catch (e) {
      debugPrint('[Repository] ❌ API呼び出しエラー: $e');
      rethrow; // Usecaseレイヤーでハンドリング
    }
  }

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
  Future<void> deleteAllStores() async {
    try {
      await localDatasource.deleteAllStores();
      debugPrint('[Repository] 🗑️ 全店舗データを削除しました');
    } catch (e) {
      debugPrint('[Repository] ❌ 全店舗削除エラー: $e');
      throw Exception('全店舗の削除に失敗しました: ${e.toString()}');
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
