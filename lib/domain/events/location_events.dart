import '../entities/location.dart';
import '../../core/events/base_event.dart';

/// Event fired when the user's location is successfully updated
///
/// This event is published whenever the application successfully obtains
/// a new location reading from the device's GPS or location services.
/// Components can listen to this event to react to location changes.
///
/// Example usage:
/// ```dart
/// // Publishing
/// EventBus.instance.emit(LocationUpdatedEvent(
///   location: currentLocation,
///   timestamp: DateTime.now(),
/// ));
///
/// // Listening
/// EventBus.instance.on<LocationUpdatedEvent>().listen((event) {
///   updateMapView(event.location);
///   saveLocationToHistory(event.location, event.timestamp);
/// });
/// ```
class LocationUpdatedEvent extends BaseEvent {
  /// The new location data
  final Location location;

  /// When this location update occurred
  final DateTime timestamp;

  /// Creates a LocationUpdatedEvent
  ///
  /// [location] - The location data that was obtained
  /// [timestamp] - When this location update occurred
  const LocationUpdatedEvent({
    required this.location,
    required this.timestamp,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationUpdatedEvent &&
          runtimeType == other.runtimeType &&
          location == other.location &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(location, timestamp);

  @override
  String toString() =>
      'LocationUpdatedEvent(location: $location, timestamp: $timestamp)';
}

/// Event fired when location access fails
///
/// This event is published when the application encounters an error
/// while trying to obtain the user's location. This could be due to
/// permission issues, disabled location services, or technical problems.
///
/// Example usage:
/// ```dart
/// // Publishing
/// EventBus.instance.emit(LocationErrorEvent(
///   error: 'Location permission denied',
///   errorCode: 'PERMISSION_DENIED',
///   timestamp: DateTime.now(),
/// ));
///
/// // Listening
/// EventBus.instance.on<LocationErrorEvent>().listen((event) {
///   showLocationErrorDialog(event.error);
///   logLocationError(event.errorCode, event.timestamp);
/// });
/// ```
class LocationErrorEvent extends BaseEvent {
  /// Human-readable error message
  final String error;

  /// Error code for programmatic handling
  final String errorCode;

  /// When this error occurred
  final DateTime timestamp;

  /// Creates a LocationErrorEvent
  ///
  /// [error] - Human-readable error message
  /// [errorCode] - Error code for programmatic handling
  /// [timestamp] - When this error occurred
  const LocationErrorEvent({
    required this.error,
    required this.errorCode,
    required this.timestamp,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationErrorEvent &&
          runtimeType == other.runtimeType &&
          error == other.error &&
          errorCode == other.errorCode &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(error, errorCode, timestamp);

  @override
  String toString() =>
      'LocationErrorEvent(error: $error, errorCode: $errorCode, timestamp: $timestamp)';
}

/// Event fired when location permission status changes
///
/// This event is published when the user grants or denies location
/// permission, allowing the application to react accordingly.
///
/// Example usage:
/// ```dart
/// // Publishing
/// EventBus.instance.emit(LocationPermissionChangedEvent(
///   hasPermission: true,
///   timestamp: DateTime.now(),
/// ));
///
/// // Listening
/// EventBus.instance.on<LocationPermissionChangedEvent>().listen((event) {
///   if (event.hasPermission) {
///     startLocationUpdates();
///   } else {
///     showPermissionRequiredMessage();
///   }
/// });
/// ```
class LocationPermissionChangedEvent extends BaseEvent {
  /// Whether location permission is currently granted
  final bool hasPermission;

  /// When this permission change occurred
  final DateTime timestamp;

  /// Creates a LocationPermissionChangedEvent
  ///
  /// [hasPermission] - Whether location permission is currently granted
  /// [timestamp] - When this permission change occurred
  const LocationPermissionChangedEvent({
    required this.hasPermission,
    required this.timestamp,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationPermissionChangedEvent &&
          runtimeType == other.runtimeType &&
          hasPermission == other.hasPermission &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(hasPermission, timestamp);

  @override
  String toString() =>
      'LocationPermissionChangedEvent(hasPermission: $hasPermission, timestamp: $timestamp)';
}
