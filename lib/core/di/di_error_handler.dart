import 'dart:developer' as developer;
import '../constants/log_constants.dart';

/// Unified error handling for DI container operations
///
/// This class provides structured error handling and logging
/// for dependency injection container operations.
class DIErrorHandler {
  DIErrorHandler._(); // Private constructor to prevent instantiation

  /// Handle API configuration errors with detailed logging
  static void handleApiConfigurationError(
    String environment,
    String apiKeyStatus,
    Exception? error,
  ) {
    final errorMessage = error != null
        ? 'API設定エラー ($environment環境): $error'
        : 'API設定警告 ($environment環境): $apiKeyStatus';

    final logLevel = error != null ? LogConstants.error : LogConstants.warning;

    developer.log(
      errorMessage,
      name: 'DI-API',
      level: logLevel,
    );

    // Additional structured logging for debugging
    developer.log(
      '🔍 API設定詳細: 環境=$environment, キー状況=$apiKeyStatus',
      name: 'DI-Debug',
      level: LogConstants.info,
    );
  }

  /// Handle database connection errors with recovery suggestions
  static void handleDatabaseError(
    String platform,
    String operation,
    Exception error, {
    String? recoveryHint,
  }) {
    final errorMessage = 'データベースエラー ($platform): $operation - $error';

    developer.log(
      errorMessage,
      name: 'DI-Database',
      level: LogConstants.error,
    );

    if (recoveryHint != null) {
      developer.log(
        '💡 回復方法: $recoveryHint',
        name: 'DI-Recovery',
        level: LogConstants.info,
      );
    }

    // Log structured error details for debugging
    developer.log(
      '🔍 データベースエラー詳細: プラットフォーム=$platform, 操作=$operation',
      name: 'DI-Debug',
      level: LogConstants.info,
    );
  }

  /// Handle container configuration warnings
  static void handleConfigurationWarning(
    String containerType,
    String message, {
    String? recommendation,
  }) {
    developer.log(
      'DIコンテナ警告 ($containerType): $message',
      name: 'DI-Config',
      level: LogConstants.warning,
    );

    if (recommendation != null) {
      developer.log(
        '📝 推奨対応: $recommendation',
        name: 'DI-Recommendation',
        level: LogConstants.info,
      );
    }
  }

  /// Handle successful operations with appropriate logging
  static void logSuccessfulOperation(
    String operation,
    String details, {
    bool isVerbose = false,
  }) {
    final logLevel = isVerbose ? LogConstants.info : LogConstants.info;

    developer.log(
      '✅ $operation: $details',
      name: 'DI-Success',
      level: logLevel,
    );
  }

  /// Format error message for user-friendly display
  static String formatUserFriendlyError(
    String operation,
    Exception error,
  ) {
    // Extract meaningful error information
    final errorString = error.toString();

    if (errorString.contains('API')) {
      return 'API接続の設定に問題があります。設定を確認してください。';
    } else if (errorString.contains('Database') ||
        errorString.contains('SQLite')) {
      return 'データベース接続に問題があります。アプリを再起動してください。';
    } else if (errorString.contains('Network')) {
      return 'ネットワーク接続に問題があります。接続を確認してください。';
    } else {
      return '予期しないエラーが発生しました。($operation)';
    }
  }

  /// Validate environment configuration and log issues
  static bool validateEnvironmentConfiguration(String environment) {
    const validEnvironments = ['production', 'development', 'test'];

    if (!validEnvironments.contains(environment)) {
      handleConfigurationWarning(
        'Environment',
        '不明な環境設定: $environment',
        recommendation: '有効な環境: ${validEnvironments.join(', ')}',
      );
      return false;
    }

    logSuccessfulOperation(
      '環境検証',
      '環境設定が有効です: $environment',
      isVerbose: true,
    );
    return true;
  }
}
