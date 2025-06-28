// import 'package:geolocator/geolocator.dart';  // 一時的に無効化
import 'package:geocoding/geocoding.dart';
import 'dart:io' show Platform;

// TDD GREEN段階: 最小限のエラー型定義
abstract class LocationError extends Error {
  final String message;
  LocationError(this.message);
  
  @override
  String toString() => 'LocationError: $message';
}

class LocationPermissionDeniedError extends LocationError {
  LocationPermissionDeniedError(super.message);
  
  @override
  String toString() => 'LocationPermissionDeniedError: $message';
}

class LocationServiceDisabledError extends LocationError {
  LocationServiceDisabledError(super.message);
  
  @override
  String toString() => 'LocationServiceDisabledError: $message';
}

class LocationTimeoutError extends LocationError {
  LocationTimeoutError(super.message);
  
  @override
  String toString() => 'LocationTimeoutError: $message';
}

// TDD GREEN段階: PermissionResult型の定義
class PermissionResult {
  final bool isGranted;
  final String? errorMessage;
  final LocationError? errorType;

  const PermissionResult._({
    required this.isGranted,
    this.errorMessage,
    this.errorType,
  });

  factory PermissionResult.granted() {
    return const PermissionResult._(isGranted: true);
  }

  factory PermissionResult.denied(String message, {LocationError? errorType}) {
    return PermissionResult._(
      isGranted: false,
      errorMessage: message,
      errorType: errorType,
    );
  }
}

class LocationService {
  // static const LocationSettings _locationSettings = LocationSettings(
  //   accuracy: LocationAccuracy.high,
  //   distanceFilter: 100,
  // );

  // TDD GREEN段階: 最小限のcheckLocationPermissionメソッド
  Future<PermissionResult> checkLocationPermission() async {
    // 仮実装: 常に権限が許可されていると返す（三角測量で後で改善）
    return PermissionResult.granted();
  }

  Future<LocationServiceResult> getCurrentPosition() async {
    try {
      // TDD GREEN段階: 環境変数による実装切り替え
      final locationMode = Platform.environment['LOCATION_MODE'] ?? 'test';
      
      if (locationMode == 'production') {
        // TODO: 実際のGPS実装（後で実装）
        // final permission = await checkLocationPermission();
        // if (!permission.isGranted) {
        //   return LocationServiceResult.failure(permission.errorMessage ?? 'Permission denied');
        // }
        // 
        // final position = await Geolocator.getCurrentPosition();
        // return LocationServiceResult.success(lat: position.latitude, lng: position.longitude);
        
        // 暫定的にダミーデータを返す（実GPS実装前）
        return LocationServiceResult.success(
          lat: 35.6762, // 東京駅
          lng: 139.6503,
        );
      } else {
        // テスト環境：ダミーデータを返す
        return LocationServiceResult.success(
          lat: 35.6762, // 東京駅
          lng: 139.6503,
        );
      }
    } catch (e) {
      return LocationServiceResult.failure(e.toString());
    }
  }

  Future<GeocodeResult> getAddressFromCoordinates(
    double lat,
    double lng,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) {
        return GeocodeResult.failure('住所が見つかりませんでした');
      }

      final placemark = placemarks.first;
      final address = _formatAddress(placemark);

      return GeocodeResult.success(address);
    } catch (e) {
      return GeocodeResult.failure(e.toString());
    }
  }

  Future<GeocodeResult> getCoordinatesFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isEmpty) {
        return GeocodeResult.failure('座標が見つかりませんでした');
      }

      final location = locations.first;
      return GeocodeResult.success(
        '${location.latitude}, ${location.longitude}',
        lat: location.latitude,
        lng: location.longitude,
      );
    } catch (e) {
      return GeocodeResult.failure(e.toString());
    }
  }


  String _formatAddress(Placemark placemark) {
    final components = <String>[];

    if (placemark.administrativeArea?.isNotEmpty == true) {
      components.add(placemark.administrativeArea!);
    }
    if (placemark.locality?.isNotEmpty == true) {
      components.add(placemark.locality!);
    }
    if (placemark.subLocality?.isNotEmpty == true) {
      components.add(placemark.subLocality!);
    }
    if (placemark.thoroughfare?.isNotEmpty == true) {
      components.add(placemark.thoroughfare!);
    }
    if (placemark.subThoroughfare?.isNotEmpty == true) {
      components.add(placemark.subThoroughfare!);
    }

    return components.join(' ');
  }
}

class LocationServiceResult {
  final double? lat;
  final double? lng;
  final String? error;
  final bool isSuccess;

  const LocationServiceResult._({
    this.lat,
    this.lng,
    this.error,
    required this.isSuccess,
  });

  factory LocationServiceResult.success({
    required double lat,
    required double lng,
  }) {
    return LocationServiceResult._(
      lat: lat,
      lng: lng,
      isSuccess: true,
    );
  }

  factory LocationServiceResult.failure(String error) {
    return LocationServiceResult._(
      error: error,
      isSuccess: false,
    );
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'LocationServiceResult.success(lat: $lat, lng: $lng)';
    } else {
      return 'LocationServiceResult.failure($error)';
    }
  }
}

class GeocodeResult {
  final String? address;
  final double? lat;
  final double? lng;
  final String? error;
  final bool isSuccess;

  const GeocodeResult._({
    this.address,
    this.lat,
    this.lng,
    this.error,
    required this.isSuccess,
  });

  factory GeocodeResult.success(
    String address, {
    double? lat,
    double? lng,
  }) {
    return GeocodeResult._(
      address: address,
      lat: lat,
      lng: lng,
      isSuccess: true,
    );
  }

  factory GeocodeResult.failure(String error) {
    return GeocodeResult._(
      error: error,
      isSuccess: false,
    );
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'GeocodeResult.success($address)';
    } else {
      return 'GeocodeResult.failure($error)';
    }
  }
}
