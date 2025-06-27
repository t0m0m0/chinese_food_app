import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/domain/entities/location.dart';
import 'package:chinese_food_app/domain/services/location_service.dart';

/// LocationServiceの基本機能テスト
void main() {
  group('LocationService Tests', () {
    late LocationService locationService;
    late MockLocationService mockLocationService;

    setUp(() {
      mockLocationService = MockLocationService();
      locationService = mockLocationService;
    });

    test('should get current location successfully', () async {
      // 🔴 このテストは失敗するはずです - getCurrentLocation()が実装されていません
      final location = await locationService.getCurrentLocation();

      expect(location, isA<Location>());
      expect(location.latitude, isA<double>());
      expect(location.longitude, isA<double>());
      expect(location.latitude, greaterThanOrEqualTo(-90.0));
      expect(location.latitude, lessThanOrEqualTo(90.0));
      expect(location.longitude, greaterThanOrEqualTo(-180.0));
      expect(location.longitude, lessThanOrEqualTo(180.0));
    });

    test('should check if location services are enabled', () async {
      // 🔴 このテストは失敗するはずです - isLocationServiceEnabled()が実装されていません
      final isEnabled = await locationService.isLocationServiceEnabled();

      expect(isEnabled, isA<bool>());
    });

    test('should check location permissions', () async {
      // 🔴 このテストは失敗するはずです - hasLocationPermission()が実装されていません
      final hasPermission = await locationService.hasLocationPermission();

      expect(hasPermission, isA<bool>());
    });

    test('should request location permissions', () async {
      // 🔴 このテストは失敗するはずです - requestLocationPermission()が実装されていません
      final granted = await locationService.requestLocationPermission();

      expect(granted, isA<bool>());
    });

    test('should throw LocationException when location services are disabled',
        () async {
      // LocationServiceの状態を設定
      mockLocationService.setLocationServiceEnabled(false);

      expect(
        () async => await locationService.getCurrentLocation(),
        throwsA(isA<LocationException>()),
      );
    });

    test('should throw LocationException when permission is denied', () async {
      // LocationServiceの権限状態を設定
      mockLocationService.setShouldThrowPermissionDenied(true);

      expect(
        () async => await locationService.getCurrentLocation(),
        throwsA(isA<LocationException>()),
      );
    });
  });
}

/// テスト用のMockLocationService
class MockLocationService implements LocationService {
  bool _isLocationServiceEnabled = true;
  bool _hasLocationPermission = true;
  bool _shouldThrowPermissionDenied = false;

  void setLocationServiceEnabled(bool enabled) {
    _isLocationServiceEnabled = enabled;
  }

  void setHasLocationPermission(bool hasPermission) {
    _hasLocationPermission = hasPermission;
  }

  void setShouldThrowPermissionDenied(bool shouldThrow) {
    _shouldThrowPermissionDenied = shouldThrow;
  }

  @override
  Future<Location> getCurrentLocation() async {
    if (!_isLocationServiceEnabled) {
      throw LocationException(
        'Location services are disabled',
        LocationExceptionType.serviceDisabled,
      );
    }

    if (_shouldThrowPermissionDenied || !_hasLocationPermission) {
      throw LocationException(
        'Location permission denied',
        LocationExceptionType.permissionDenied,
      );
    }

    // 正常時はモックの位置データを返す
    return Location(
      latitude: 35.6762,
      longitude: 139.6503,
      accuracy: 10.0,
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    return _isLocationServiceEnabled;
  }

  @override
  Future<bool> hasLocationPermission() async {
    return _hasLocationPermission;
  }

  @override
  Future<bool> requestLocationPermission() async {
    if (_hasLocationPermission) {
      return true;
    }
    // 権限リクエストが成功した場合の仮実装
    _hasLocationPermission = true;
    return true;
  }
}
