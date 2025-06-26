import 'package:flutter/foundation.dart';
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

  StoreProvider({required this.repository});

  // Getters
  List<Store> get stores => List.unmodifiable(_stores);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 「行きたい」ステータスの店舗リスト
  List<Store> get wantToGoStores =>
      _stores.where((store) => store.status == StoreStatus.wantToGo).toList();

  /// 「行った」ステータスの店舗リスト
  List<Store> get visitedStores =>
      _stores.where((store) => store.status == StoreStatus.visited).toList();

  /// 「興味なし」ステータスの店舗リスト
  List<Store> get badStores =>
      _stores.where((store) => store.status == StoreStatus.bad).toList();

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
      _setError('店舗データの読み込みに失敗しました: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// 店舗のステータスを更新
  ///
  /// [storeId] 更新対象の店舗ID
  /// [newStatus] 新しいステータス
  Future<void> updateStoreStatus(String storeId, StoreStatus newStatus) async {
    try {
      // ローカル状態を更新
      final storeIndex = _stores.indexWhere((store) => store.id == storeId);
      if (storeIndex == -1) {
        throw Exception('店舗が見つかりません: $storeId');
      }

      final updatedStore = _stores[storeIndex].copyWith(status: newStatus);
      _stores[storeIndex] = updatedStore;
      notifyListeners();

      // データベースに永続化
      await repository.updateStore(updatedStore);
      _clearError();
    } catch (e) {
      _setError('店舗ステータスの更新に失敗しました: ${e.toString()}');
      // エラー時はローカル状態も元に戻す必要があるが、
      // 簡略化のため、次回loadStores()で正しい状態に復元される
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
      _setError('店舗の追加に失敗しました: ${e.toString()}');
    }
  }

  /// エラーをクリア
  void clearError() {
    _clearError();
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
}
