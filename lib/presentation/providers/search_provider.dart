import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import '../../core/constants/string_constants.dart';
import '../../domain/entities/store.dart';
import '../../domain/services/location_service.dart';
import './store_provider.dart';

/// 検索画面の状態管理とビジネスロジックを担当するProvider
class SearchProvider extends ChangeNotifier {
  /// 検索範囲の制限値
  static const int _minSearchRange = 1;
  static const int _maxSearchRange = 5;
  static const int _defaultSearchRange = 3;

  /// 結果数の制限値
  static const int _minResultCount = 1;
  static const int _maxResultCount = 100;
  static const int _defaultResultCount = 10;

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

  // 検索フィルター設定
  int _searchRange = _defaultSearchRange;
  int _resultCount = _defaultResultCount;

  // ゲッター
  bool get isLoading => _isLoading;
  bool get isGettingLocation => _isGettingLocation;
  String? get errorMessage => _errorMessage;
  List<Store> get searchResults => _searchResults;
  bool get useCurrentLocation => _useCurrentLocation;
  bool get hasSearched => _hasSearched;
  int get searchRange => _searchRange;
  int get resultCount => _resultCount;

  // 検索モード切り替え
  void setUseCurrentLocation(bool value) {
    _useCurrentLocation = value;
    notifyListeners();
  }

  // 検索フィルター設定メソッド
  void setSearchRange(int range) {
    if (range >= _minSearchRange && range <= _maxSearchRange) {
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
    if (count >= _minResultCount && count <= _maxResultCount) {
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
    _searchResults.clear();
    _hasSearched = true;
    notifyListeners();

    try {
      if (address != null && address.isNotEmpty) {
        // 住所での検索（フィルター設定適用）
        await storeProvider.loadNewStoresFromApi(
          address: address,
          keyword: StringConstants.defaultSearchKeyword,
          range: _searchRange,
          count: _resultCount,
        );
        _searchResults = List<Store>.from(storeProvider.searchResults);
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
    _searchResults.clear();
    _hasSearched = true;
    notifyListeners();

    try {
      // 現在位置を取得
      final location = await locationService.getCurrentLocation();

      _isGettingLocation = false;
      notifyListeners();

      // 位置情報を使ってAPI検索（フィルター設定適用）
      await storeProvider.loadNewStoresFromApi(
        lat: location.latitude,
        lng: location.longitude,
        keyword: StringConstants.defaultSearchKeyword,
        range: _searchRange,
        count: _resultCount,
      );
      _searchResults = List<Store>.from(storeProvider.searchResults);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isGettingLocation = false;
      _isLoading = false;
      _errorMessage = _formatErrorMessage(e);
      notifyListeners();
    }
  }
}
