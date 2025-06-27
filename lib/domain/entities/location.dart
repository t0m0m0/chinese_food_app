/// 位置情報を表すエンティティ
class Location {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime timestamp;

  const Location({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.timestamp,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Location &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.accuracy == accuracy &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return latitude.hashCode ^
        longitude.hashCode ^
        accuracy.hashCode ^
        timestamp.hashCode;
  }

  @override
  String toString() {
    return 'Location(latitude: $latitude, longitude: $longitude, accuracy: $accuracy, timestamp: $timestamp)';
  }
}

/// 位置情報サービスの例外
class LocationException implements Exception {
  final String message;
  final LocationExceptionType type;

  const LocationException(this.message, this.type);

  @override
  String toString() => 'LocationException: $message';
}

/// 位置情報例外の種類
enum LocationExceptionType {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  locationUnavailable,
  timeout,
}