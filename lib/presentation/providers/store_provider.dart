import 'package:flutter/foundation.dart';
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

  /// キャッシュされたステータス別店舗リスト
  List<Store>? _cachedWantToGoStores;
  List<Store>? _cachedVisitedStores;
  List<Store>? _cachedBadStores;

  StoreProvider({required this.repository});

  // Getters
  List<Store> get stores => List.unmodifiable(_stores);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 「行きたい」ステータスの店舗リスト（キャッシュ機能付き）
  List<Store> get wantToGoStores {
    _cachedWantToGoStores ??=
        _stores.where((store) => store.status == StoreStatus.wantToGo).toList();
    return List.unmodifiable(_cachedWantToGoStores!);
  }

  /// 「行った」ステータスの店舗リスト（キャッシュ機能付き）
  List<Store> get visitedStores {
    _cachedVisitedStores ??=
        _stores.where((store) => store.status == StoreStatus.visited).toList();
    return List.unmodifiable(_cachedVisitedStores!);
  }

  /// 「興味なし」ステータスの店舗リスト（キャッシュ機能付き）
  List<Store> get badStores {
    _cachedBadStores ??=
        _stores.where((store) => store.status == StoreStatus.bad).toList();
    return List.unmodifiable(_cachedBadStores!);
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
  }
}
