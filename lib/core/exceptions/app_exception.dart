/// Severity levels for application exceptions
enum ExceptionSeverity {
  /// Low impact - informational or minor issues
  low,

  /// Medium impact - normal errors that need attention
  medium,

  /// High impact - serious errors affecting functionality
  high,

  /// Critical impact - application-breaking errors
  critical
}

/// Base exception class for all application-specific exceptions
///
/// This class provides a unified structure for exception handling across
/// the application, including severity levels, timestamps, and consistent
/// error messaging.
///
/// Example usage:
/// ```dart
/// throw AppException('Failed to load data', severity: ExceptionSeverity.high);
/// ```
class AppException implements Exception {
  /// The error message describing what went wrong
  final String message;

  /// The severity level of this exception
  final ExceptionSeverity severity;

  /// When this exception was created
  final DateTime timestamp;

  /// Creates a new AppException with the given message and optional severity
  ///
  /// [message] - Description of the error
  /// [severity] - Severity level (defaults to medium)
  AppException(
    this.message, {
    this.severity = ExceptionSeverity.medium,
  }) : timestamp = DateTime.now();

  @override
  String toString() => 'AppException: $message';
}
