import 'package:flutter/foundation.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/error_message_helper.dart';
import '../../domain/entities/store.dart';
import '../../domain/repositories/store_repository.dart';
import '../../domain/usecases/initialize_sample_stores_usecase.dart';

/// 店舗データの状態管理を行うProvider
///
/// 全ての店舗データのCRUD操作と状態管理を担当し、
/// Clean ArchitectureのPresentation層でドメイン層のRepositoryと連携する
class StoreProvider extends ChangeNotifier {
  final StoreRepository repository;

  /// 全ての店舗データ
  List<Store> _stores = [];

  /// ローディング状態
  bool _isLoading = false;

  /// エラーメッセージ
  String? _error;

  /// キャッシュされたステータス別店舗リスト（メモリ効率化）
  List<Store>? _cachedWantToGoStores;
  List<Store>? _cachedVisitedStores;
  List<Store>? _cachedBadStores;

  /// キャッシュの最大保持時間（ミリ秒）
  /// 設定から取得可能にするための実装（デフォルト30秒）
  static const int _defaultCacheMaxAge = 30000; // 30秒
  static int get _cacheMaxAge => _defaultCacheMaxAge; // 将来的に設定ファイルから取得可能
  int? _lastCacheUpdateTime;

  StoreProvider({required this.repository});

  // Getters
  List<Store> get stores => List.unmodifiable(_stores);
  bool get isLoading => _isLoading;
  String? get error => _error;

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

  /// リポジトリから全ての店舗データを取得
  ///
  /// 初回起動時にはサンプルデータを自動初期化する
  Future<void> loadStores() async {
    _setLoading(true);
    _clearError();

    try {
      // サンプルデータを初期化（既存データがない場合のみ）
      final initializeUsecase = InitializeSampleStoresUsecase(repository);
      await initializeUsecase.execute();

      // 店舗データを取得
      _stores = await repository.getAllStores();
      notifyListeners();
    } catch (e) {
      _setError(ErrorMessageHelper.getStoreRelatedMessage('load_stores'));
    } finally {
      _setLoading(false);
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
      notifyListeners();
      _clearError();
    } catch (e) {
      _setError(ErrorMessageHelper.getStoreRelatedMessage('update_status'));
      // ローカル状態はデータベースと整合性を保つため、変更しない
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

  /// エラーをクリア
  void clearError() {
    _clearError();
  }

  /// キャッシュをリフレッシュして最新状態を反映
  ///
  /// UIの更新が必要な場合に呼び出す専用メソッド
  /// 直接notifyListeners()を呼ぶよりも意図が明確
  void refreshCache() {
    _clearCache();
    notifyListeners();
  }

  /// HotPepper APIから新しい店舗データを検索して追加
  Future<void> loadNewStoresFromApi({
    double? lat,
    double? lng,
    String? address,
    String? keyword = '中華',
    int count = 10,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final apiStores = await repository.searchStoresFromApi(
        lat: lat,
        lng: lng,
        address: address,
        keyword: keyword,
        count: count,
      );

      // Issue #84: N+1クエリ問題を回避するため、重複チェックを効率化
      // QA改善: 正規化キーによる更なる最適化
      final existingStoreIndex = <String, List<Store>>{};
      for (final store in _stores) {
        final key = _generateNormalizedStoreKey(store.name, store.address);
        existingStoreIndex[key] ??= [];
        existingStoreIndex[key]!.add(store);
      }

      // APIストアごとに効率的な重複チェック（O(1)検索）
      final newStores = <Store>[];
      for (final apiStore in apiStores) {
        try {
          final key =
              _generateNormalizedStoreKey(apiStore.name, apiStore.address);
          final candidateStores = existingStoreIndex[key] ?? [];

          // 座標による精密な重複チェック（候補が限定されているため高速）
          final isDuplicate = candidateStores.any((store) =>
              (store.lat - apiStore.lat).abs() <
                  ApiConstants.duplicateThreshold &&
              (store.lng - apiStore.lng).abs() <
                  ApiConstants.duplicateThreshold);

          if (!isDuplicate) {
            newStores.add(apiStore.copyWith(resetStatus: true));
          }
        } catch (e) {
          // 個別の店舗処理でエラーが発生した場合はスキップ
          debugPrint('Store processing error: $e');
        }
      }

      // バッチ追加でパフォーマンス向上
      _stores.addAll(newStores);

      // 空の結果時のユーザーフレンドリーなメッセージ
      if (apiStores.isEmpty) {
        _setError('近くに新しい中華料理店が見つかりませんでした。検索範囲を広げてみてください。');
        return;
      }

      notifyListeners();
    } catch (e) {
      _setError('新しい店舗の取得に失敗しました');
    } finally {
      _setLoading(false);
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

  /// QA改善: 正規化されたストアキーを生成（高速ハッシュマップ検索用）
  ///
  /// 店舗名と住所を正規化し、一意性を保ちながら比較しやすい形式に変換
  String _generateNormalizedStoreKey(String name, String address) {
    // 全角・半角統一、空白・記号の正規化
    final normalizedName = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s\-　－]'), '') // 空白・ハイフンを除去
        .replaceAll(RegExp(r'[・･]'), ''); // 中点を除去

    final normalizedAddress = address
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s\-　－]'), '') // 空白・ハイフンを除去
        .replaceAll(RegExp(r'[丁目番地号]'), ''); // 住所表記を統一

    // ハッシュ効率を最適化するため、セパレータを最小化
    return '$normalizedName|$normalizedAddress';
  }
}
