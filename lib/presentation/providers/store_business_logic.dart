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

  Future<void> addStore(Store store) async {
    await _repository.insertStore(store);
    _stores.add(store);
  }

  /// API から新しい店舗を検索して取得
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

    // 重複チェック：既存店舗と同じIDまたは同じ位置の店舗は除外
    final existingIds = _stores.map((store) => store.id).toSet();
    final existingLocations =
        _stores.map((store) => '${store.lat}_${store.lng}').toSet();
    final newStores = apiStores.where((store) {
      final locationKey = '${store.lat}_${store.lng}';
      return !existingIds.contains(store.id) &&
          !existingLocations.contains(locationKey);
    }).toList();

    // 新しい店舗をローカルに追加
    for (final store in newStores) {
      await _repository.insertStore(store);
      _stores.add(store);
    }

    return newStores;
  }

  /// スワイプ画面用の店舗取得（ステータス未設定の店舗のみ）
  Future<List<Store>> loadSwipeStores({
    required double lat,
    required double lng,
    int range = 3,
    int count = 20,
  }) async {
    final apiStores = await _fetchStoresFromApi(lat, lng, range, count);
    final existingStoreMaps = _buildExistingStoreMaps();
    return await _filterAndProcessSwipeStores(apiStores, existingStoreMaps);
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

  /// Filters API stores and processes them for swipe functionality
  Future<List<Store>> _filterAndProcessSwipeStores(
    List<Store> apiStores,
    ({
      Map<String, StoreStatus?> byId,
      Map<String, StoreStatus?> byLocation
    }) existingStoreMaps,
  ) async {
    final swipeStores = <Store>[];

    for (final apiStore in apiStores) {
      final processedStore =
          await _processApiStore(apiStore, existingStoreMaps);
      if (processedStore != null) {
        swipeStores.add(processedStore);
      }
    }

    return swipeStores;
  }

  /// Processes a single API store based on existence and status
  Future<Store?> _processApiStore(
    Store apiStore,
    ({
      Map<String, StoreStatus?> byId,
      Map<String, StoreStatus?> byLocation
    }) existingStoreMaps,
  ) async {
    final locationKey = _createLocationKey(apiStore.lat, apiStore.lng);
    final isExistingById = existingStoreMaps.byId.containsKey(apiStore.id);
    final isExistingByLocation =
        existingStoreMaps.byLocation.containsKey(locationKey);

    if (!isExistingById && !isExistingByLocation) {
      return await _addNewStore(apiStore);
    } else if (isExistingById) {
      return _getExistingStoreById(apiStore.id, existingStoreMaps.byId);
    } else if (isExistingByLocation) {
      return _getExistingStoreByLocation(
          apiStore, existingStoreMaps.byLocation);
    }

    return null; // Store has status (already swiped), exclude from swipe list
  }

  /// Adds a completely new store to local storage and returns it
  Future<Store> _addNewStore(Store apiStore) async {
    await _repository.insertStore(apiStore);
    _stores.add(apiStore);
    return apiStore;
  }

  /// Returns existing store by ID if it has no status (not yet swiped)
  Store? _getExistingStoreById(
      String storeId, Map<String, StoreStatus?> existingStoreMap) {
    final existingStatus = existingStoreMap[storeId];
    if (existingStatus == null) {
      return _stores.firstWhere((store) => store.id == storeId);
    }
    return null;
  }

  /// Returns existing store by location if it has no status (not yet swiped)
  Store? _getExistingStoreByLocation(
    Store apiStore,
    Map<String, StoreStatus?> existingLocations,
  ) {
    final locationKey = _createLocationKey(apiStore.lat, apiStore.lng);
    final existingStatus = existingLocations[locationKey];
    if (existingStatus == null) {
      return _stores.firstWhere(
          (store) => store.lat == apiStore.lat && store.lng == apiStore.lng);
    }
    return null;
  }

  /// Creates a consistent location key for store coordinates
  String _createLocationKey(double lat, double lng) {
    return '${lat}_$lng';
  }
}
