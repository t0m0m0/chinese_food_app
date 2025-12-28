import 'package:flutter/foundation.dart';

import '../../domain/entities/store.dart';
import '../../domain/repositories/store_repository.dart';
import '../../core/constants/string_constants.dart';
import '../../core/constants/debug_constants.dart';

class StoreBusinessLogic {
  final StoreRepository _repository;
  List<Store> _stores = [];

  StoreBusinessLogic({
    required StoreRepository repository,
  }) : _repository = repository;

  List<Store> get allStores => List.unmodifiable(_stores);

  Future<List<Store>> loadStores() async {
    _stores = await _repository.getAllStores();
    return List.unmodifiable(_stores);
  }

  /// Updates store status and saves to DB
  ///
  /// スワイプ画面から呼ばれた場合:
  /// - 新規店舗（DB未保存）→ insertStore()
  /// - 既存店舗 → updateStore()
  Future<void> updateStoreStatus(String storeId, StoreStatus newStatus) async {
    final storeIndex = _stores.indexWhere((store) => store.id == storeId);

    if (storeIndex == -1) {
      throw Exception('店舗が見つかりません: $storeId');
    }

    final originalStore = _stores[storeIndex];
    final updatedStore = originalStore.copyWith(status: newStatus);

    await _repository.updateStore(updatedStore);
    _stores[storeIndex] = updatedStore;
  }

  /// Saves a swiped store to DB with status
  ///
  /// スワイプ時に呼ばれる。新規店舗の場合はinsert、既存店舗の場合はupdateを行う
  Future<void> saveSwipedStore(Store store, StoreStatus status) async {
    final storeWithStatus = store.copyWith(status: status);

    // DBに既に存在するかチェック
    final existingStore = await _repository.getStoreById(store.id);

    if (existingStore == null) {
      // 新規店舗 → insert
      await _repository.insertStore(storeWithStatus);
      _stores.add(storeWithStatus);
    } else {
      // 既存店舗 → update
      await _repository.updateStore(storeWithStatus);
      final index = _stores.indexWhere((s) => s.id == store.id);
      if (index != -1) {
        _stores[index] = storeWithStatus;
      } else {
        // メモリ内にない場合は追加
        _stores.add(storeWithStatus);
      }
    }
  }

  Future<void> addStore(Store store) async {
    await _repository.insertStore(store);
    _stores.add(store);
  }

  /// 全店舗を削除（デバッグ用）
  Future<void> deleteAllStores() async {
    await _repository.deleteAllStores();
    _stores.clear();
    debugPrint('[StoreBusinessLogic] 🗑️ 全店舗データを削除しました');
  }

  /// API から新しい店舗を検索して取得
  ///
  /// 検索結果は重複チェックせず、そのまま返す
  /// （検索画面では同じ店舗でも毎回表示すべき）
  /// データベースへの保存も行わない（検索は表示のみ）
  Future<List<Store>> loadNewStoresFromApi({
    double? lat,
    double? lng,
    String? address,
    String? keyword = StringConstants.defaultSearchKeyword,
    int range = 3,
    int count = 10,
    int start = 1,
  }) async {
    if (DebugConstants.enableApiLog) {
      debugPrint(
          '[SearchAPI] 🔍 検索開始 - lat: $lat, lng: $lng, range: $range, count: $count, start: $start');
    }

    final apiStores = await _repository.searchStoresFromApi(
      lat: lat,
      lng: lng,
      address: address,
      keyword: keyword,
      range: range,
      count: count,
      start: start,
    );

    if (DebugConstants.enableApiLog) {
      debugPrint('[SearchAPI] 🔍 検索結果: ${apiStores.length}件');
    }

    // 検索結果はそのまま返す（重複チェック不要、DB保存も不要）
    return apiStores;
  }

  /// スワイプ画面用の店舗取得（ステータス未設定の店舗のみ）
  ///
  /// DB保存は行わず、スワイプ可能な店舗リストのみを返す
  /// 実際のDB保存はスワイプ時に行われる
  ///
  /// Issue #245対応: フィルタリング後の店舗数が閾値以下の場合、
  /// 自動的に次ページを取得して十分な店舗数を確保する
  Future<List<Store>> loadSwipeStores({
    required double lat,
    required double lng,
    int range = 3,
    int count = 20,
  }) async {
    final allFilteredStores = <Store>[];
    var currentStart = 1;
    var hasMorePages = true;

    final existingStoreMaps = _buildExistingStoreMaps();

    if (DebugConstants.enableApiLog) {
      debugPrint('[SwipeStores] 🔍 DB内の既存店舗数: ${_stores.length}');
      debugPrint(
          '[SwipeStores]   - ID別マップサイズ: ${existingStoreMaps.byId.length}');
      debugPrint(
          '[SwipeStores]   - 位置別マップサイズ: ${existingStoreMaps.byLocation.length}');
    }

    // Issue #245: APIから取得可能な全店舗を取得し続ける
    // フィルタリング後の件数に関わらず、次ページがあれば取得を継続
    while (hasMorePages) {
      final apiStores = await _fetchStoresFromApi(lat, lng, range, count,
          start: currentStart);

      if (DebugConstants.enableApiLog) {
        debugPrint(
            '[SwipeStores] 🔍 APIから取得した店舗数: ${apiStores.length} (start=$currentStart)');
      }

      // APIから店舗が返されなかった場合、これ以上ページがない
      if (apiStores.isEmpty) {
        hasMorePages = false;
        break;
      }

      final filteredStores = _filterSwipeStores(apiStores, existingStoreMaps);

      if (DebugConstants.enableApiLog) {
        debugPrint('[SwipeStores] 🔍 フィルタリング後の店舗数: ${filteredStores.length}');
      }

      allFilteredStores.addAll(filteredStores);

      // 次ページの開始位置を計算
      currentStart += count;

      // APIから取得した店舗数がcount未満なら、これ以上ページがない
      if (apiStores.length < count) {
        hasMorePages = false;
      }
    }

    if (DebugConstants.enableApiLog) {
      debugPrint('[SwipeStores] 🔍 最終的な店舗数: ${allFilteredStores.length}');
    }

    return allFilteredStores;
  }

