import '../../domain/entities/store.dart';
import '../../core/config/cache_config.dart';

/// 店舗データのフィルタリング結果をキャッシュするマネージャー
///
/// ## キャッシュ戦略
/// - ステータスごとのフィルタリング結果をメモリにキャッシュ
/// - DBから読み込んだ全店舗リストから、ステータスでフィルタリングした結果を保持
/// - キャッシュの有効期限はCacheConfig.storeCacheMaxAgeMillisecondsで管理
///
/// ## キャッシュクリアのタイミング
/// 1. DBデータが変更された時（loadStores()実行後）
/// 2. 距離変更でAPI検索を実行した後（loadSwipeStores()実行後）
/// 3. キャッシュの有効期限が切れた時
///
/// ## 重要な注意点
/// - マイメニュー画面でステータスごとの店舗リストを表示するため、
///   DBデータの変更後は必ずclearCache()を呼び出す必要がある
/// - キャッシュをクリアしないと、画面に古いデータが表示され続ける
class StoreCacheManager {
  List<Store>? _cachedWantToGoStores;
  List<Store>? _cachedVisitedStores;
  List<Store>? _cachedBadStores;
  int? _lastCacheUpdateTime;

  /// 「行きたい」ステータスの店舗リストを取得（キャッシュ使用）
  List<Store> getWantToGoStores(List<Store> allStores) {
    _checkCacheExpiry();
    _cachedWantToGoStores ??= List.unmodifiable(allStores
        .where((store) => store.status == StoreStatus.wantToGo)
        .toList());
    return _cachedWantToGoStores!;
  }

  /// 「行った」ステータスの店舗リストを取得（キャッシュ使用）
  List<Store> getVisitedStores(List<Store> allStores) {
    _checkCacheExpiry();
    _cachedVisitedStores ??= List.unmodifiable(allStores
        .where((store) => store.status == StoreStatus.visited)
        .toList());
    return _cachedVisitedStores!;
  }

  /// 「興味なし」ステータスの店舗リストを取得（キャッシュ使用）
  List<Store> getBadStores(List<Store> allStores) {
    _checkCacheExpiry();
    _cachedBadStores ??= List.unmodifiable(
        allStores.where((store) => store.status == StoreStatus.bad).toList());
    return _cachedBadStores!;
  }

  /// ステータス未設定（新規）の店舗リストを取得（キャッシュなし）
  List<Store> getNewStores(List<Store> allStores) {
    return allStores.where((store) => store.status == null).toList();
  }

  /// キャッシュの有効期限をチェックし、期限切れの場合はクリア
  void _checkCacheExpiry() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lastCacheUpdateTime != null &&
        (now - _lastCacheUpdateTime!) >
            CacheConfig.storeCacheMaxAgeMilliseconds) {
      clearCache();
    }
  }

  /// 全てのキャッシュをクリアし、キャッシュ更新時刻を現在時刻に設定
  ///
  /// ## 呼び出しタイミング
  /// - StoreProvider.loadStores()実行後
  /// - StoreProvider.loadSwipeStores()実行後
  /// - 店舗データがDBで変更された後
  void clearCache() {
    _cachedWantToGoStores = null;
    _cachedVisitedStores = null;
    _cachedBadStores = null;
    _lastCacheUpdateTime = DateTime.now().millisecondsSinceEpoch;
  }

  /// キャッシュが有効期限切れかどうかをチェック
  bool isCacheExpired() {
    if (_lastCacheUpdateTime == null) {
      return false;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - _lastCacheUpdateTime!) >
        CacheConfig.storeCacheMaxAgeMilliseconds;
  }
}
