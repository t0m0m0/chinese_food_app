import '../../domain/entities/store.dart';
import '../../domain/repositories/store_repository.dart';
import '../../domain/services/location_service.dart';

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
    String? keyword = '中華',
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
    final existingLocations = _stores.map((store) => '${store.lat}_${store.lng}').toSet();
    final newStores = apiStores.where((store) {
      final locationKey = '${store.lat}_${store.lng}';
      return !existingIds.contains(store.id) && !existingLocations.contains(locationKey);
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
    // APIから店舗を検索
    final apiStores = await _repository.searchStoresFromApi(
      lat: lat,
      lng: lng,
      keyword: '中華',
      range: range,
      count: count,
    );

    // 既存店舗のIDとステータス、位置を取得
    final existingStoreMap = <String, StoreStatus?>{};
    final existingLocations = <String, StoreStatus?>{};
    for (final store in _stores) {
      existingStoreMap[store.id] = store.status;
      final locationKey = '${store.lat}_${store.lng}';
      existingLocations[locationKey] = store.status;
    }

    // 重複チェックと未スワイプフィルタリング
    final swipeStores = <Store>[];
    for (final apiStore in apiStores) {
      final locationKey = '${apiStore.lat}_${apiStore.lng}';
      final isExistingById = existingStoreMap.containsKey(apiStore.id);
      final isExistingByLocation = existingLocations.containsKey(locationKey);
      
      if (!isExistingById && !isExistingByLocation) {
        // 完全に新しい店舗：ローカルに追加してスワイプリストに含める
        await _repository.insertStore(apiStore);
        _stores.add(apiStore);
        swipeStores.add(apiStore);
      } else if (isExistingById) {
        // IDで既存店舗：ステータス未設定の場合のみスワイプリストに含める
        final existingStatus = existingStoreMap[apiStore.id];
        if (existingStatus == null) {
          final existingStore = _stores.firstWhere((store) => store.id == apiStore.id);
          swipeStores.add(existingStore);
        }
      } else if (isExistingByLocation) {
        // 位置で既存店舗：ステータス未設定の場合のみスワイプリストに含める
        final existingStatus = existingLocations[locationKey];
        if (existingStatus == null) {
          final existingStore = _stores.firstWhere((store) => 
            store.lat == apiStore.lat && store.lng == apiStore.lng);
          swipeStores.add(existingStore);
        }
      }
      // ステータスが設定済みの店舗（既にスワイプ済み）は除外
    }

    return swipeStores;
  }
}
