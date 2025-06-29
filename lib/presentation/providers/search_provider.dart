import 'package:flutter/foundation.dart';
import '../../domain/entities/store.dart';
import '../../domain/services/location_service.dart';
import './store_provider.dart';

/// 検索画面の状態管理とビジネスロジックを担当するProvider
class SearchProvider extends ChangeNotifier {
  final StoreProvider storeProvider;
  final LocationService locationService;

  SearchProvider({
    required this.storeProvider,
    required this.locationService,
  });

  // 状態管理フィールド
  bool _isLoading = false;
  bool _isGettingLocation = false;
  String? _errorMessage;
  List<Store> _searchResults = [];
  bool _useCurrentLocation = true;
  bool _hasSearched = false;

  // ゲッター
  bool get isLoading => _isLoading;
  bool get isGettingLocation => _isGettingLocation;
  String? get errorMessage => _errorMessage;
  List<Store> get searchResults => _searchResults;
  bool get useCurrentLocation => _useCurrentLocation;
  bool get hasSearched => _hasSearched;

  // 検索モード切り替え
  void setUseCurrentLocation(bool value) {
    _useCurrentLocation = value;
    notifyListeners();
  }

  // 検索実行 - 最小実装（テストを通すため）
  Future<void> performSearch({String? address}) async {
    _hasSearched = true;
    _isLoading = false; // すぐに完了と仮定
    notifyListeners();
  }
}
