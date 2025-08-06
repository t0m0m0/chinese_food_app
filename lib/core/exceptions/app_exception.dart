import 'base_exception.dart';

/// Application exception class that extends BaseException
/// 
/// This class provides compatibility with existing code while
/// leveraging the new BaseException hierarchy.
/// 
/// Example usage:
/// ```dart
/// throw AppException('Failed to load data', severity: ExceptionSeverity.high);
/// ```
class AppException extends BaseException {
  /// Creates a new AppException with the given message and optional parameters
  ///
  /// [message] - Description of the error
  /// [severity] - Severity level (defaults to medium)
  /// [cause] - The underlying exception that caused this exception
  /// [stackTrace] - Stack trace when this exception was created
  AppException(
    super.message, {
    super.severity = ExceptionSeverity.medium,
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('AppException: $message');
    if (cause != null) {
      buffer.write('\nCaused by: $cause');
    }
    return buffer.toString();
  }
}
