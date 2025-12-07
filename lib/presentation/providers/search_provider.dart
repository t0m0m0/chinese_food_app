import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import '../../core/constants/string_constants.dart';
import '../../core/config/search_config.dart';
import '../../domain/entities/store.dart';
import '../../domain/services/location_service.dart';
import './store_provider.dart';

/// 検索画面の状態管理とビジネスロジックを担当するProvider
class SearchProvider extends ChangeNotifier {
  /// 検索範囲の制限値（SearchConfigから取得）
  static const int _minSearchRange = 1;
  static const int _maxSearchRange = 5;
  static const int _defaultSearchRange = SearchConfig.defaultRange;

  /// 結果数の制限値（SearchConfigから取得）
  static const int _minResultCount = SearchConfig.minCount;
  static const int _maxResultCount = SearchConfig.maxCount;
  static const int _defaultResultCount = SearchConfig.defaultPageSize;

  final StoreProvider storeProvider;
  final LocationService locationService;

  SearchProvider({
    required this.storeProvider,
    required this.locationService,
  });

  // 状態管理フィールド
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isGettingLocation = false;
  String? _errorMessage;
  List<Store> _searchResults = [];
  bool _useCurrentLocation = true;
  bool _hasSearched = false;

  // ページネーション
  int _currentPage = 1;
  bool _hasMoreResults = true;
  static const int _pageSize = 20;

  // 最後の検索パラメータ（ページネーション用）
  double? _lastSearchLat;
  double? _lastSearchLng;
  String? _lastSearchAddress;

  // 検索フィルター設定
  int _searchRange = _defaultSearchRange;
  int _resultCount = _defaultResultCount;

  // ゲッター
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isGettingLocation => _isGettingLocation;
  String? get errorMessage => _errorMessage;
  List<Store> get searchResults => _searchResults;
  bool get useCurrentLocation => _useCurrentLocation;
  bool get hasSearched => _hasSearched;
  bool get hasMoreResults => _hasMoreResults;
  int get searchRange => _searchRange;
  int get resultCount => _resultCount;

  // 検索モード切り替え
  void setUseCurrentLocation(bool value) {
    _useCurrentLocation = value;
    notifyListeners();
  }

  // ページネーションをリセット
  void _resetPagination() {
    _currentPage = 1;
    _hasMoreResults = true;
    _searchResults.clear();
  }

  // 検索フィルター設定メソッド
  void setSearchRange(int range) {
    if (SearchConfig.isValidRange(range)) {
      _searchRange = range;
      notifyListeners();
    } else {
      // 無効な値の場合、ログに記録（将来的にユーザー通知を追加可能）
      if (kDebugMode) {
        developer.log(
          'Invalid search range value: $range. '
          'Valid range is $_minSearchRange to $_maxSearchRange.',
          name: 'SearchProvider',
          level: 900, // Warning level
        );
      }
    }
  }

  void setResultCount(int count) {
    if (SearchConfig.isValidCount(count)) {
      _resultCount = count;
      notifyListeners();
    } else {
      // 無効な値の場合、ログに記録（将来的にユーザー通知を追加可能）
      if (kDebugMode) {
        developer.log(
          'Invalid result count value: $count. '
          'Valid range is $_minResultCount to $_maxResultCount.',
          name: 'SearchProvider',
          level: 900, // Warning level
        );
      }
    }
  }

  // エラーメッセージのフォーマット
  String _formatErrorMessage(dynamic error) {
    final errorString = error.toString();

    if (errorString.contains('位置情報') ||
        errorString.contains('Location') ||
        errorString.contains('permission')) {
      return '位置情報の取得に失敗しました。設定を確認してください。';
    } else if (errorString.contains('ネットワーク') ||
        errorString.contains('network') ||
        errorString.contains('Network')) {
      return 'ネットワークエラーが発生しました。接続を確認してください。';
    } else if (errorString.contains('API') || errorString.contains('api')) {
      return 'サーバーエラーが発生しました。しばらく時間をおいて再度お試しください。';
    } else {
      return '予期しないエラーが発生しました。再度お試しください。';
    }
  }

  // 検索実行
  Future<void> performSearch({String? address}) async {
    _isLoading = true;
    _errorMessage = null;
    _resetPagination();
    _hasSearched = true;
    notifyListeners();

    try {
      if (address != null && address.isNotEmpty) {
        _lastSearchAddress = address;
        _lastSearchLat = null;
        _lastSearchLng = null;

        // 住所での検索（ページサイズ使用）
        await storeProvider.loadNewStoresFromApi(
          address: address,
          keyword: StringConstants.defaultSearchKeyword,
          range: _searchRange,
          count: _pageSize,
          start: 1,
        );
        _searchResults = List<Store>.from(storeProvider.searchResults);
        _currentPage = 1;
        _hasMoreResults = _searchResults.length >= _pageSize;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = _formatErrorMessage(e);
      notifyListeners();
    }
  }

  // 現在地検索実行
  Future<void> performSearchWithCurrentLocation() async {
    _isLoading = true;
    _isGettingLocation = true;
    _errorMessage = null;
    _resetPagination();
    _hasSearched = true;
    notifyListeners();

    try {
      // 現在位置を取得
      final location = await locationService.getCurrentLocation();

      _isGettingLocation = false;
      notifyListeners();

      _lastSearchLat = location.latitude;
      _lastSearchLng = location.longitude;
      _lastSearchAddress = null;

      // 位置情報を使ってAPI検索（ページサイズ使用）
      await storeProvider.loadNewStoresFromApi(
        lat: location.latitude,
        lng: location.longitude,
        keyword: StringConstants.defaultSearchKeyword,
        range: _searchRange,
        count: _pageSize,
        start: 1,
      );
      _searchResults = List<Store>.from(storeProvider.searchResults);
      _currentPage = 1;
      _hasMoreResults = _searchResults.length >= _pageSize;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isGettingLocation = false;
      _isLoading = false;
      _errorMessage = _formatErrorMessage(e);
      notifyListeners();
    }
  }

  // 次のページを読み込む
  Future<void> loadMoreResults() async {
    if (_isLoadingMore || !_hasMoreResults) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final start = (nextPage - 1) * _pageSize + 1;

      if (_lastSearchAddress != null) {
        // 住所検索の続き
        await storeProvider.loadNewStoresFromApi(
          address: _lastSearchAddress!,
          keyword: StringConstants.defaultSearchKeyword,
          range: _searchRange,
          count: _pageSize,
          start: start,
        );
      } else if (_lastSearchLat != null && _lastSearchLng != null) {
        // 現在地検索の続き
        await storeProvider.loadNewStoresFromApi(
          lat: _lastSearchLat!,
          lng: _lastSearchLng!,
          keyword: StringConstants.defaultSearchKeyword,
          range: _searchRange,
          count: _pageSize,
          start: start,
        );
      }

      final newResults = storeProvider.searchResults;
      if (newResults.isNotEmpty) {
        _searchResults.addAll(newResults);
        _currentPage = nextPage;
        _hasMoreResults = newResults.length >= _pageSize;
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
}
