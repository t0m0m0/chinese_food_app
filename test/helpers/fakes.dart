import 'package:chinese_food_app/domain/services/location_service.dart';
import 'package:chinese_food_app/domain/repositories/store_repository.dart';
import 'package:chinese_food_app/domain/repositories/location_repository.dart';
import 'package:chinese_food_app/domain/entities/location.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/core/types/result.dart';
import 'package:chinese_food_app/core/exceptions/app_exception.dart';

/// 設定可能なLocationServiceのFake実装
///
/// 状態を持つテストダブルで、統合テストや複雑なシナリオテストに適している。
///
/// 使用例：
/// ```dart
/// test('location scenario test', () async {
///   final fakeService = FakeLocationService()
///     ..setCurrentLocation(Location(latitude: 35.6762, longitude: 139.6503))
///     ..setServiceEnabled(true)
///     ..setPermissionGranted(true);
///
///   final result = await fakeService.getCurrentLocation();
///   expect(result.latitude, 35.6762);
/// });
/// ```
class FakeLocationService implements LocationService {
  Location? _currentLocation;
  bool _serviceEnabled = true;
  bool _permissionGranted = true;
  bool _shouldThrowError = false;
  Exception? _errorToThrow;

  /// 現在位置を設定
  void setCurrentLocation(Location location) {
    _currentLocation = location;
  }

  /// サービス有効状態を設定
  void setServiceEnabled(bool enabled) {
    _serviceEnabled = enabled;
  }

  /// 権限状態を設定
  void setPermissionGranted(bool granted) {
    _permissionGranted = granted;
  }

  /// エラーを投げるかどうかを設定
  void setShouldThrowError(bool shouldThrow, [Exception? error]) {
    _shouldThrowError = shouldThrow;
    _errorToThrow = error;
  }

  /// 初期状態にリセット
  void reset() {
    _currentLocation = null;
    _serviceEnabled = true;
    _permissionGranted = true;
    _shouldThrowError = false;
    _errorToThrow = null;
  }

  @override
  Future<Location> getCurrentLocation() async {
    if (_shouldThrowError) {
      throw _errorToThrow ?? Exception('Location error');
    }

    if (!_serviceEnabled) {
      throw Exception('Location service disabled');
    }

    if (!_permissionGranted) {
      throw Exception('Location permission denied');
    }

    return _currentLocation ??
        Location(
          latitude: 35.6762,
          longitude: 139.6503,
          timestamp: DateTime.now(),
          accuracy: 10.0,
        );
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    return _serviceEnabled;
  }

  @override
  Future<bool> hasLocationPermission() async {
    return _permissionGranted;
  }

  @override
  Future<bool> requestLocationPermission() async {
    return _permissionGranted;
  }
}

/// 設定可能なStoreRepositoryのFake実装
///
/// インメモリでストアデータを管理するテストダブル。
/// 複雑なデータ操作シナリオのテストに適している。
class FakeStoreRepository implements StoreRepository {
  final List<Store> _stores = [];
  bool _shouldThrowError = false;
  Exception? _errorToThrow;

  /// ストアを追加
  void addStore(Store store) {
    _stores.add(store);
  }

  /// 全ストアをクリア
  void clearStores() {
    _stores.clear();
  }

  /// エラーを投げるかどうかを設定
  void setShouldThrowError(bool shouldThrow, [Exception? error]) {
    _shouldThrowError = shouldThrow;
    _errorToThrow = error;
  }

  void _throwIfNeeded() {
    if (_shouldThrowError) {
      throw _errorToThrow ?? Exception('Repository error');
    }
  }

  @override
  Future<List<Store>> getAllStores() async {
    _throwIfNeeded();
    return List.from(_stores);
  }

  @override
  Future<List<Store>> getStoresByStatus(StoreStatus status) async {
    _throwIfNeeded();
    return _stores.where((store) => store.status == status).toList();
  }

  @override
  Future<Store?> getStoreById(String id) async {
    _throwIfNeeded();
    try {
      return _stores.firstWhere((store) => store.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> insertStore(Store store) async {
    _throwIfNeeded();
    _stores.add(store);
  }

  @override
  Future<void> updateStore(Store store) async {
    _throwIfNeeded();
    final index = _stores.indexWhere((s) => s.id == store.id);
    if (index != -1) {
      _stores[index] = store;
    }
  }

  @override
  Future<void> deleteStore(String id) async {
    _throwIfNeeded();
    _stores.removeWhere((store) => store.id == id);
  }

  @override
  Future<List<Store>> searchStores(String query) async {
    _throwIfNeeded();
    return _stores
        .where((store) =>
            store.name.toLowerCase().contains(query.toLowerCase()) ||
            store.address.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Future<List<Store>> searchStoresFromApi({
    double? lat,
    double? lng,
    String? address,
    String? keyword,
    int range = 3,
    int count = 20,
    int start = 1,
  }) async {
    _throwIfNeeded();
    // API検索のシミュレーション - 実際のテストでは事前に設定されたデータを返す
    return _stores.take(count).toList();
  }
}

/// 設定可能なLocationRepositoryのFake実装
class FakeLocationRepository implements LocationRepository {
  Location? _currentLocation;
  bool _shouldReturnFailure = false;
  AppException? _exceptionToReturn;

  /// 現在位置を設定
  void setCurrentLocation(Location location) {
    _currentLocation = location;
  }

  /// 失敗結果を返すかどうかを設定
  void setShouldReturnFailure(bool shouldFail, [AppException? exception]) {
    _shouldReturnFailure = shouldFail;
    _exceptionToReturn = exception;
  }

  /// 初期状態にリセット
  void reset() {
    _currentLocation = null;
    _shouldReturnFailure = false;
    _exceptionToReturn = null;
  }

  @override
  Future<Result<Location>> getCurrentLocation() async {
    if (_shouldReturnFailure) {
      return Failure(
          _exceptionToReturn ?? AppException('Location repository error'));
    }

    final location = _currentLocation ??
        Location(
          latitude: 35.6762,
          longitude: 139.6503,
          timestamp: DateTime.now(),
          accuracy: 10.0,
        );

    return Success(location);
  }
}
