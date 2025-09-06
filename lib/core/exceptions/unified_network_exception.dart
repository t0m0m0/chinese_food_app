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

  /// Factory constructor for rate limit exceeded errors
  factory UnifiedNetworkException.rateLimitExceeded(
    String message, {
    int? statusCode,
    Exception? cause,
    StackTrace? stackTrace,
  }) {
    return UnifiedNetworkException(
      message,
      statusCode: statusCode,
      errorType: NetworkErrorType.rateLimitExceeded,
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  /// Factory constructor for maintenance/unavailable errors
  factory UnifiedNetworkException.maintenance(
    String message, {
    Exception? cause,
    StackTrace? stackTrace,
  }) {
    return UnifiedNetworkException(
      message,
      errorType: NetworkErrorType.maintenance,
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  /// Factory constructor for unauthorized errors
  factory UnifiedNetworkException.unauthorized(
    String message, {
    int? statusCode,
    Exception? cause,
    StackTrace? stackTrace,
  }) {
    return UnifiedNetworkException(
      message,
      statusCode: statusCode,
      errorType: NetworkErrorType.unauthorized,
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
      case NetworkErrorType.unauthorized:
      case NetworkErrorType.rateLimitExceeded:
        return ExceptionSeverity.high;
      case NetworkErrorType.certificateError:
      case NetworkErrorType.dnsError:
        return ExceptionSeverity.high;
      case NetworkErrorType.timeout:
      case NetworkErrorType.connectionError:
        return ExceptionSeverity.medium;
      case NetworkErrorType.maintenance:
        return ExceptionSeverity.medium;
      case NetworkErrorType.unknown:
        return ExceptionSeverity.medium;
    }
  }

  @override
  String toString() {
    final buffer = StringBuffer('ネットワークエラー: $message');

    if (statusCode != null) {
      buffer.write(' (ステータス: $statusCode');
      buffer.write(', 種別: ${_getErrorTypeDisplayName(errorType)})');
    } else {
      buffer.write(' (種別: ${_getErrorTypeDisplayName(errorType)})');
    }

    return buffer.toString();
  }

  /// Get display name for error type in Japanese
  String _getErrorTypeDisplayName(NetworkErrorType errorType) {
    switch (errorType) {
      case NetworkErrorType.httpError:
        return 'HTTP通信';
      case NetworkErrorType.apiError:
        return 'API処理';
      case NetworkErrorType.timeout:
        return 'タイムアウト';
      case NetworkErrorType.connectionError:
        return '接続';
      case NetworkErrorType.rateLimitExceeded:
        return '利用制限';
      case NetworkErrorType.maintenance:
        return 'メンテナンス';
      case NetworkErrorType.unauthorized:
        return '認証';
      case NetworkErrorType.certificateError:
        return '証明書';
      case NetworkErrorType.dnsError:
        return 'DNS';
      case NetworkErrorType.unknown:
        return '不明';
    }
  }
}
