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

class LocationGeocodeError extends LocationError {
  LocationGeocodeError(super.message);

  @override
  String toString() => 'LocationGeocodeError: $message';
}

class LocationNetworkError extends LocationError {
  LocationNetworkError(super.message);

  @override
  String toString() => 'LocationNetworkError: $message';
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

  // TDD REFACTOR段階: 環境変数による権限チェック制御
  Future<PermissionResult> checkLocationPermission() async {
    final permissionTestMode = Platform.environment['PERMISSION_TEST_MODE'];
    
    // テスト環境での権限拒否シミュレーション
    if (permissionTestMode == 'denied') {
      return PermissionResult.denied(
        '位置情報の権限が拒否されました',
        errorType: LocationPermissionDeniedError('テスト用権限拒否'),
      );
    } else if (permissionTestMode == 'denied_forever') {
      return PermissionResult.denied(
        '位置情報の権限が永続的に拒否されています。設定から許可してください',
        errorType: LocationPermissionDeniedError('永続的権限拒否'),
      );
    } else if (permissionTestMode == 'service_disabled') {
      return PermissionResult.denied(
        '位置情報サービスが無効です',
        errorType: LocationServiceDisabledError('サービス無効'),
      );
    }
    
    // TODO(#42): [HIGH] 本番環境では実際のGeolocator.checkPermission()を使用 - Sprint 2.1で対応予定
    // 実装内容: Geolocatorパッケージの有効化、実際の権限チェック機能
    // final permission = await Geolocator.checkPermission();
    // 現時点では権限許可として扱う（実GPS実装時に修正）
    return PermissionResult.granted();
  }

  Future<LocationServiceResult> getCurrentPosition() async {
    try {
      // TDD GREEN段階: 環境変数による実装切り替え
      final locationMode = Platform.environment['LOCATION_MODE'] ?? 'test';

      if (locationMode == 'production') {
        // 本番環境: 権限チェック後にGPS取得（実GPS実装準備）
        final permission = await checkLocationPermission();
        if (!permission.isGranted) {
          return LocationServiceResult.failure(
            permission.errorMessage ?? 'Permission denied'
          );
        }
        
        // TODO(#42): [HIGH] 実際のGPS実装 - Sprint 2.1で対応予定  
        // 実装内容: Geolocatorパッケージ有効化、LocationSettings設定、実座標取得
        // final position = await Geolocator.getCurrentPosition(locationSettings: _locationSettings);
        // return LocationServiceResult.success(lat: position.latitude, lng: position.longitude);
        
        // 暫定的にダミーデータを返す（権限チェック後）
        return LocationServiceResult.success(
          lat: 35.6762, // 東京駅
          lng: 139.6503,
        );
      } else {
        // テスト環境：環境変数でエラーシミュレーション可能
        final errorMode = Platform.environment['LOCATION_ERROR_MODE'];
        
        if (errorMode == 'permission_denied') {
          return LocationServiceResult.failure('権限が拒否されました');
        } else if (errorMode == 'service_disabled') {
          return LocationServiceResult.failure('位置情報サービスが無効です');
        } else if (errorMode == 'timeout') {
          return LocationServiceResult.failure('位置取得がタイムアウトしました');
        }
        
        // テスト環境：正常時はダミーデータ
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
      // 具体的なエラー型による改善されたエラーハンドリング
      if (e.toString().contains('network') || e.toString().contains('connection')) {
        return GeocodeResult.failure('ネットワークエラーが発生しました');
      } else if (e.toString().contains('format') || e.toString().contains('invalid')) {
        return GeocodeResult.failure('座標の形式が正しくありません');
      } else if (e.toString().contains('timeout')) {
        return GeocodeResult.failure('リバースジオコーディングがタイムアウトしました');
      } else {
        return GeocodeResult.failure('リバースジオコーディングエラー: ${e.runtimeType}');
      }
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
      // 具体的なエラー型による改善されたエラーハンドリング
      if (e.toString().contains('network') || e.toString().contains('connection')) {
        return GeocodeResult.failure('ネットワークエラーが発生しました');
      } else if (e.toString().contains('format') || e.toString().contains('invalid')) {
        return GeocodeResult.failure('住所の形式が正しくありません');
      } else if (e.toString().contains('timeout')) {
        return GeocodeResult.failure('ジオコーディングがタイムアウトしました');
      } else {
        return GeocodeResult.failure('ジオコーディングエラー: ${e.runtimeType}');
      }
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
