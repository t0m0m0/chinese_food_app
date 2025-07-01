import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mockito/annotations.dart';
import 'package:chinese_food_app/domain/entities/location.dart';
import 'package:chinese_food_app/data/services/geolocator_location_service.dart';

// モック生成のためのアノテーション
@GenerateMocks([])
void main() {
  // テスト前の初期化を最小限にして高速化
  setUpAll(() {
    // 必要な場合のみ初期化処理を追加
  });
  group('GeolocatorLocationService Tests', () {
    late GeolocatorLocationService locationService;

    setUp(() {
      // 軽量化：遅延初期化を使用
      locationService = GeolocatorLocationService();
    });

    group('convertPositionToLocation', () {
      test('should convert Geolocator Position to Location entity', () {
        // Mock Positionオブジェクト
        final mockPosition = Position(
          latitude: 35.6762,
          longitude: 139.6503,
          timestamp: DateTime.now(),
          accuracy: 5.0,
          altitude: 10.0,
          altitudeAccuracy: 3.0,
          heading: 0.0,
          headingAccuracy: 1.0,
          speed: 0.0,
          speedAccuracy: 0.5,
        );

        final location =
            locationService.convertPositionToLocation(mockPosition);

        expect(location.latitude, equals(mockPosition.latitude));
        expect(location.longitude, equals(mockPosition.longitude));
        expect(location.accuracy, equals(mockPosition.accuracy));
        expect(location.timestamp, equals(mockPosition.timestamp));
      });
    });

    group('Constructor Configuration Tests', () {
      test('should use default timeout and accuracy', () {
        final service = GeolocatorLocationService();
        expect(service.timeoutSeconds, equals(10));
        expect(service.accuracy, equals(LocationAccuracy.high));
      });

      test('should accept custom timeout and accuracy', () {
        final service = GeolocatorLocationService(
          timeoutSeconds: 15,
          accuracy: LocationAccuracy.medium,
        );
        expect(service.timeoutSeconds, equals(15));
        expect(service.accuracy, equals(LocationAccuracy.medium));
      });
    });

    group('MockableGeolocatorLocationService Tests', () {
      late MockableGeolocatorLocationService testService;

      setUp(() {
        testService = MockableGeolocatorLocationService();
      });

      test('should throw LocationException when location services are disabled',
          () async {
        testService.setLocationServiceEnabled(false);

        expect(
          () async => await testService.getCurrentLocation(),
          throwsA(isA<LocationException>()),
        );
      });

      test('should throw LocationException when permission is denied',
          () async {
        testService.setLocationPermission(LocationPermission.denied);

        expect(
          () async => await testService.getCurrentLocation(),
          throwsA(isA<LocationException>()),
        );
      });

      test('should throw LocationException when permission is denied forever',
          () async {
        testService.setLocationPermission(LocationPermission.deniedForever);

        expect(
          () async => await testService.getCurrentLocation(),
          throwsA(allOf([
            isA<LocationException>(),
            predicate<LocationException>(
                (e) => e.type == LocationExceptionType.permissionDeniedForever),
          ])),
        );
      });

      test('should handle timeout when getting location', () async {
        testService.setTimeoutError(true);

        expect(
          () async => await testService.getCurrentLocation(),
          throwsA(allOf([
            isA<LocationException>(),
            predicate<LocationException>(
                (e) => e.type == LocationExceptionType.timeout),
          ])),
        );
      });

      test('should check if location services are enabled', () async {
        testService.setLocationServiceEnabled(false);
        expect(await testService.isLocationServiceEnabled(), isFalse);

        testService.setLocationServiceEnabled(true);
        expect(await testService.isLocationServiceEnabled(), isTrue);
      });

      test('should check location permission', () async {
        testService.setLocationPermission(LocationPermission.denied);
        expect(await testService.hasLocationPermission(), isFalse);

        testService.setLocationPermission(LocationPermission.whileInUse);
        expect(await testService.hasLocationPermission(), isTrue);

        testService.setLocationPermission(LocationPermission.always);
        expect(await testService.hasLocationPermission(), isTrue);
      });

      test('should handle location permission request', () async {
        testService.setLocationPermission(LocationPermission.deniedForever);
        expect(await testService.requestLocationPermission(), isFalse);

        testService.setLocationPermission(LocationPermission.denied);
        expect(await testService.requestLocationPermission(), isTrue);
      });

      test('should get location when all conditions are met', () async {
        testService.setLocationServiceEnabled(true);
        testService.setLocationPermission(LocationPermission.whileInUse);
        testService.setTimeoutError(false);
        testService.setMockPosition(Position(
          latitude: 35.6762,
          longitude: 139.6503,
          timestamp: DateTime.now(),
          accuracy: 5.0,
          altitude: 10.0,
          altitudeAccuracy: 3.0,
          heading: 0.0,
          headingAccuracy: 1.0,
          speed: 0.0,
          speedAccuracy: 0.5,
        ));

        final location = await testService.getCurrentLocation();

        expect(location, isA<Location>());
        expect(location.latitude, equals(35.6762));
        expect(location.longitude, equals(139.6503));
        expect(location.accuracy, equals(5.0));
      });

      test('should handle specific geolocator exceptions', () async {
        testService.setLocationServiceEnabled(true);
        testService.setLocationPermission(LocationPermission.whileInUse);
        testService
            .setSpecificError(Exception('LocationServiceDisabledException'));

        expect(
          () async => await testService.getCurrentLocation(),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle permission denied exception', () async {
        testService.setLocationServiceEnabled(true);
        testService.setSpecificError(Exception('permission denied'));

        expect(
          () async => await testService.getCurrentLocation(),
          throwsA(isA<Exception>()),
        );
      });

      test('should use custom timeout setting', () async {
        final customService = MockableGeolocatorLocationServiceWithTimeout(
          timeoutSeconds: 5,
        );

        expect(customService.timeoutSeconds, equals(5));
        expect(customService.accuracy, equals(LocationAccuracy.high));
      });

      test('should use custom accuracy setting', () async {
        final customService = MockableGeolocatorLocationServiceWithTimeout(
          accuracy: LocationAccuracy.low,
        );

        expect(customService.timeoutSeconds, equals(10));
        expect(customService.accuracy, equals(LocationAccuracy.low));
      });
    });
  });
}

/// テスト用のMockable GeolocatorLocationService
/// エラー状態をシミュレートできる
class MockableGeolocatorLocationService extends GeolocatorLocationService {
  bool _isLocationServiceEnabled = true;
  LocationPermission _locationPermission = LocationPermission.whileInUse;
  bool _shouldTimeoutError = false;
  Position? _mockPosition;
  Exception? _specificError;

  void setLocationServiceEnabled(bool enabled) {
    _isLocationServiceEnabled = enabled;
  }

  void setLocationPermission(LocationPermission permission) {
    _locationPermission = permission;
  }

  void setTimeoutError(bool shouldTimeout) {
    _shouldTimeoutError = shouldTimeout;
  }

  void setMockPosition(Position position) {
    _mockPosition = position;
  }

  void setSpecificError(Exception error) {
    _specificError = error;
  }

  @override
  Future<Location> getCurrentLocation() async {
    // 特定のエラーが設定されている場合はそれを投げる
    if (_specificError != null) {
      throw _specificError!;
    }

    if (!_isLocationServiceEnabled) {
      throw LocationException(
        'Location services are disabled',
        LocationExceptionType.serviceDisabled,
      );
    }

    if (_locationPermission == LocationPermission.denied) {
      throw LocationException(
        'Location permission denied',
        LocationExceptionType.permissionDenied,
      );
    }

    if (_locationPermission == LocationPermission.deniedForever) {
      throw LocationException(
        'Location permission denied forever',
        LocationExceptionType.permissionDeniedForever,
      );
    }

    if (_shouldTimeoutError) {
      throw LocationException(
        'Location request timed out',
        LocationExceptionType.timeout,
      );
    }

    if (_mockPosition != null) {
      return convertPositionToLocation(_mockPosition!);
    }

    // デフォルトのモック位置（東京駅）
    return Location(
      latitude: 35.6812,
      longitude: 139.7671,
      accuracy: 5.0,
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    return _isLocationServiceEnabled;
  }

  @override
  Future<bool> hasLocationPermission() async {
    return _locationPermission == LocationPermission.whileInUse ||
        _locationPermission == LocationPermission.always;
  }

  @override
  Future<bool> requestLocationPermission() async {
    if (_locationPermission == LocationPermission.deniedForever) {
      return false;
    }
    _locationPermission = LocationPermission.whileInUse;
    return true;
  }
}

/// テスト用のカスタムタイムアウト設定可能なMockableGeolocatorLocationService
class MockableGeolocatorLocationServiceWithTimeout
    extends GeolocatorLocationService {
  const MockableGeolocatorLocationServiceWithTimeout({
    super.timeoutSeconds = 10,
    super.accuracy = LocationAccuracy.high,
  });

  @override
  Future<Location> getCurrentLocation() async {
    // テスト用の固定位置を返す
    return Location(
      latitude: 35.6762,
      longitude: 139.6503,
      accuracy: 10.0,
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<bool> hasLocationPermission() async => true;

  @override
  Future<bool> requestLocationPermission() async => true;
}
