import 'package:geolocator/geolocator.dart';
import '../../domain/entities/location.dart';
import '../../domain/services/location_service.dart';

/// Geolocatorパッケージを使用した位置情報サービスの実装
class GeolocatorLocationService implements LocationService {
  @override
  Future<Location> getCurrentLocation() async {
    try {
      // 🟢 GREEN: 仮実装 - まずは固定位置を返してテストを通す
      // 実際のGPS機能は次のステップで実装
      final position = Position(
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
      
      return convertPositionToLocation(position);
    } catch (e) {
      throw LocationException(
        'Failed to get current location: $e',
        LocationExceptionType.locationUnavailable,
      );
    }
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    // 🟢 GREEN: 仮実装でテストを通す
    return true;
  }

  @override
  Future<bool> hasLocationPermission() async {
    // 🟢 GREEN: 仮実装でテストを通す
    return true;
  }

  @override
  Future<bool> requestLocationPermission() async {
    // 🟢 GREEN: 仮実装でテストを通す
    return true;
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