/// セキュリティ関連の基底例外クラス
class SecurityException implements Exception {
  /// エラーメッセージ
  final String message;

  /// エラーの追加コンテキスト情報
  final String? context;

  /// 元の例外（存在する場合）
  final Exception? originalException;

  const SecurityException(
    this.message, {
    this.context,
    this.originalException,
  });

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

  const APIKeyNotFoundException(
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

  const APIKeyAccessException(
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

  const SecureStorageException(
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
  const EnvironmentConfigException(
    String message, {
    String? context,
    Exception? originalException,
  }) : super(
          '環境設定エラー: $message',
          context: context,
          originalException: originalException,
        );
}
