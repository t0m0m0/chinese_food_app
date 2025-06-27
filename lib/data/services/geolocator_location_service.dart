import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../../domain/entities/location.dart';
import '../../domain/services/location_service.dart';

/// Geolocatorパッケージを使用した位置情報サービスの実装
class GeolocatorLocationService implements LocationService {
  @override
  Future<Location> getCurrentLocation() async {
    try {
      // 位置情報サービスが有効かチェック
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
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
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );
      
      return convertPositionToLocation(position);
    } on TimeoutException {
      throw LocationException(
        'Location request timed out',
        LocationExceptionType.timeout,
      );
    } catch (e) {
      throw LocationException(
        'Failed to get current location: $e',
        LocationExceptionType.locationUnavailable,
      );
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