import '../base_exception.dart';

/// セキュリティ関連の基底例外クラス
class SecurityException extends BaseException {
  /// エラーの追加コンテキスト情報
  final String? context;

  /// 元の例外（存在する場合）
  final Exception? originalException;

  /// Creates a security exception
  ///
  /// [message] - Description of the security error
  /// [context] - Additional context information (optional)
  /// [originalException] - The original exception that caused this (optional)
  SecurityException(
    super.message, {
    this.context,
    this.originalException,
    super.cause,
    super.stackTrace,
  }) : super(severity: ExceptionSeverity.critical);

  @override
  String toString() {
    final buffer = StringBuffer('SecurityException: $message');
    if (context != null) {
      buffer.write(' (Context: $context)');
    }
    if (originalException != null) {
      buffer.write(' (Caused by: $originalException)');
    }
    return buffer.toString();
  }
}

/// APIキーが見つからない場合の例外
class APIKeyNotFoundException extends SecurityException {
  /// APIキーの種類
  final String keyType;

  /// Creates an API key not found exception
  ///
  /// [keyType] - The type/name of the API key
  /// [context] - Additional context information (optional)
  /// [originalException] - The original exception that caused this (optional)
  APIKeyNotFoundException(
    this.keyType, {
    String? context,
    Exception? originalException,
  }) : super(
          '$keyTypeのAPIキーが設定されていません',
          context: context,
          originalException: originalException,
        );
}

/// APIキーの取得に失敗した場合の例外
class APIKeyAccessException extends SecurityException {
  /// APIキーの種類
  final String keyType;

  /// Creates an API key access exception
  ///
  /// [keyType] - The type/name of the API key
  /// [message] - Description of the access error
  /// [context] - Additional context information (optional)
  /// [originalException] - The original exception that caused this (optional)
  APIKeyAccessException(
    this.keyType,
    String message, {
    String? context,
    Exception? originalException,
  }) : super(
          '$keyType: $message',
          context: context,
          originalException: originalException,
        );
}

/// セキュアストレージのアクセスエラー
class SecureStorageException extends SecurityException {
  /// 操作の種類（read, write, delete など）
  final String operation;

  /// Creates a secure storage exception
  ///
  /// [operation] - The type of operation (read, write, delete, etc.)
  /// [message] - Description of the error
  /// [context] - Additional context information (optional)
  /// [originalException] - The original exception that caused this (optional)
  SecureStorageException(
    this.operation,
    String message, {
    String? context,
    Exception? originalException,
  }) : super(
          'セキュアストレージ$operation エラー: $message',
          context: context,
          originalException: originalException,
        );
}

/// 環境設定関連のエラー
class EnvironmentConfigException extends SecurityException {
  /// Creates an environment configuration exception
  ///
  /// [message] - Description of the configuration error
  /// [context] - Additional context information (optional)
  /// [originalException] - The original exception that caused this (optional)
  EnvironmentConfigException(
    String message, {
    String? context,
    Exception? originalException,
  }) : super(
          '環境設定エラー: $message',
          context: context,
          originalException: originalException,
        );
}