  /// スワイプ画面用の追加店舗取得（ページネーション）
  ///
  /// 次ページの店舗を取得し、ステータス未設定の店舗のみをフィルタリングして返す
  Future<List<Store>> loadMoreSwipeStores({
    required double lat,
    required double lng,
    int range = 3,
    int count = 20,
    int start = 1,
  }) async {
    final apiStores =
        await _fetchStoresFromApi(lat, lng, range, count, start: start);

    if (DebugConstants.enableApiLog) {
      debugPrint('[SwipeStores] 📄 ページ取得: ${apiStores.length}件');
    }

    final existingStoreMaps = _buildExistingStoreMaps();
    final filteredStores = _filterSwipeStores(apiStores, existingStoreMaps);

    if (DebugConstants.enableApiLog) {
      debugPrint('[SwipeStores] 📄 フィルタリング後: ${filteredStores.length}件');
    }

    return filteredStores;
  }

  /// Fetches stores from API with specified parameters
  Future<List<Store>> _fetchStoresFromApi(
    double lat,
    double lng,
    int range,
    int count, {
    int start = 1,
  }) async {
    return await _repository.searchStoresFromApi(
      lat: lat,
      lng: lng,
      keyword: StringConstants.apiKeywordParameter,
      range: range,
      count: count,
      start: start,
    );
  }

  /// Builds maps of existing stores by ID and location for efficient lookup
  ({Map<String, StoreStatus?> byId, Map<String, StoreStatus?> byLocation})
      _buildExistingStoreMaps() {
    final existingStoreMap = <String, StoreStatus?>{};
    final existingLocations = <String, StoreStatus?>{};

    for (final store in _stores) {
      existingStoreMap[store.id] = store.status;
      final locationKey = _createLocationKey(store.lat, store.lng);
      existingLocations[locationKey] = store.status;
    }

    return (byId: existingStoreMap, byLocation: existingLocations);
  }

  /// Filters API stores for swipe functionality (no DB operations)
  ///
  /// スワイプ用の店舗リストをフィルタリング（DB保存なし）
  /// - 既存店舗でステータスがnullのもの → 含める
  /// - 新規店舗 → 含める（DB保存はスワイプ時）
  /// - 既存店舗でステータスありのもの → 除外
  List<Store> _filterSwipeStores(
    List<Store> apiStores,
    ({
      Map<String, StoreStatus?> byId,
      Map<String, StoreStatus?> byLocation
    }) existingStoreMaps,
  ) {
    final swipeStores = <Store>[];

    for (final apiStore in apiStores) {
      final shouldInclude =
          _shouldIncludeInSwipeList(apiStore, existingStoreMaps);
      if (shouldInclude) {
        swipeStores.add(apiStore);
      }
    }

    return swipeStores;
  }

  /// Determines if a store should be included in swipe list
  bool _shouldIncludeInSwipeList(
    Store apiStore,
    ({
      Map<String, StoreStatus?> byId,
      Map<String, StoreStatus?> byLocation
    }) existingStoreMaps,
  ) {
    final locationKey = _createLocationKey(apiStore.lat, apiStore.lng);

    // IDベースのチェック: キーが存在し、かつステータスがnullでない場合に除外
    if (existingStoreMaps.byId.containsKey(apiStore.id)) {
      final existingStatusById = existingStoreMaps.byId[apiStore.id];
      if (existingStatusById != null) {
        if (DebugConstants.enableSwipeFilterLog) {
          debugPrint('[SwipeFilter] 除外: ID存在 & ステータスあり');
        }
        return false; // ステータスあり → スワイプ済み → 除外
      }
      // ステータスがnullの場合は続行（スワイプ可能）
    }

    // 位置ベースのチェック: キーが存在し、かつステータスがnullでない場合に除外
    if (existingStoreMaps.byLocation.containsKey(locationKey)) {
      final existingStatusByLocation =
          existingStoreMaps.byLocation[locationKey];
      if (existingStatusByLocation != null) {
        if (DebugConstants.enableSwipeFilterLog) {
          debugPrint('[SwipeFilter] 除外: 位置存在 & ステータスあり');
        }
        return false; // ステータスあり → スワイプ済み → 除外
      }
      // ステータスがnullの場合は続行（スワイプ可能）
    }

    // 新規店舗、または既存でステータスnullの場合 → スワイプ可能
    if (DebugConstants.enableSwipeFilterLog) {
      debugPrint('[SwipeFilter] 含める: スワイプ可能');
    }
    return true;
  }

  /// Creates a consistent location key for store coordinates
  String _createLocationKey(double lat, double lng) {
    return '${lat}_$lng';
  }
}
