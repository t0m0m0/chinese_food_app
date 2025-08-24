import 'package:flutter/foundation.dart';
import 'environment_config.dart';

/// ログ出力制御クラス
class LoggingConfig {
  /// 環境別ログレベル設定
  static LogLevel get logLevel {
    switch (EnvironmentConfig.current) {
      case Environment.production:
        return LogLevel.error;
      case Environment.staging:
        return LogLevel.warning;
      case Environment.development:
        return LogLevel.debug;
      case Environment.test:
        return LogLevel.none; // テスト時はログを無効化
    }
  }

  /// ログ出力が有効かどうか
  static bool get isLoggingEnabled {
    return logLevel != LogLevel.none;
  }

  /// デバッグログ出力が有効かどうか
  static bool get isDebugLoggingEnabled {
    return logLevel == LogLevel.debug && kDebugMode;
  }

  /// 警告ログ出力が有効かどうか
  static bool get isWarningLoggingEnabled {
    final level = logLevel;
    return level == LogLevel.debug || level == LogLevel.warning;
  }

  /// エラーログ出力が有効かどうか
  static bool get isErrorLoggingEnabled {
    final level = logLevel;
    return level == LogLevel.debug ||
        level == LogLevel.warning ||
        level == LogLevel.error;
  }

  /// 条件付きデバッグログ出力
  static void debugLog(String message) {
    if (isDebugLoggingEnabled) {
      debugPrint('🔧 $message');
    }
  }

  /// 条件付き警告ログ出力
  static void warningLog(String message) {
    if (isWarningLoggingEnabled) {
      debugPrint('⚠️ $message');
    }
  }

  /// 条件付きエラーログ出力
  static void errorLog(String message) {
    if (isErrorLoggingEnabled) {
      debugPrint('❌ $message');
    }
  }

  /// 条件付き情報ログ出力
  static void infoLog(String message) {
    if (isDebugLoggingEnabled) {
      debugPrint('ℹ️ $message');
    }
  }
}

/// ログレベル定義
enum LogLevel {
  /// ログ出力なし
  none,

  /// エラーのみ
  error,

  /// 警告以上
  warning,

  /// デバッグ含む全て
  debug;
}
