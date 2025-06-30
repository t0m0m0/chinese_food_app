import 'app_exception.dart';

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

/// Exception thrown when input validation fails
class ValidationException extends AppException {
  /// The name of the field that failed validation (optional)
  final String? fieldName;

  /// Creates a validation exception
  ///
  /// [message] - Description of the validation error
  /// [fieldName] - Name of the field that failed validation (optional)
  ValidationException(super.message, {this.fieldName})
      : super(severity: ExceptionSeverity.medium);

  @override
  String toString() => fieldName != null
      ? 'ValidationException: $message (Field: $fieldName)'
      : 'ValidationException: $message';
}

/// Exception thrown when network operations fail
class NetworkException extends AppException {
  /// HTTP status code (if available)
  final int? statusCode;

  /// Creates a network exception
  ///
  /// [message] - Description of the network error
  /// [statusCode] - HTTP status code (optional)
  NetworkException(super.message, {this.statusCode})
      : super(severity: ExceptionSeverity.high);

  @override
  String toString() => statusCode != null
      ? 'NetworkException: $message (Status: $statusCode)'
      : 'NetworkException: $message';
}

/// Exception thrown when database operations fail
class DatabaseException extends AppException {
  /// The database operation that failed (e.g., 'INSERT', 'UPDATE')
  final String? operation;

  /// The table involved in the operation
  final String? table;

  /// Creates a database exception
  ///
  /// [message] - Description of the database error
  /// [operation] - Database operation (optional)
  /// [table] - Table name (optional)
  DatabaseException(super.message, {this.operation, this.table})
      : super(severity: ExceptionSeverity.critical);

  @override
  String toString() {
    final details = <String>[];
    if (operation != null) details.add('Operation: $operation');
    if (table != null) details.add('Table: $table');

    return details.isNotEmpty
        ? 'DatabaseException: $message (${details.join(', ')})'
        : 'DatabaseException: $message';
  }
}

/// Exception thrown when location services encounter errors
class LocationException extends AppException {
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

/// Exception thrown when API response processing fails
class ApiException extends AppException {
  /// HTTP status code from the API response
  final int? statusCode;

  /// Creates an API exception
  ///
  /// [message] - Description of the API error
  /// [statusCode] - HTTP status code (optional)
  ApiException(super.message, {this.statusCode})
      : super(severity: ExceptionSeverity.high);

  @override
  String toString() => statusCode != null
      ? 'ApiException: $message (Status: $statusCode)'
      : 'ApiException: $message';
}
