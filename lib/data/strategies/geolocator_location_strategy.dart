import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../../domain/strategies/location_strategy.dart';
import '../../domain/entities/location.dart';
import '../../core/types/result.dart';
import '../../core/exceptions/unified_exceptions_export.dart' as domain;

/// Production implementation of LocationStrategy using the Geolocator package
///
/// This strategy provides real GPS functionality by integrating with the
/// device's location services through the Geolocator package. It handles
/// all the complexity of permission management, service availability checks,
/// and GPS coordinate retrieval.
///
/// Features:
/// - Real GPS location access
/// - Permission handling (request/check)
/// - Service availability verification
/// - Configurable timeout and accuracy
/// - Proper error mapping to domain exceptions
///
/// Example usage:
/// ```dart
/// final strategy = GeolocatorLocationStrategy(
///   timeout: Duration(seconds: 30),
///   desiredAccuracy: LocationAccuracy.high,
/// );
///
/// final result = await strategy.getCurrentLocation();
/// ```
class GeolocatorLocationStrategy extends LocationStrategy {
  /// Timeout for location requests
  final Duration timeout;

  /// Desired accuracy for location requests
  final LocationAccuracy desiredAccuracy;

  /// Creates a GeolocatorLocationStrategy with optional configuration
  ///
  /// [timeout] - Maximum time to wait for location (default: 30 seconds)
  /// [desiredAccuracy] - GPS accuracy level (default: best available)
  GeolocatorLocationStrategy({
    this.timeout = const Duration(seconds: 30),
    this.desiredAccuracy = LocationAccuracy.best,
  });

  @override
  Future<Result<Location>> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      final serviceEnabledResult = await isLocationServiceEnabled();
      if (serviceEnabledResult is Failure<bool>) {
        return Failure(serviceEnabledResult.exception);
      }

      final isServiceEnabled = (serviceEnabledResult as Success<bool>).data;
      if (!isServiceEnabled) {
        return Failure(domain.LocationException(
          'Location services are disabled on this device',
          reason: domain.LocationExceptionReason.serviceDisabled,
        ));
      }

      // Check if we have permission
      final permissionResult = await hasLocationPermission();
      if (permissionResult is Failure<bool>) {
        return Failure(permissionResult.exception);
      }

      final hasPermission = (permissionResult as Success<bool>).data;
      if (!hasPermission) {
        return Failure(domain.LocationException(
          'Location permission is required to get current location',
          reason: domain.LocationExceptionReason.permissionDenied,
        ));
      }

      // Get the current position using modern settings
      final locationSettings = LocationSettings(
        accuracy: desiredAccuracy,
        timeLimit: timeout,
      );

      final position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      final location = Location(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
      );

      return Success(location);
    } on TimeoutException {
      return Failure(domain.LocationException(
        'Location request timed out after ${timeout.inSeconds} seconds',
        reason: domain.LocationExceptionReason.timeout,
      ));
    } on LocationServiceDisabledException {
      return Failure(domain.LocationException(
        'Location services are disabled',
        reason: domain.LocationExceptionReason.serviceDisabled,
      ));
    } on PermissionDeniedException {
      return Failure(domain.LocationException(
        'Location permission denied',
        reason: domain.LocationExceptionReason.permissionDenied,
      ));
    } on PositionUpdateException catch (e) {
      return Failure(domain.LocationException(
        'Failed to get location: ${e.message}',
        reason: domain.LocationExceptionReason.unknown,
      ));
    } catch (e) {
      return Failure(domain.LocationException(
        'Unexpected error getting location: ${e.toString()}',
        reason: domain.LocationExceptionReason.unknown,
      ));
    }
  }

  @override
  Future<Result<bool>> hasLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();

      switch (permission) {
        case LocationPermission.always:
        case LocationPermission.whileInUse:
          return const Success(true);
        case LocationPermission.denied:
        case LocationPermission.deniedForever:
        case LocationPermission.unableToDetermine:
          return const Success(false);
      }
    } catch (e) {
      return Failure(domain.LocationException(
        'Failed to check location permission: ${e.toString()}',
        reason: domain.LocationExceptionReason.unknown,
      ));
    }
  }

  @override
  Future<Result<bool>> requestLocationPermission() async {
    try {
      // First check current permission
      final currentPermission = await Geolocator.checkPermission();

      // If already granted, return success
      if (currentPermission == LocationPermission.always ||
          currentPermission == LocationPermission.whileInUse) {
        return const Success(true);
      }

      // If permanently denied, we can't request again
      if (currentPermission == LocationPermission.deniedForever) {
        return Failure(domain.LocationException(
          'Location permission permanently denied. Please enable in system settings.',
          reason: domain.LocationExceptionReason.permissionDenied,
        ));
      }

      // Request permission
      final permission = await Geolocator.requestPermission();

      switch (permission) {
        case LocationPermission.always:
        case LocationPermission.whileInUse:
          return const Success(true);
        case LocationPermission.denied:
          return const Success(false);
        case LocationPermission.deniedForever:
          return Failure(domain.LocationException(
            'Location permission permanently denied',
            reason: domain.LocationExceptionReason.permissionDenied,
          ));
        case LocationPermission.unableToDetermine:
          return Failure(domain.LocationException(
            'Unable to determine location permission status',
            reason: domain.LocationExceptionReason.unknown,
          ));
      }
    } catch (e) {
      return Failure(domain.LocationException(
        'Failed to request location permission: ${e.toString()}',
        reason: domain.LocationExceptionReason.unknown,
      ));
    }
  }

  @override
  Future<Result<bool>> isLocationServiceEnabled() async {
    try {
      final isEnabled = await Geolocator.isLocationServiceEnabled();
      return Success(isEnabled);
    } catch (e) {
      return Failure(domain.LocationException(
        'Failed to check if location service is enabled: ${e.toString()}',
        reason: domain.LocationExceptionReason.unknown,
      ));
    }
  }
}
