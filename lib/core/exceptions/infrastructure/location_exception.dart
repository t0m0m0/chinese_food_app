import '../base_exception.dart';

/// Reasons for location-related exceptions
enum LocationExceptionReason {
  /// Location permission was denied by the user
  permissionDenied,

  /// Location services are disabled on the device
  serviceDisabled,

  /// Operation timed out
  timeout,

  /// Unknown or unspecified error
  unknown,
}

/// Exception thrown when location services encounter errors
class LocationException extends BaseException {
  /// The specific reason for the location error
  final LocationExceptionReason reason;

  /// Creates a location exception
  ///
  /// [message] - Description of the location error
  /// [reason] - Specific reason for the error
  LocationException(super.message,
      {this.reason = LocationExceptionReason.unknown})
      : super(severity: ExceptionSeverity.medium);

  @override
  String toString() => 'LocationException: $message (Reason: $reason)';
}