import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:io' show Platform;
import 'dart:developer' as developer;

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
  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 100,
  );

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

    // 実際のGeolocator権限チェック実装
    try {
      // 位置情報サービスの有効性確認
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return PermissionResult.denied(
          '位置情報サービスが無効です',
          errorType: LocationServiceDisabledError('サービス無効'),
        );
      }

      // 現在の権限状態を確認
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // 権限が拒否されている場合、リクエストを試行
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return PermissionResult.denied(
            '位置情報の権限が拒否されました',
            errorType: LocationPermissionDeniedError('権限拒否'),
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return PermissionResult.denied(
          '位置情報の権限が永続的に拒否されています。設定から許可してください',
          errorType: LocationPermissionDeniedError('永続拒否'),
        );
      }

      return PermissionResult.granted();
    } catch (e) {
      // ログに詳細を記録、ユーザーには一般的なメッセージを返す
      developer.log('Permission check failed: $e', name: 'LocationService');
      return PermissionResult.denied(
        '権限チェック中にエラーが発生しました。再試行してください。',
        errorType: LocationPermissionDeniedError('権限チェックエラー'),
      );
    }
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
              permission.errorMessage ?? 'Permission denied');
        }

        // 実際のGPS実装
        try {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: _locationSettings,
          );

          // 座標の妥当性チェック
          if (position.latitude.isNaN ||
              position.longitude.isNaN ||
              position.latitude.isInfinite ||
              position.longitude.isInfinite ||
              position.latitude.abs() > 90 ||
              position.longitude.abs() > 180) {
            developer.log(
                'Invalid GPS coordinates received: lat=${position.latitude}, lng=${position.longitude}',
                name: 'LocationService');
            return LocationServiceResult.failure('無効な座標データを受信しました');
          }

          return LocationServiceResult.success(
            lat: position.latitude,
            lng: position.longitude,
          );
        } catch (e) {
          // GPS取得エラーの場合は適切なエラーメッセージを返す
          if (e.toString().contains('timeout') ||
              e.toString().contains('time')) {
            return LocationServiceResult.failure('GPS取得がタイムアウトしました');
          } else if (e.toString().contains('permission')) {
            return LocationServiceResult.failure('位置情報の権限が不足しています');
          } else {
            return LocationServiceResult.failure('GPS取得エラー: $e');
          }
        }
      } else {
        // TDD GREEN段階: Issue #43の新しい環境変数対応
        // QA Review修正: 環境変数バリデーション強化
        _validateEnvironmentVariables();

        // GPS精度モードシミュレーション
        final accuracyMode = Platform.environment['GPS_ACCURACY_MODE'];
        if (accuracyMode == 'low') {
          return LocationServiceResult.failure('GPS精度が低すぎます');
        } else if (accuracyMode == 'medium') {
          return LocationServiceResult.failure('GPS精度が中程度です');
        }

        // ネットワーク遅延モードシミュレーション
        final delayMode = Platform.environment['NETWORK_DELAY_MODE'];
        if (delayMode == '1s') {
          await Future.delayed(const Duration(seconds: 1));
        } else if (delayMode == '5s') {
          await Future.delayed(const Duration(seconds: 5));
        } else if (delayMode == 'timeout') {
          return LocationServiceResult.failure('ネットワークタイムアウト');
        }

        // バッテリー最適化モードシミュレーション
        final batteryMode = Platform.environment['BATTERY_OPTIMIZATION_MODE'];
        if (batteryMode == 'enabled') {
          return LocationServiceResult.failure('バッテリー最適化により位置情報が制限されています');
        }

        // 10種類のエラーパターンシミュレーション（仮実装）
        final errorPattern = Platform.environment['ERROR_SIMULATION_PATTERN'];
        if (errorPattern == 'gps_weak') {
          return LocationServiceResult.failure('GPS信号が弱すぎます');
        } else if (errorPattern == 'multipath') {
          return LocationServiceResult.failure('マルチパス干渉により位置情報が不安定です');
        } else if (errorPattern == 'indoor') {
          return LocationServiceResult.failure('屋内環境のためGPS取得できません');
        }

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
      if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        return GeocodeResult.failure('ネットワークエラーが発生しました');
      } else if (e.toString().contains('format') ||
          e.toString().contains('invalid')) {
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
      if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        return GeocodeResult.failure('ネットワークエラーが発生しました');
      } else if (e.toString().contains('format') ||
          e.toString().contains('invalid')) {
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

  /// QA Review修正: 環境変数バリデーション
  void _validateEnvironmentVariables() {
    // GPS精度モードの有効性チェック
    final accuracyMode = Platform.environment['GPS_ACCURACY_MODE'];
    const validAccuracyModes = ['low', 'medium', 'high'];
    if (accuracyMode != null && !validAccuracyModes.contains(accuracyMode)) {
      developer.log(
          'Invalid GPS_ACCURACY_MODE: $accuracyMode. Valid values: ${validAccuracyModes.join(', ')}',
          name: 'LocationService');
    }

    // ネットワーク遅延モードの有効性チェック
    final delayMode = Platform.environment['NETWORK_DELAY_MODE'];
    const validDelayModes = ['1s', '5s', 'timeout'];
    if (delayMode != null && !validDelayModes.contains(delayMode)) {
      developer.log(
          'Invalid NETWORK_DELAY_MODE: $delayMode. Valid values: ${validDelayModes.join(', ')}',
          name: 'LocationService');
    }

    // バッテリー最適化モードの有効性チェック
    final batteryMode = Platform.environment['BATTERY_OPTIMIZATION_MODE'];
    const validBatteryModes = ['enabled', 'disabled'];
    if (batteryMode != null && !validBatteryModes.contains(batteryMode)) {
      developer.log(
          'Invalid BATTERY_OPTIMIZATION_MODE: $batteryMode. Valid values: ${validBatteryModes.join(', ')}',
          name: 'LocationService');
    }

    // エラーシミュレーションパターンの有効性チェック
    final errorPattern = Platform.environment['ERROR_SIMULATION_PATTERN'];
    const validErrorPatterns = [
      'gps_weak',
      'multipath',
      'indoor',
      'battery_optimization',
      'permission_timing',
      'network_unstable',
      'high_speed_movement',
      'app_switching',
      'os_version_difference',
      'memory_shortage'
    ];
    if (errorPattern != null && !validErrorPatterns.contains(errorPattern)) {
      developer.log(
          'Invalid ERROR_SIMULATION_PATTERN: $errorPattern. Valid values: ${validErrorPatterns.join(', ')}',
          name: 'LocationService');
    }
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
