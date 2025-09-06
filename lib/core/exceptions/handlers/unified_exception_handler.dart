import 'dart:developer' as developer;
import '../app_exception.dart';
import '../base_exception.dart';
import '../unified_network_exception.dart';
import '../unified_security_exception.dart';
import '../domain/validation_exception.dart';
import '../infrastructure/database_exception.dart';
import '../infrastructure/location_exception.dart';

/// Result wrapper for unified exception operations
class UnifiedExceptionResult<T> {
  /// Whether the operation was successful
  final bool isSuccess;

  /// The data returned by successful operations
  final T? data;

  /// The exception that occurred (if any)
  final BaseException? exception;

  /// User-friendly error message
  final String userMessage;

  /// Severity level of the exception
  final ExceptionSeverity? severity;

  const UnifiedExceptionResult._({
    required this.isSuccess,
    this.data,
    this.exception,
    this.userMessage = '',
    this.severity,
  });

  /// Creates a successful result with data
  factory UnifiedExceptionResult.success(T data) {
    return UnifiedExceptionResult._(
      isSuccess: true,
      data: data,
    );
  }

  /// Creates a failure result with exception and user message
  factory UnifiedExceptionResult.failure(BaseException exception, String userMessage) {
    return UnifiedExceptionResult._(
      isSuccess: false,
      exception: exception,
      userMessage: userMessage,
      severity: exception.severity,
    );
  }

  /// Whether the operation failed
  bool get isFailure => !isSuccess;
}

/// Logger interface for unified exception handling
abstract class UnifiedExceptionLogger {
  /// Log an exception with optional severity level
  void logException(Exception exception, {ExceptionSeverity? severity});
}

/// Default logger implementation using dart:developer
class DeveloperUnifiedExceptionLogger implements UnifiedExceptionLogger {
  @override
  void logException(Exception exception, {ExceptionSeverity? severity}) {
    final level = _getSeverityLevel(severity ?? ExceptionSeverity.medium);
    developer.log(
      exception.toString(),
      name: 'UnifiedExceptionHandler',
      level: level,
      error: exception,
    );
  }

  int _getSeverityLevel(ExceptionSeverity severity) {
    switch (severity) {
      case ExceptionSeverity.low:
        return 500; // INFO
      case ExceptionSeverity.medium:
        return 900; // WARNING
      case ExceptionSeverity.high:
        return 1000; // SEVERE
      case ExceptionSeverity.critical:
        return 1200; // SHOUT
    }
  }
}

/// Unified exception handler for the application
///
/// This class provides consolidated exception handling for all unified exceptions,
/// offering consistent logging, user message generation, and error processing
/// across the application.
///
/// Example usage:
/// ```dart
/// final handler = UnifiedExceptionHandler();
///
/// try {
///   final data = await riskyOperation();
///   return handler.success(data);
/// } catch (e) {
///   return handler.handle(e);
/// }
/// ```
class UnifiedExceptionHandler {
  final UnifiedExceptionLogger _logger;

  /// Creates a unified exception handler with optional custom logger
  UnifiedExceptionHandler({UnifiedExceptionLogger? logger})
      : _logger = logger ?? DeveloperUnifiedExceptionLogger();

  /// Handle any exception and return a formatted result
  UnifiedExceptionResult<T> handle<T>(Exception exception, [StackTrace? stackTrace]) {
    // Convert to BaseException if needed
    final BaseException baseException;
    if (exception is BaseException) {
      baseException = exception;
    } else {
      baseException = AppException(
        exception.toString(),
        severity: ExceptionSeverity.medium,
        cause: exception,
        stackTrace: stackTrace,
      );
    }

    // Log the exception
    _logger.logException(baseException, severity: baseException.severity);

    // Generate user-friendly message
    final userMessage = _getUserMessage(baseException);

    return UnifiedExceptionResult.failure(baseException, userMessage);
  }

  /// Create a successful result
  UnifiedExceptionResult<T> success<T>(T data) {
    return UnifiedExceptionResult.success(data);
  }

  /// Execute a function and handle any exceptions
  UnifiedExceptionResult<T> execute<T>(T Function() operation) {
    try {
      final result = operation();
      return success(result);
    } catch (e, stackTrace) {
      if (e is Exception) {
        return handle(e, stackTrace);
      } else {
        return handle(Exception(e.toString()), stackTrace);
      }
    }
  }

  /// Execute an async function and handle any exceptions
  Future<UnifiedExceptionResult<T>> executeAsync<T>(
      Future<T> Function() operation) async {
    try {
      final result = await operation();
      return success(result);
    } catch (e, stackTrace) {
      if (e is Exception) {
        return handle(e, stackTrace);
      } else {
        return handle(Exception(e.toString()), stackTrace);
      }
    }
  }

  /// Generate user-friendly error messages based on exception type
  String _getUserMessage(BaseException exception) {
    // Unified Network Exception handling
    if (exception is UnifiedNetworkException) {
      return 'ネットワークエラーが発生しました。しばらくしてからお試しください。';
    }

    // Unified Security Exception handling
    if (exception is UnifiedSecurityException) {
      return '認証エラーが発生しました。設定を確認してください。';
    }

    // Legacy exception handling for backward compatibility
    if (exception is ValidationException) {
      return '入力内容に誤りがあります。確認してください。';
    } else if (exception is DatabaseException) {
      return 'データの保存に失敗しました。';
    } else if (exception is LocationException) {
      switch (exception.reason) {
        case LocationExceptionReason.permissionDenied:
          return '位置情報の利用許可が必要です。';
        case LocationExceptionReason.serviceDisabled:
          return '位置情報サービスが無効になっています。';
        case LocationExceptionReason.timeout:
          return '位置情報の取得がタイムアウトしました。';
        default:
          return '位置情報の取得に失敗しました。';
      }
    } else {
      return '予期しないエラーが発生しました。';
    }
  }
}
