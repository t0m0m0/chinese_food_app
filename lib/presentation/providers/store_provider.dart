import 'package:flutter/foundation.dart';
import '../../core/utils/error_message_helper.dart';
import '../../core/utils/duplicate_store_checker.dart';
import '../../core/utils/database_error_handler.dart';
import '../../domain/entities/store.dart';
import '../../domain/entities/location.dart';
import '../../domain/repositories/store_repository.dart';
import '../../domain/services/location_service.dart';

/// 店舗データの状態管理を行うProvider
///
/// 全ての店舗データのCRUD操作と状態管理を担当し、
/// Clean ArchitectureのPresentation層でドメイン層のRepositoryと連携する
class StoreProvider extends ChangeNotifier {
  final StoreRepository repository;
  final LocationService locationService;

  /// 全ての店舗データ
  List<Store> _stores = [];

  /// 検索結果専用のリスト（検索画面で使用）
  List<Store> _searchResults = [];

  /// スワイプ画面専用のリスト（現在地周辺の店舗のみ）
  List<Store> _swipeStores = [];

  /// ローディング状態
  bool _isLoading = false;

  /// エラーメッセージ
  String? _error;

  /// 情報メッセージ（検索結果0件など、異常ではない状況のメッセージ）
  String? _infoMessage;

  /// キャッシュされたステータス別店舗リスト（メモリ効率化）
  List<Store>? _cachedWantToGoStores;
  List<Store>? _cachedVisitedStores;
  List<Store>? _cachedBadStores;

  /// キャッシュの最大保持時間（ミリ秒）
  /// 設定から取得可能にするための実装（デフォルト30秒）
  static const int _defaultCacheMaxAge = 30000; // 30秒
  static int get _cacheMaxAge => _defaultCacheMaxAge; // 将来的に設定ファイルから取得可能
  int? _lastCacheUpdateTime;

  StoreProvider({required this.repository, required this.locationService});

  // Getters
  List<Store> get stores => List.unmodifiable(_stores);
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get infoMessage => _infoMessage;

  /// 「行きたい」ステータスの店舗リスト（キャッシュ機能付き）
  List<Store> get wantToGoStores {
    _checkCacheExpiry();
    _cachedWantToGoStores ??=
        _stores.where((store) => store.status == StoreStatus.wantToGo).toList();
    return List.unmodifiable(_cachedWantToGoStores!);
  }

  /// 「行った」ステータスの店舗リスト（キャッシュ機能付き）
  List<Store> get visitedStores {
    _checkCacheExpiry();
    _cachedVisitedStores ??=
        _stores.where((store) => store.status == StoreStatus.visited).toList();
    return List.unmodifiable(_cachedVisitedStores!);
  }

  /// 「興味なし」ステータスの店舗リスト（キャッシュ機能付き）
  List<Store> get badStores {
    _checkCacheExpiry();
    _cachedBadStores ??=
        _stores.where((store) => store.status == StoreStatus.bad).toList();
    return List.unmodifiable(_cachedBadStores!);
  }

  /// スワイプ用の新しい店舗（ステータス未設定）リスト
  List<Store> get newStores {
    return _stores.where((store) => store.status == null).toList();
  }

  /// 検索結果専用のリスト（検索画面で使用）
  List<Store> get searchResults => List.unmodifiable(_searchResults);

  /// スワイプ画面専用のリスト（現在地周辺の未設定ステータス店舗のみ）
  List<Store> get swipeStores {
    return _swipeStores.where((store) => store.status == null).toList();
  }

