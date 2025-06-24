import '../entities/store.dart';
import '../repositories/store_repository.dart';

class SearchStoresUsecase {
  final StoreRepository repository;

  SearchStoresUsecase(this.repository);

  Future<SearchStoresResult> execute(SearchStoresParams params) async {
    try {
      final stores = await repository.searchStoresFromApi(
        lat: params.lat,
        lng: params.lng,
        address: params.address,
        keyword: params.keyword,
        range: params.range,
        count: params.count,
        start: params.start,
      );

      return SearchStoresResult.success(stores);
    } catch (e) {
      return SearchStoresResult.failure(e.toString());
    }
  }
}

class SearchStoresParams {
  final double? lat;
  final double? lng;
  final String? address;
  final String? keyword;
  final int range;
  final int count;
  final int start;

  const SearchStoresParams({
    this.lat,
    this.lng,
    this.address,
    this.keyword,
    this.range = 3,
    this.count = 20,
    this.start = 1,
  });

  bool get hasLocationSearch => lat != null && lng != null;
  bool get hasAddressSearch => address != null && address!.isNotEmpty;
  bool get hasValidSearchCriteria => hasLocationSearch || hasAddressSearch;

  @override
  String toString() {
    return 'SearchStoresParams(lat: $lat, lng: $lng, address: $address, keyword: $keyword)';
  }
}

class SearchStoresResult {
  final List<Store>? stores;
  final String? error;
  final bool isSuccess;

  const SearchStoresResult._({
    this.stores,
    this.error,
    required this.isSuccess,
  });

  factory SearchStoresResult.success(List<Store> stores) {
    return SearchStoresResult._(
      stores: stores,
      isSuccess: true,
    );
  }

  factory SearchStoresResult.failure(String error) {
    return SearchStoresResult._(
      error: error,
      isSuccess: false,
    );
  }

  bool get hasStores => stores != null && stores!.isNotEmpty;

  @override
  String toString() {
    if (isSuccess) {
      return 'SearchStoresResult.success(${stores?.length} stores)';
    } else {
      return 'SearchStoresResult.failure($error)';
    }
  }
}
