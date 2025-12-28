import 'package:flutter/foundation.dart';
import '../../domain/entities/store.dart';
import '../../domain/repositories/store_repository.dart';
import '../../core/constants/error_messages.dart';
import '../../core/constants/info_messages.dart';
import '../../core/constants/string_constants.dart';
import '../../core/constants/debug_constants.dart';
import 'store_state_manager.dart';
import 'store_cache_manager.dart';
import 'store_business_logic.dart';

class StoreProvider extends ChangeNotifier {
  final StoreStateManager _stateManager;
  final StoreCacheManager _cacheManager;
  final StoreBusinessLogic _businessLogic;

  StoreProvider({
    required StoreRepository repository,
  })  : _stateManager = StoreStateManager(),
        _cacheManager = StoreCacheManager(),
        _businessLogic = StoreBusinessLogic(
          repository: repository,
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
  List<Store> get wantToGoStores {
    return _cacheManager.getWantToGoStores(_businessLogic.allStores);
  }

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

      // キャッシュクリア戦略:
      // DBから店舗データを再読み込みした後は、フィルタリング済みのキャッシュを
      // クリアしてUIに最新データを反映する必要がある。
      // これにより、マイメニュー画面が常に最新のDB状態を表示できる。
      _cacheManager.clearCache();
      notifyListeners();
    } catch (e) {
      _stateManager
          .setError(ErrorMessages.getStoreMessage('store_load_failed'));
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

      // UIに変更を通知
      notifyListeners();
    } catch (e) {
      _stateManager.setError(
          ErrorMessages.getStoreMessage('store_status_update_failed'));
      notifyListeners();
    }
  }

  /// Saves a swiped store with status
  ///
  /// スワイプ画面専用。新規店舗の場合はinsert、既存店舗の場合はupdateを行う
  Future<void> saveSwipedStore(Store store, StoreStatus status) async {
    try {
      _stateManager.clearError();
      await _businessLogic.saveSwipedStore(store, status);
      _cacheManager.clearCache();

      // スワイプリストから削除
      final updatedSwipeStores =
          _stateManager.swipeStores.where((s) => s.id != store.id).toList();
      _stateManager.updateSwipeStores(updatedSwipeStores);

      // UIに変更を通知
      notifyListeners();
    } catch (e) {
      _stateManager.setError(
          ErrorMessages.getStoreMessage('store_status_update_failed'));
      notifyListeners();
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
      _stateManager.setError(ErrorMessages.getStoreMessage('store_add_failed'));
    }
  }

  /// 全店舗を削除（デバッグ用）
  Future<void> deleteAllStores() async {
    try {
      _stateManager.clearError();
      await _businessLogic.deleteAllStores();
      // 削除後、キャッシュクリアとUIに変更を通知
      _cacheManager.clearCache();
      notifyListeners();
    } catch (e) {
      _stateManager
          .setError(ErrorMessages.getStoreMessage('store_delete_failed'));
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
    String? keyword = StringConstants.defaultSearchKeyword,
    int range = 3,
    int count = 10,
    int start = 1,
  }) async {
    try {
      _stateManager.setLoading(true);
      _stateManager.clearError();

      final newStores = await _businessLogic.loadNewStoresFromApi(
        lat: lat,
        lng: lng,
        address: address,
        keyword: keyword,
        range: range,
        count: count,
        start: start,
      );

      _stateManager.updateSearchResults(newStores);
      _stateManager.setLoading(false);
      // 新規店舗取得後、キャッシュクリアとUIに変更を通知
      _cacheManager.clearCache();
      notifyListeners();
    } catch (e) {
      _stateManager
          .setError(ErrorMessages.getStoreMessage('new_stores_fetch_failed'));
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

      // スワイプ前にDBから最新の店舗リストを読み込む
      await _businessLogic.loadStores();

      final swipeStores = await _businessLogic.loadSwipeStores(
        lat: lat,
        lng: lng,
        range: range,
        count: count,
      );

      _stateManager.updateSwipeStores(swipeStores);

      // スワイプ用店舗が0件の場合、適切な情報メッセージを設定
      if (swipeStores.isEmpty) {
        _stateManager.setInfoMessage(
            InfoMessages.getStoreMessage('no_stores_found_nearby'));
      } else {
        _stateManager.clearInfoMessage();
      }

      // キャッシュクリア戦略:
      // 距離変更でAPI検索を実行した後、DBデータが変更されている可能性があるため
      // キャッシュをクリアする。これにより、マイメニュー画面が最新のDB状態を
      // 反映する（距離変更によって店舗が消えないようにするため重要）。
      _cacheManager.clearCache();
      notifyListeners();

      _stateManager.setLoading(false);
    } catch (e) {
      _stateManager
          .setError(ErrorMessages.getStoreMessage('location_stores_failed'));
      _stateManager.setLoading(false);
    }
  }

  /// スワイプ画面用の店舗取得（メートル単位の半径指定、広域検索対応）
  ///
  /// [radiusMeters] 検索半径（メートル）
  /// - 3000m以下: 通常の単一API検索
  /// - 3000m超: 広域検索（複数ポイントで並列検索）
  Future<void> loadSwipeStoresWithRadius({
    required double lat,
    required double lng,
    required int radiusMeters,
    int count = 100,
  }) async {
    try {
      _stateManager.setLoading(true);
      _stateManager.clearError();

      // スワイプ前にDBから最新の店舗リストを読み込む
      await _businessLogic.loadStores();

      final swipeStores = await _businessLogic.loadSwipeStoresWithRadius(
        lat: lat,
        lng: lng,
        radiusMeters: radiusMeters,
        count: count,
      );

      _stateManager.updateSwipeStores(swipeStores);

      // スワイプ用店舗が0件の場合、適切な情報メッセージを設定
      if (swipeStores.isEmpty) {
        _stateManager.setInfoMessage(
            InfoMessages.getStoreMessage('no_stores_found_nearby'));
      } else {
        _stateManager.clearInfoMessage();
      }

      _cacheManager.clearCache();
      notifyListeners();

      _stateManager.setLoading(false);
    } catch (e) {
      _stateManager
          .setError(ErrorMessages.getStoreMessage('location_stores_failed'));
      _stateManager.setLoading(false);
    }
  }

  /// スワイプ画面用の追加店舗取得（ページネーション）
  ///
  /// 次ページの店舗を取得し、既存のスワイプリストに追加する
  bool _isLoadingMore = false;

  Future<void> loadMoreSwipeStores({
    required double lat,
    required double lng,
    int range = 3,
    int count = 20,
    required int start,
  }) async {
    // 重複読み込み防止
    if (_isLoadingMore) {
      if (DebugConstants.enableStoreProviderLog) {
        debugPrint('[StoreProvider] 📄 追加読み込み中のため、スキップ');
      }
      return;
    }

    try {
      _isLoadingMore = true;
      if (DebugConstants.enableStoreProviderLog) {
        debugPrint('[StoreProvider] 📄 追加店舗取得開始');
      }

      // DB最新状態を確保（スワイプ済み店舗を正しく除外するため）
      await _businessLogic.loadStores();

      final moreStores = await _businessLogic.loadMoreSwipeStores(
        lat: lat,
        lng: lng,
        range: range,
        count: count,
        start: start,
      );

      if (moreStores.isNotEmpty) {
        // 既存のスワイプリストに追加
        final updatedSwipeStores = [
          ..._stateManager.swipeStores,
          ...moreStores
        ];
        _stateManager.updateSwipeStores(updatedSwipeStores);
        if (DebugConstants.enableStoreProviderLog) {
          debugPrint(
              '[StoreProvider] 📄 追加店舗${moreStores.length}件を取得 (合計: ${updatedSwipeStores.length}件)');
        }
        notifyListeners();
      } else {
        if (DebugConstants.enableStoreProviderLog) {
          debugPrint('[StoreProvider] 📄 次ページは空でした');
        }
      }
    } catch (e) {
      if (DebugConstants.enableStoreProviderLog) {
        debugPrint('[StoreProvider] ❌ 追加店舗取得エラー: $e');
      }
      // エラーは静かに処理（ユーザー体験を妨げない）
    } finally {
      _isLoadingMore = false;
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
      _stateManager.setError(ErrorMessages.withContext(
          ErrorMessages.getDatabaseMessage('database_recovery_failed'),
          e.toString()));
      return false;
    }
  }

  @override
  void dispose() {
    _stateManager.removeListener(_onStateChanged);
    _stateManager.dispose();
    super.dispose();
  }
}
