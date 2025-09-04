import 'package:flutter/foundation.dart';
import '../../domain/entities/store.dart';
import '../../domain/repositories/store_repository.dart';
import '../../domain/services/location_service.dart';
import 'store_state_manager.dart';
import 'store_cache_manager.dart';
import 'store_business_logic.dart';

class StoreProvider extends ChangeNotifier {
  final StoreStateManager _stateManager;
  final StoreCacheManager _cacheManager;
  final StoreBusinessLogic _businessLogic;

  StoreProvider({
    required StoreRepository repository,
    required LocationService locationService,
  })  : _stateManager = StoreStateManager(),
        _cacheManager = StoreCacheManager(),
        _businessLogic = StoreBusinessLogic(
          repository: repository,
          locationService: locationService,
        ) {
    _stateManager.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    notifyListeners();
  }

  // Delegated getters from StateManager
  bool get isLoading => _stateManager.isLoading;
  String? get error => _stateManager.error;
  String? get infoMessage => _stateManager.infoMessage;
  List<Store> get searchResults => _stateManager.searchResults;
  List<Store> get swipeStores => _stateManager.swipeStores;

  // Delegated getters from BusinessLogic
  List<Store> get stores => _businessLogic.allStores;

  // Delegated getters from CacheManager
  List<Store> get wantToGoStores =>
      _cacheManager.getWantToGoStores(_businessLogic.allStores);
  List<Store> get visitedStores =>
      _cacheManager.getVisitedStores(_businessLogic.allStores);
  List<Store> get badStores =>
      _cacheManager.getBadStores(_businessLogic.allStores);
  List<Store> get newStores =>
      _cacheManager.getNewStores(_businessLogic.allStores);

  // Business operations
  Future<void> loadStores() async {
    try {
      _stateManager.setLoading(true);
      _stateManager.clearError();

      await _businessLogic.loadStores();

      _stateManager.setLoading(false);
      // 店舗データ読み込み後、キャッシュクリアとUIに変更を通知
      _cacheManager.clearCache();
      notifyListeners();
    } catch (e) {
      _stateManager.setError('店舗データの読み込みに失敗しました');
      _stateManager.setLoading(false);
    }
  }

  Future<void> updateStoreStatus(String storeId, StoreStatus newStatus) async {
    try {
      _stateManager.clearError();
      await _businessLogic.updateStoreStatus(storeId, newStatus);
      _cacheManager.clearCache();

      // スワイプリストからステータス更新された店舗を除去
      final updatedSwipeStores = _stateManager.swipeStores
          .where((store) => store.id != storeId)
          .toList();
      _stateManager.updateSwipeStores(updatedSwipeStores);
    } catch (e) {
      _stateManager.setError('店舗ステータスの更新に失敗しました');
    }
  }

  Future<void> addStore(Store store) async {
    try {
      _stateManager.clearError();
      await _businessLogic.addStore(store);
      // 店舗追加後、キャッシュクリアとUIに変更を通知
      _cacheManager.clearCache();
      notifyListeners();
    } catch (e) {
      _stateManager.setError('店舗の追加に失敗しました');
    }
  }

  void clearError() {
    _stateManager.clearError();
  }

  void refreshCache() {
    _cacheManager.clearCache();
    notifyListeners();
  }

  // Missing methods from old StoreProvider for backward compatibility
  Future<void> loadNewStoresFromApi({
    double? lat,
    double? lng,
    String? address,
    String? keyword = '中華',
    int range = 3,
    int count = 10,
  }) async {
    try {
      _stateManager.setLoading(true);
      _stateManager.clearError();

      await _businessLogic.loadNewStoresFromApi(
        lat: lat,
        lng: lng,
        address: address,
        keyword: keyword,
        range: range,
        count: count,
      );

      _stateManager.setLoading(false);
      // 新規店舗取得後、キャッシュクリアとUIに変更を通知
      _cacheManager.clearCache();
      notifyListeners();
    } catch (e) {
      _stateManager.setError('新しい店舗の取得に失敗しました');
      _stateManager.setLoading(false);
    }
  }

  Future<void> loadSwipeStores({
    required double lat,
    required double lng,
    int range = 3,
    int count = 20,
  }) async {
    try {
      _stateManager.setLoading(true);
      _stateManager.clearError();

      final swipeStores = await _businessLogic.loadSwipeStores(
        lat: lat,
        lng: lng,
        range: range,
        count: count,
      );

      _stateManager.updateSwipeStores(swipeStores);
      _stateManager.setLoading(false);
    } catch (e) {
      _stateManager.setError('現在地周辺の店舗取得に失敗しました');
      _stateManager.setLoading(false);
    }
  }

  // Database error recovery functionality
  Future<bool> tryRecoverFromDatabaseError() async {
    try {
      _stateManager.clearError();
      _stateManager.setLoading(true);

      // データベース接続の再確認
      await _businessLogic.loadStores();

      _stateManager.setLoading(false);
      return true;
    } catch (e) {
      _stateManager.setLoading(false);
      _stateManager.setError('データベース復旧に失敗しました: ${e.toString()}');
      return false;
    }
  }

  // Temporary getter for backward compatibility
  StoreRepository get repository => throw UnimplementedError(
      'repository getter is deprecated. Direct repository access violates separation of concerns.');

  @override
  void dispose() {
    _stateManager.removeListener(_onStateChanged);
    _stateManager.dispose();
    super.dispose();
  }
}
