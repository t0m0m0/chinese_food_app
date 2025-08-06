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
/// throw BaseException('Failed to load data', severity: ExceptionSeverity.high);
/// ```
class BaseException implements Exception {
  /// The error message describing what went wrong
  final String message;

  /// The severity level of this exception
  final ExceptionSeverity severity;

  /// When this exception was created
  final DateTime timestamp;

  /// The underlying exception that caused this exception (optional)
  final Exception? cause;

  /// The stack trace when this exception was created (optional)
  final StackTrace? stackTrace;

  /// Creates a new BaseException with the given message and optional parameters
  ///
  /// [message] - Description of the error
  /// [severity] - Severity level (defaults to medium)
  /// [cause] - The underlying exception that caused this exception
  /// [stackTrace] - Stack trace when this exception was created
  BaseException(
    this.message, {
    this.severity = ExceptionSeverity.medium,
    this.cause,
    this.stackTrace,
  }) : timestamp = DateTime.now();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BaseException &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          severity == other.severity;

  @override
  int get hashCode => Object.hash(message, severity);

  @override
  String toString() {
    final buffer = StringBuffer('BaseException: $message');
    if (cause != null) {
      buffer.write('\nCaused by: $cause');
    }
    return buffer.toString();
  }
}