  /// リポジトリから全ての店舗データを取得
  ///
  /// まずローカルデータベースからデータを取得し、データが少ない場合は
  /// APIから新しいデータを自動取得する
  Future<void> loadStores() async {
    _setLoading(true);
    _clearError();

    try {
      // まずローカルデータベースから店舗データを取得
      _stores = await repository.getAllStores();

      // データが少ない場合（10件未満）はAPIから追加取得
      if (_stores.length < 10) {
        debugPrint('ローカルデータが少ないため、APIから店舗データを取得します（現在: ${_stores.length}件）');

        // デフォルトの検索条件でAPIから店舗データを取得
        await _loadStoresFromApiWithCurrentLocation();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('店舗データ読み込みエラー: $e');
      _setError(ErrorMessageHelper.getStoreRelatedMessage('load_stores'));
    } finally {
      _setLoading(false);
    }
  }

  /// 現在地優先でAPIから店舗データを取得（デフォルト位置フォールバック付き）
  Future<void> _loadStoresFromApiWithCurrentLocation() async {
    double lat = 35.6917; // デフォルト: 新宿駅の座標
    double lng = 139.7006;

    try {
      // まず現在地取得を試行
      final location = await locationService.getCurrentLocation();
      lat = location.latitude;
      lng = location.longitude;
      debugPrint('現在地を取得しました: ($lat, $lng)');
    } on LocationException catch (e) {
      debugPrint('現在地取得に失敗、デフォルト位置を使用: $e');
      // フォールバック: デフォルト位置（新宿駅）を使用
    } catch (e) {
      debugPrint('現在地取得でエラー、デフォルト位置を使用: $e');
      // フォールバック: デフォルト位置（新宿駅）を使用
    }

    try {
      // 取得した位置（現在地またはデフォルト）で中華料理店を検索
      await loadNewStoresFromApi(
        lat: lat,
        lng: lng,
        keyword: '中華',
        count: 20, // より多くのデータを取得
      );
      debugPrint('APIから${_stores.length}件の店舗データを取得しました');
    } catch (e) {
      debugPrint('API取得エラー: $e');
      // APIエラーは致命的ではないので、エラーメッセージは設定しない
    }
  }

  /// 店舗のステータスを更新
  ///
  /// データベースへの永続化を先に実行し、成功後にローカル状態を更新することで
  /// データの整合性を保証する
  ///
  /// [storeId] 更新対象の店舗ID
  /// [newStatus] 新しいステータス
  Future<void> updateStoreStatus(String storeId, StoreStatus newStatus) async {
    final storeIndex = _stores.indexWhere((store) => store.id == storeId);
    if (storeIndex == -1) {
      throw Exception('店舗が見つかりません: $storeId');
    }

    final originalStore = _stores[storeIndex];
    final updatedStore = originalStore.copyWith(status: newStatus);

    try {
      // データベースへの永続化を先に実行
      await repository.updateStore(updatedStore);

      // 成功後にローカル状態を更新
      _stores[storeIndex] = updatedStore;

      // スワイプリストからも同じ店舗を除去（ステータス設定済みのため）
      _swipeStores.removeWhere((store) => store.id == storeId);

      _clearCache(); // ステータス別キャッシュもクリア
      notifyListeners();
      _clearError();
    } catch (e) {
      // Issue #113 Phase 2: 型安全なエラーハンドリングに改善
      String errorMessage;

      if (e is Exception) {
        if (DatabaseErrorHandler.isDatabaseFileAccessError(e)) {
          errorMessage = 'データベースファイルにアクセスできません。アプリを再起動してください。';
        } else if (DatabaseErrorHandler.isFFIError(e)) {
          errorMessage = 'Web環境でのデータベース制限です。機能は制限付きで動作します。';
        } else if (DatabaseErrorHandler.isInitializationError(e)) {
          errorMessage = 'データベースが初期化されていません。しばらくお待ちください。';
        } else {
          errorMessage =
              ErrorMessageHelper.getStoreRelatedMessage('update_status');
        }
      } else {
        // Exception以外の場合（通常起こらない）
        errorMessage =
            ErrorMessageHelper.getStoreRelatedMessage('update_status');
      }

      _setError(errorMessage);
      // ローカル状態はデータベースと整合性を保つため、変更しない

      // デバッグ用の詳細ログ（エラーレベル付き）
      final severity =
          e is Exception ? DatabaseErrorHandler.getErrorSeverity(e) : 2;
      debugPrint('店舗ステータス更新エラー (severity: $severity): $e');
    }
  }

  /// 新しい店舗を追加
  ///
  /// [store] 追加する店舗データ
  Future<void> addStore(Store store) async {
    try {
      // データベースに永続化
      await repository.insertStore(store);

      // ローカル状態を更新
      _stores.add(store);
      notifyListeners();
      _clearError();
    } catch (e) {
      _setError(ErrorMessageHelper.getStoreRelatedMessage('add_store'));
    }
  }

  /// エラーと情報メッセージをクリア
  void clearError() {
    _clearError();
    _clearInfoMessage();
  }

  /// キャッシュをリフレッシュして最新状態を反映
  ///
  /// UIの更新が必要な場合に呼び出す専用メソッド
  /// 直接notifyListeners()を呼ぶよりも意図が明確
  void refreshCache() {
    _clearCache();
    notifyListeners();
  }

  /// スワイプ画面専用: 現在地周辺の店舗データを読み込み
  Future<void> loadSwipeStores({
    required double lat,
    required double lng,
    int range = 3,
    int count = 20,
  }) async {
    debugPrint(
        '[SWIPE] 店舗読み込み開始: lat=$lat, lng=$lng, range=$range, count=$count');
    _setLoading(true);
    _clearError();

    try {
      debugPrint('[SWIPE] API呼び出し中...');
      final apiStores = await repository.searchStoresFromApi(
        lat: lat,
        lng: lng,
        keyword: '中華',
        range: range,
        count: count,
      );
      debugPrint('[SWIPE] API応答受信: ${apiStores.length}件の店舗データ');

      // スワイプ画面用リストを構築（既存店舗のステータス考慮）
      // パフォーマンス最適化: HashMapによる高速検索
      final existingStoreMap = <String, Store>{
        for (final store in _stores) store.id: store
      };

      final filteredStores = <Store>[];
      for (final apiStore in apiStores) {
        final existingStore = existingStoreMap[apiStore.id];

        if (existingStore != null) {
          // 既存店舗が見つかった場合：そのステータスを確認
          if (existingStore.status == null) {
            // ステータス未設定の場合のみスワイプ対象に追加
            filteredStores.add(existingStore);
          }
          // ステータス設定済みの場合は除外
        } else {
          // 新規店舗の場合：_storesに追加してスワイプ対象にも追加
          final newStore = apiStore.copyWith(resetStatus: true);
          _stores.add(newStore);
          existingStoreMap[newStore.id] = newStore; // マップも更新
          filteredStores.add(newStore);
        }
      }

      _swipeStores = filteredStores;

      debugPrint('[SWIPE] 店舗リスト更新完了: ${_swipeStores.length}件');

      // 空の結果時のメッセージ
      if (_swipeStores.isEmpty) {
        debugPrint('[SWIPE] 対象店舗が見つかりませんでした');
        _setError('現在地周辺に新しい中華料理店が見つかりませんでした。範囲を広げてみてください。');
        return;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('[SWIPE] API呼び出しエラー: $e');
      _setError('現在地周辺の店舗取得に失敗しました');
    } finally {
      _setLoading(false);
      debugPrint('[SWIPE] loadSwipeStores() 完了');
    }
  }

  /// HotPepper APIから新しい店舗データを検索して追加
  Future<void> loadNewStoresFromApi({
    double? lat,
    double? lng,
    String? address,
    String? keyword = '中華',
    int range = 3,
    int count = 10,
  }) async {
    debugPrint(
        '[API] 呼び出し開始: lat=$lat, lng=$lng, keyword=$keyword, range=$range, count=$count');
    _setLoading(true);
    _clearError();
    _clearInfoMessage();

    try {
      debugPrint('[API] repository.searchStoresFromApi() 呼び出し中...');
      final apiStores = await repository.searchStoresFromApi(
        lat: lat,
        lng: lng,
        address: address,
        keyword: keyword,
        range: range,
        count: count,
      );
      debugPrint('$apiStores');
      debugPrint('[API] 応答受信: ${apiStores.length}件の店舗データ');

      // Issue #96: 統一化されたDuplicateStoreCheckerを使用
      // 既存店舗と新規店舗を比較して重複を除去
      final newStores = <Store>[];

      for (final apiStore in apiStores) {
        try {
          // 既存店舗との重複チェック（統一化されたロジック使用）
          final isDuplicate = _stores.any((existingStore) =>
              DuplicateStoreChecker.isDuplicate(existingStore, apiStore));

          if (!isDuplicate) {
            newStores.add(apiStore.copyWith(resetStatus: true));
          }
        } catch (e) {
          // 個別の店舗処理でエラーが発生した場合はスキップ
          debugPrint('Store processing error: $e');
        }
      }

      debugPrint('[API] 重複除去後: ${newStores.length}件の新店舗');

      // 新しい店舗をローカルデータベースにも保存
      for (final store in newStores) {
        try {
          await repository.insertStore(store);
        } catch (e) {
          debugPrint('店舗保存エラー (${store.name}): $e');
          // 個別のエラーは無視して続行
        }
      }

      // バッチ追加でパフォーマンス向上
      _stores.addAll(newStores);

      // 検索結果を専用リストに保存（検索画面で使用）
      _searchResults = List.from(newStores);

      debugPrint(
          '[API] 最終結果: 総店舗数=${_stores.length}件, 新規追加=${newStores.length}件, 検索結果=${_searchResults.length}件');

      // 空の結果時のユーザーフレンドリーなメッセージ
      if (apiStores.isEmpty) {
        debugPrint('[API] 応答が空でした');
        _setInfoMessage('近くに新しい中華料理店が見つかりませんでした。検索範囲を広げてみてください。');
        return;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('[API] 呼び出しエラー: $e');
      _setError('新しい店舗の取得に失敗しました');
    } finally {
      _setLoading(false);
      debugPrint('[API] loadNewStoresFromApi() 完了');
    }
  }

  @override
  void notifyListeners() {
    _clearCache();
    super.notifyListeners();
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  void _setInfoMessage(String infoMessage) {
    _infoMessage = infoMessage;
    notifyListeners();
  }

  void _clearInfoMessage() {
    if (_infoMessage != null) {
      _infoMessage = null;
      notifyListeners();
    }
  }

  /// データベースエラーからのリカバリーを試行
  /// Issue #111対応: データベース接続問題の自動復旧機能
  Future<bool> tryRecoverFromDatabaseError() async {
    try {
      _clearError();
      _isLoading = true;
      notifyListeners();

      // データベース接続の再確認
      await repository.getAllStores();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _setError('データベース復旧に失敗しました: ${e.toString()}');
      return false;
    }
  }

  /// キャッシュされたステータス別リストをクリア
  void _clearCache() {
    _cachedWantToGoStores = null;
    _cachedVisitedStores = null;
    _cachedBadStores = null;
    _lastCacheUpdateTime = DateTime.now().millisecondsSinceEpoch;
  }

  /// キャッシュの有効期限をチェックし、期限切れの場合はクリア
  void _checkCacheExpiry() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lastCacheUpdateTime != null &&
        (now - _lastCacheUpdateTime!) > _cacheMaxAge) {
      _clearCache();
    }
  }
}
