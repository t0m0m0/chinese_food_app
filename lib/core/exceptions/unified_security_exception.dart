import 'base_exception.dart';

/// Unified security exception that consolidates all security-related errors
///
/// This class replaces the original SecurityException and its subclasses
/// to provide consistent security error handling with factory constructors
/// for common security scenarios.
///
/// Example usage:
/// ```dart
/// // General security error
/// throw UnifiedSecurityException('Unauthorized access', context: 'API validation');
///
/// // API key not found
/// final apiKeyError = UnifiedSecurityException.apiKeyNotFound('HOTPEPPER_API_KEY');
///
/// // Secure storage error
/// final storageError = UnifiedSecurityException.secureStorage('read', 'Access denied');
/// ```
class UnifiedSecurityException extends BaseException {
  /// Additional context information about the security error
  final String? context;

  /// Creates a unified security exception
  ///
  /// [message] - Description of the security error
  /// [context] - Additional context information (optional)
  /// [cause] - The underlying exception that caused this exception
  /// [stackTrace] - Stack trace when this exception was created
  UnifiedSecurityException(
    super.message, {
    this.context,
    super.cause,
    super.stackTrace,
  }) : super(severity: ExceptionSeverity.critical);

  /// Factory constructor for API key not found errors
  factory UnifiedSecurityException.apiKeyNotFound(String keyType) {
    return UnifiedSecurityException(
      '$keyTypeのAPIキーが設定されていません',
    );
  }

  /// Factory constructor for API key access errors
  factory UnifiedSecurityException.apiKeyAccess(
    String keyType,
    String errorMessage, {
    String? context,
    Exception? cause,
    StackTrace? stackTrace,
  }) {
    return UnifiedSecurityException(
      '$keyType: $errorMessage',
      context: context,
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  /// Factory constructor for secure storage errors
  factory UnifiedSecurityException.secureStorage(
    String operation,
    String errorMessage, {
    String? context,
    Exception? cause,
    StackTrace? stackTrace,
  }) {
    return UnifiedSecurityException(
      'セキュアストレージ$operation エラー: $errorMessage',
      context: context,
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  /// Factory constructor for environment configuration errors
  factory UnifiedSecurityException.environmentConfig(
    String errorMessage, {
    String? context,
    Exception? cause,
    StackTrace? stackTrace,
  }) {
    return UnifiedSecurityException(
      '環境設定エラー: $errorMessage',
      context: context,
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer('UnifiedSecurityException: $message');
    if (context != null) {
      buffer.write(' (Context: $context)');
    }
    return buffer.toString();
  }
}
