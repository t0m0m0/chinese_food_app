import '../../domain/entities/store.dart';
import '../../domain/repositories/store_repository.dart';
import '../../domain/services/location_service.dart';

class StoreBusinessLogic {
  final StoreRepository _repository;
  final LocationService _locationService;
  List<Store> _stores = [];

  StoreBusinessLogic({
    required StoreRepository repository,
    required LocationService locationService,
  }) : _repository = repository,
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
}