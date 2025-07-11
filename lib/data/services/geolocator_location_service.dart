import 'dart:async';
import 'dart:developer' as developer;
import 'package:geolocator/geolocator.dart';
import '../../core/config/location_config.dart';
import '../../domain/entities/location.dart';
import '../../domain/services/location_service.dart';

/// Geolocatorパッケージを使用した位置情報サービスの実装
class GeolocatorLocationService implements LocationService {
  /// 位置情報取得のタイムアウト時間（秒）
  final int timeoutSeconds;

  /// 位置情報の精度設定
  final LocationAccuracy accuracy;

  const GeolocatorLocationService({
    this.timeoutSeconds = LocationConfig.defaultTimeoutSeconds,
    this.accuracy = LocationConfig.defaultAccuracy,
  });
  @override
  Future<Location> getCurrentLocation() async {
    developer.log('Starting location request with timeout: ${timeoutSeconds}s',
        name: 'LocationService');

    try {
      // 位置情報サービスが有効かチェック
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      developer.log('Location service enabled: $serviceEnabled',
          name: 'LocationService');

      if (!serviceEnabled) {
        developer.log('Location service disabled, throwing exception',
            name: 'LocationService');
        throw LocationException(
          'Location services are disabled',
          LocationExceptionType.serviceDisabled,
        );
      }

      // 権限チェック
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw LocationException(
            'Location permission denied',
            LocationExceptionType.permissionDenied,
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw LocationException(
          'Location permission denied forever',
          LocationExceptionType.permissionDeniedForever,
        );
      }

      // 実際の位置情報取得（タイムアウト付き）
      developer.log('Requesting location with accuracy: $accuracy',
          name: 'LocationService');
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: Duration(seconds: timeoutSeconds),
        ),
      );

      final location = convertPositionToLocation(position);
      developer.log(
          'Location obtained: ${location.latitude}, ${location.longitude} (accuracy: ${location.accuracy}m)',
          name: 'LocationService');

      return location;
    } on TimeoutException {
      developer.log('Location request timed out after ${timeoutSeconds}s',
          name: 'LocationService');
      throw LocationException(
        'Location request timed out',
        LocationExceptionType.timeout,
      );
    } on LocationServiceDisabledException {
      developer.log('Location service disabled exception',
          name: 'LocationService');
      throw LocationException(
        'Location services are disabled',
        LocationExceptionType.serviceDisabled,
      );
    } on PermissionDeniedException {
      developer.log('Location permission denied exception',
          name: 'LocationService');
      throw LocationException(
        'Location permission denied',
        LocationExceptionType.permissionDenied,
      );
    } on PermissionRequestInProgressException {
      developer.log('Permission request already in progress',
          name: 'LocationService');
      throw LocationException(
        'Location permission request is already in progress',
        LocationExceptionType.permissionDenied,
      );
    } on PermissionDefinitionsNotFoundException {
      developer.log('Location permission definitions not found',
          name: 'LocationService');
      throw LocationException(
        'Location permission settings are not configured properly',
        LocationExceptionType.permissionDenied,
      );
    } catch (e) {
      developer.log('Unexpected location error: $e', name: 'LocationService');
      // より適切なエラー分類（文字列チェックによるフォールバック）
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('permission') ||
          errorMessage.contains('denied')) {
        throw LocationException(
          'Location permission error: $e',
          LocationExceptionType.permissionDenied,
        );
      } else if (errorMessage.contains('disabled') ||
          errorMessage.contains('unavailable') ||
          errorMessage.contains('service')) {
        throw LocationException(
          'Location service unavailable: $e',
          LocationExceptionType.serviceDisabled,
        );
      } else if (errorMessage.contains('timeout')) {
        throw LocationException(
          'Location request timeout: $e',
          LocationExceptionType.timeout,
        );
      } else {
        throw LocationException(
          'Failed to get current location: $e',
          LocationExceptionType.locationUnavailable,
        );
      }
    }
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  @override
  Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  @override
  Future<bool> requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// GeolocatorのPositionをLocationエンティティに変換
  Location convertPositionToLocation(Position position) {
    return Location(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      timestamp: position.timestamp,
    );
  }
}
