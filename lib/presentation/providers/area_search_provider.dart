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
  String? _errorMessage;
  List<Store> _searchResults = [];
  bool _hasSearched = false;

  // 検索フィルター
  int _searchRange = SearchConfig.defaultRange;
  int _resultCount = SearchConfig.defaultPageSize;

  // Getters
  Prefecture? get selectedPrefecture => _selectedPrefecture;
  City? get selectedCity => _selectedCity;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Store> get searchResults => _searchResults;
  bool get hasSearched => _hasSearched;
  int get searchRange => _searchRange;
  int get resultCount => _resultCount;

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
    notifyListeners();
    // 都道府県選択時に自動検索
    performSearch();
  }

  /// 市区町村を選択
  void selectCity(City city) {
    _selectedCity = city;
    notifyListeners();
    // 市区町村選択時に自動検索
    performSearch();
  }

  /// 市区町村をクリア
  void clearCity() {
    _selectedCity = null;
    notifyListeners();
    // 市区町村クリア時に都道府県で再検索
    performSearch();
  }

  /// 検索範囲を設定
  void setSearchRange(int range) {
    if (SearchConfig.isValidRange(range)) {
      _searchRange = range;
      notifyListeners();
    }
  }

  /// 検索結果数を設定
  void setResultCount(int count) {
    if (SearchConfig.isValidCount(count)) {
      _resultCount = count;
      notifyListeners();
    }
  }

  /// エリア検索を実行
  Future<void> performSearch() async {
    if (!canSearch) return;

    _isLoading = true;
    _errorMessage = null;
    _searchResults.clear();
    _hasSearched = true;
    notifyListeners();

    try {
      final address = currentSelection!.toSearchAddress();

      await storeProvider.loadNewStoresFromApi(
        address: address,
        keyword: StringConstants.defaultSearchKeyword,
        range: _searchRange,
        count: _resultCount,
      );

      _searchResults = List<Store>.from(storeProvider.searchResults);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
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
