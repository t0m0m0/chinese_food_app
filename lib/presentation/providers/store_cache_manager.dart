import '../../domain/entities/store.dart';
import '../../core/config/cache_config.dart';

class StoreCacheManager {
  List<Store>? _cachedWantToGoStores;
  List<Store>? _cachedVisitedStores;
  List<Store>? _cachedBadStores;
  int? _lastCacheUpdateTime;

  List<Store> getWantToGoStores(List<Store> allStores) {
    _checkCacheExpiry();
    _cachedWantToGoStores ??= List.unmodifiable(allStores
        .where((store) => store.status == StoreStatus.wantToGo)
        .toList());
    return _cachedWantToGoStores!;
  }

  List<Store> getVisitedStores(List<Store> allStores) {
    _checkCacheExpiry();
    _cachedVisitedStores ??= List.unmodifiable(allStores
        .where((store) => store.status == StoreStatus.visited)
        .toList());
    return _cachedVisitedStores!;
  }

  List<Store> getBadStores(List<Store> allStores) {
    _checkCacheExpiry();
    _cachedBadStores ??= List.unmodifiable(
        allStores.where((store) => store.status == StoreStatus.bad).toList());
    return _cachedBadStores!;
  }

  List<Store> getNewStores(List<Store> allStores) {
    return allStores.where((store) => store.status == null).toList();
  }

  void _checkCacheExpiry() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lastCacheUpdateTime != null &&
        (now - _lastCacheUpdateTime!) >
            CacheConfig.storeCacheMaxAgeMilliseconds) {
      clearCache();
    }
  }

  void clearCache() {
    _cachedWantToGoStores = null;
    _cachedVisitedStores = null;
    _cachedBadStores = null;
    _lastCacheUpdateTime = DateTime.now().millisecondsSinceEpoch;
  }

  bool isCacheExpired() {
    if (_lastCacheUpdateTime == null) {
      return false;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - _lastCacheUpdateTime!) >
        CacheConfig.storeCacheMaxAgeMilliseconds;
  }
}
