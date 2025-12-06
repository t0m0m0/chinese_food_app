import 'package:flutter/foundation.dart';
import '../../core/constants/area_data.dart';
import '../../core/constants/string_constants.dart';
import '../../core/config/search_config.dart';
import '../../domain/entities/area.dart';
import '../../domain/entities/store.dart';
import './store_provider.dart';

/// エリア探索機能の状態管理を担当するProvider
///
/// 都道府県・市区町村の階層選択によるエリア指定検索を提供
class AreaSearchProvider extends ChangeNotifier {
  final StoreProvider storeProvider;

  AreaSearchProvider({required this.storeProvider});

  // 選択状態
  Prefecture? _selectedPrefecture;
  City? _selectedCity;

  // 検索状態
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  List<Store> _searchResults = [];
  bool _hasSearched = false;

  // ページネーション
  int _currentPage = 1;
  bool _hasMoreResults = true;
  static const int _pageSize = 20;
  static const int _maxResults = 100;

  // 検索フィルター
  int _searchRange = SearchConfig.defaultRange;

  // Getters
  Prefecture? get selectedPrefecture => _selectedPrefecture;
  City? get selectedCity => _selectedCity;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  List<Store> get searchResults => _searchResults;
  bool get hasSearched => _hasSearched;
  bool get hasMoreResults => _hasMoreResults;
  int get searchRange => _searchRange;

  /// 全都道府県リスト
  List<Prefecture> get prefectures => AreaData.prefectures;

  /// 地域別都道府県マップ
  Map<String, List<Prefecture>> get prefecturesByRegion =>
      AreaData.prefecturesByRegion;

  /// 選択中の都道府県に対応する市区町村リスト
  List<City> get availableCities {
    if (_selectedPrefecture == null) return [];
    return AreaData.getCitiesForPrefecture(_selectedPrefecture!.code);
  }

  /// 現在の選択状態
  AreaSelection? get currentSelection {
    if (_selectedPrefecture == null) return null;
    return AreaSelection(
      prefecture: _selectedPrefecture!,
      city: _selectedCity,
    );
  }

  /// 検索可能かどうか
  bool get canSearch => _selectedPrefecture != null;

  /// 都道府県を選択
  void selectPrefecture(Prefecture prefecture) {
    _selectedPrefecture = prefecture;
    _selectedCity = null; // 都道府県が変わったら市区町村をクリア
    _resetPagination();
    notifyListeners();
    // 都道府県選択時に自動検索
    performSearch();
  }

  /// 市区町村を選択
  void selectCity(City city) {
    _selectedCity = city;
    _resetPagination();
    notifyListeners();
    // 市区町村選択時に自動検索
    performSearch();
  }

  /// 市区町村をクリア
  void clearCity() {
    _selectedCity = null;
    _resetPagination();
    notifyListeners();
    // 市区町村クリア時に都道府県で再検索
    performSearch();
  }

  /// ページネーションをリセット
  void _resetPagination() {
    _currentPage = 1;
    _hasMoreResults = true;
    _searchResults.clear();
  }

  /// 検索範囲を設定
  void setSearchRange(int range) {
    if (SearchConfig.isValidRange(range)) {
      _searchRange = range;
      notifyListeners();
    }
  }

  /// エリア検索を実行（初回）
  Future<void> performSearch() async {
    if (!canSearch) return;

    _isLoading = true;
    _errorMessage = null;
    _hasSearched = true;
    notifyListeners();

    try {
      final address = currentSelection!.toSearchAddress();

      await storeProvider.loadNewStoresFromApi(
        address: address,
        keyword: StringConstants.defaultSearchKeyword,
        range: _searchRange,
        count: _pageSize,
        start: 1,
      );

      _searchResults = List<Store>.from(storeProvider.searchResults);
      _currentPage = 1;
      _hasMoreResults = _searchResults.length >= _pageSize &&
          _searchResults.length < _maxResults;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = _formatErrorMessage(e);
      notifyListeners();
    }
  }

  /// 次のページを読み込む
  Future<void> loadMoreResults() async {
    if (!canSearch ||
        _isLoadingMore ||
        !_hasMoreResults ||
        _searchResults.length >= _maxResults) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      final address = currentSelection!.toSearchAddress();
      final nextPage = _currentPage + 1;
      final start = (nextPage - 1) * _pageSize + 1;

      await storeProvider.loadNewStoresFromApi(
        address: address,
        keyword: StringConstants.defaultSearchKeyword,
        range: _searchRange,
        count: _pageSize,
        start: start,
      );

      final newResults = storeProvider.searchResults;
      if (newResults.isNotEmpty) {
        _searchResults.addAll(newResults);
        _currentPage = nextPage;
        _hasMoreResults = newResults.length >= _pageSize &&
            _searchResults.length < _maxResults;
      } else {
        _hasMoreResults = false;
      }

      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _isLoadingMore = false;
      _errorMessage = _formatErrorMessage(e);
      notifyListeners();
    }
  }

  /// エラーメッセージをフォーマット
  String _formatErrorMessage(dynamic error) {
    final errorString = error.toString();

    if (errorString.contains('ネットワーク') ||
        errorString.contains('network') ||
        errorString.contains('Network')) {
      return 'ネットワークエラーが発生しました。接続を確認してください。';
    } else if (errorString.contains('API') || errorString.contains('api')) {
      return 'サーバーエラーが発生しました。しばらく時間をおいて再度お試しください。';
    } else {
      return '予期しないエラーが発生しました。再度お試しください。';
    }
  }
}
