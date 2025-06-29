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

  // 検索実行
  Future<void> performSearch({String? address}) async {
    _isLoading = true;
    _errorMessage = null;
    _searchResults.clear();
    _hasSearched = true;
    notifyListeners();

    try {
      if (address != null && address.isNotEmpty) {
        // 住所での検索
        await storeProvider.loadNewStoresFromApi(
          address: address,
          keyword: '中華',
        );
        _searchResults = List.from(storeProvider.newStores);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // 現在地検索実行
  Future<void> performSearchWithCurrentLocation() async {
    _isLoading = true;
    _isGettingLocation = true;
    _errorMessage = null;
    _searchResults.clear();
    _hasSearched = true;
    notifyListeners();

    try {
      // 現在位置を取得
      final location = await locationService.getCurrentLocation();
      
      _isGettingLocation = false;
      notifyListeners();

      // 位置情報を使ってAPI検索
      await storeProvider.loadNewStoresFromApi(
        lat: location.latitude,
        lng: location.longitude,
        keyword: '中華',
      );
      _searchResults = List.from(storeProvider.newStores);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isGettingLocation = false;
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
