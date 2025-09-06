import 'base_exception.dart';
import 'unified_exceptions.dart';

/// Unified network exception that handles both API and network errors
///
/// This class consolidates the functionality of both NetworkException and
/// ApiException to provide consistent network error handling throughout
/// the application.
///
/// Example usage:
/// ```dart
/// // HTTP error
/// throw UnifiedNetworkException(
///   'Not found',
///   statusCode: 404,
///   errorType: NetworkErrorType.httpError,
/// );
///
/// // API-specific error
/// final apiError = UnifiedNetworkException.api('Invalid parameters', statusCode: 400);
///
/// // Timeout error
/// final timeoutError = UnifiedNetworkException.timeout('Request timed out');
/// ```
class UnifiedNetworkException extends BaseException {
  /// HTTP status code (if available)
  final int? statusCode;

  /// Type of network error
  final NetworkErrorType errorType;

  /// Creates a unified network exception
  ///
  /// [message] - Description of the network error
  /// [statusCode] - HTTP status code (optional)
  /// [errorType] - Type of network error
  /// [cause] - The underlying exception that caused this exception
  /// [stackTrace] - Stack trace when this exception was created
  UnifiedNetworkException(
    super.message, {
    this.statusCode,
    this.errorType = NetworkErrorType.unknown,
    super.cause,
    super.stackTrace,
  }) : super(severity: _getSeverityForErrorType(errorType));

  /// Factory constructor for API-specific errors
  factory UnifiedNetworkException.api(
    String message, {
    int? statusCode,
    Exception? cause,
    StackTrace? stackTrace,
  }) {
    return UnifiedNetworkException(
      message,
      statusCode: statusCode,
      errorType: NetworkErrorType.apiError,
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  /// Factory constructor for timeout errors
  factory UnifiedNetworkException.timeout(
    String message, {
    Exception? cause,
    StackTrace? stackTrace,
  }) {
    return UnifiedNetworkException(
      message,
      errorType: NetworkErrorType.timeout,
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  /// Factory constructor for connection errors
  factory UnifiedNetworkException.connection(
    String message, {
    Exception? cause,
    StackTrace? stackTrace,
  }) {
    return UnifiedNetworkException(
      message,
      errorType: NetworkErrorType.connectionError,
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  /// Factory constructor for HTTP errors
  factory UnifiedNetworkException.http(
    String message, {
    required int statusCode,
    Exception? cause,
    StackTrace? stackTrace,
  }) {
    return UnifiedNetworkException(
      message,
      statusCode: statusCode,
      errorType: NetworkErrorType.httpError,
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  /// Determine severity based on error type
  static ExceptionSeverity _getSeverityForErrorType(
      NetworkErrorType errorType) {
    switch (errorType) {
      case NetworkErrorType.httpError:
      case NetworkErrorType.apiError:
        return ExceptionSeverity.high;
      case NetworkErrorType.timeout:
      case NetworkErrorType.connectionError:
        return ExceptionSeverity.medium;
      case NetworkErrorType.unknown:
        return ExceptionSeverity.medium;
    }
  }

  @override
  String toString() {
    final buffer = StringBuffer('UnifiedNetworkException: $message');

    if (statusCode != null) {
      buffer.write(' (Status: $statusCode');
      buffer.write(', Type: ${errorType.name})');
    } else {
      buffer.write(' (Type: ${errorType.name})');
    }

    return buffer.toString();
  }
}
