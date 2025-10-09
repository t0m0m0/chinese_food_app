import '../../domain/entities/store.dart';
import '../../domain/repositories/store_repository.dart';
import '../../domain/services/location_service.dart';
import '../../core/constants/string_constants.dart';

class StoreBusinessLogic {
  final StoreRepository _repository;
  // TODO: Issue #155 - 位置情報機能の完全実装で使用予定（loadStoresWithCurrentLocation等）
  // ignore: unused_field
  final LocationService _locationService;
  List<Store> _stores = [];

  StoreBusinessLogic({
    required StoreRepository repository,
    required LocationService locationService,
  })  : _repository = repository,
        _locationService = locationService;

  List<Store> get allStores => List.unmodifiable(_stores);

  Future<List<Store>> loadStores() async {
    _stores = await _repository.getAllStores();
    return List.unmodifiable(_stores);
  }

  /// Updates store status and saves to DB
  ///
  /// スワイプ画面から呼ばれた場合:
  /// - 新規店舗（DB未保存）→ insertStore()
  /// - 既存店舗 → updateStore()
  Future<void> updateStoreStatus(String storeId, StoreStatus newStatus) async {
    final storeIndex = _stores.indexWhere((store) => store.id == storeId);

    if (storeIndex == -1) {
      throw Exception('店舗が見つかりません: $storeId');
    }

    final originalStore = _stores[storeIndex];
    final updatedStore = originalStore.copyWith(status: newStatus);

    await _repository.updateStore(updatedStore);
    _stores[storeIndex] = updatedStore;
  }

  /// Saves a swiped store to DB with status
  ///
  /// スワイプ時に呼ばれる。新規店舗の場合はinsert、既存店舗の場合はupdateを行う
  Future<void> saveSwipedStore(Store store, StoreStatus status) async {
    final storeWithStatus = store.copyWith(status: status);

    // DBに既に存在するかチェック
    final existingStore = await _repository.getStoreById(store.id);

    if (existingStore == null) {
      // 新規店舗 → insert
      await _repository.insertStore(storeWithStatus);
      _stores.add(storeWithStatus);
    } else {
      // 既存店舗 → update
      await _repository.updateStore(storeWithStatus);
      final index = _stores.indexWhere((s) => s.id == store.id);
      if (index != -1) {
        _stores[index] = storeWithStatus;
      }
    }
  }

  Future<void> addStore(Store store) async {
    await _repository.insertStore(store);
    _stores.add(store);
  }

  /// API から新しい店舗を検索して取得
  ///
  /// 検索結果は重複チェックせず、そのまま返す
  /// （検索画面では同じ店舗でも毎回表示すべき）
  /// データベースへの保存も行わない（検索は表示のみ）
  Future<List<Store>> loadNewStoresFromApi({
    double? lat,
    double? lng,
    String? address,
    String? keyword = StringConstants.defaultSearchKeyword,
    int range = 3,
    int count = 10,
  }) async {
    final apiStores = await _repository.searchStoresFromApi(
      lat: lat,
      lng: lng,
      address: address,
      keyword: keyword,
      range: range,
      count: count,
    );

    // 検索結果はそのまま返す（重複チェック不要、DB保存も不要）
    return apiStores;
  }

  /// スワイプ画面用の店舗取得（ステータス未設定の店舗のみ）
  ///
  /// DB保存は行わず、スワイプ可能な店舗リストのみを返す
  /// 実際のDB保存はスワイプ時に行われる
  Future<List<Store>> loadSwipeStores({
    required double lat,
    required double lng,
    int range = 3,
    int count = 20,
  }) async {
    final apiStores = await _fetchStoresFromApi(lat, lng, range, count);
    final existingStoreMaps = _buildExistingStoreMaps();
    return _filterSwipeStores(apiStores, existingStoreMaps);
  }

  /// Fetches stores from API with specified parameters
  Future<List<Store>> _fetchStoresFromApi(
    double lat,
    double lng,
    int range,
    int count,
  ) async {
    return await _repository.searchStoresFromApi(
      lat: lat,
      lng: lng,
      keyword: StringConstants.apiKeywordParameter,
      range: range,
      count: count,
    );
  }

  /// Builds maps of existing stores by ID and location for efficient lookup
  ({Map<String, StoreStatus?> byId, Map<String, StoreStatus?> byLocation})
      _buildExistingStoreMaps() {
    final existingStoreMap = <String, StoreStatus?>{};
    final existingLocations = <String, StoreStatus?>{};

    for (final store in _stores) {
      existingStoreMap[store.id] = store.status;
      final locationKey = _createLocationKey(store.lat, store.lng);
      existingLocations[locationKey] = store.status;
    }

    return (byId: existingStoreMap, byLocation: existingLocations);
  }

  /// Filters API stores for swipe functionality (no DB operations)
  ///
  /// スワイプ用の店舗リストをフィルタリング（DB保存なし）
  /// - 既存店舗でステータスがnullのもの → 含める
  /// - 新規店舗 → 含める（DB保存はスワイプ時）
  /// - 既存店舗でステータスありのもの → 除外
  List<Store> _filterSwipeStores(
    List<Store> apiStores,
    ({
      Map<String, StoreStatus?> byId,
      Map<String, StoreStatus?> byLocation
    }) existingStoreMaps,
  ) {
    final swipeStores = <Store>[];

    for (final apiStore in apiStores) {
      final shouldInclude =
          _shouldIncludeInSwipeList(apiStore, existingStoreMaps);
      if (shouldInclude) {
        swipeStores.add(apiStore);
      }
    }

    return swipeStores;
  }

  /// Determines if a store should be included in swipe list
  bool _shouldIncludeInSwipeList(
    Store apiStore,
    ({
      Map<String, StoreStatus?> byId,
      Map<String, StoreStatus?> byLocation
    }) existingStoreMaps,
  ) {
    final locationKey = _createLocationKey(apiStore.lat, apiStore.lng);
    final existingStatusById = existingStoreMaps.byId[apiStore.id];
    final existingStatusByLocation = existingStoreMaps.byLocation[locationKey];

    // 既存店舗の場合、ステータスがnullならスワイプ可能
    if (existingStatusById != null) {
      return false; // ステータスあり → スワイプ済み → 除外
    }
    if (existingStatusByLocation != null) {
      return false; // ステータスあり → スワイプ済み → 除外
    }

    // 新規店舗、または既存でステータスnullの場合 → スワイプ可能
    return true;
  }

  /// Creates a consistent location key for store coordinates
  String _createLocationKey(double lat, double lng) {
    return '${lat}_$lng';
  }
}
