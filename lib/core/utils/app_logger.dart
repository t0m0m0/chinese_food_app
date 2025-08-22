import 'dart:developer' as developer;

/// ログレベル
enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

/// アプリケーション全体で使用する構造化ログシステム
///
/// 本番環境での監視対応と適切なログレベル管理を提供します。
/// printログの代替として使用します。
class AppLogger {
  /// ログレベルの重要度マッピング
  static const Map<LogLevel, int> _levelPriority = {
    LogLevel.debug: 0,
    LogLevel.info: 1,
    LogLevel.warning: 2,
    LogLevel.error: 3,
    LogLevel.critical: 4,
  };

  /// 現在の最小ログレベル（これ以上のレベルのみ出力）
  static LogLevel _minLogLevel = LogLevel.debug;

  /// 最小ログレベルを設定
  static void setMinLogLevel(LogLevel level) {
    _minLogLevel = level;
  }

  /// デバッグログ
  static void debug(String message,
      {String? name, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.debug, message,
        name: name, error: error, stackTrace: stackTrace);
  }

  /// 情報ログ
  static void info(String message,
      {String? name, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.info, message,
        name: name, error: error, stackTrace: stackTrace);
  }

  /// 警告ログ
  static void warning(String message,
      {String? name, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.warning, message,
        name: name, error: error, stackTrace: stackTrace);
  }

  /// エラーログ
  static void error(String message,
      {String? name, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message,
        name: name, error: error, stackTrace: stackTrace);
  }

  /// 重要エラーログ
  static void critical(String message,
      {String? name, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.critical, message,
        name: name, error: error, stackTrace: stackTrace);
  }

  /// 内部ログ出力メソッド
  static void _log(
    LogLevel level,
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // 最小ログレベルチェック
    if (_levelPriority[level]! < _levelPriority[_minLogLevel]!) {
      return;
    }

    // 構造化ログメッセージを構築
    final logData = _buildLogData(level, message, name, error, stackTrace);

    // developer.logを使用して構造化ログを出力
    developer.log(
      logData['message'] as String,
      name: logData['name'] as String,
      level: _levelPriority[level]! * 100, // Dartのログレベルに変換
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// 構造化ログデータを構築
  static Map<String, dynamic> _buildLogData(
    LogLevel level,
    String message,
    String? name,
    Object? error,
    StackTrace? stackTrace,
  ) {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'level': level.name.toUpperCase(),
      'message': message,
      'name': name ?? 'App',
      'error': error?.toString(),
      'hasError': error != null,
      'hasStackTrace': stackTrace != null,
    };
  }

  /// プロキシサーバー関連のログ（専用メソッド）
  static void proxyError(String message,
      {Object? error, StackTrace? stackTrace}) {
    _log(
      LogLevel.error,
      'プロキシサーバーエラー: $message',
      name: 'ProxyServer',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// プロキシサーバーフォールバック通知
  static void proxyFallback(String reason, {Object? originalError}) {
    _log(
      LogLevel.warning,
      'フォールバックモードに切り替え: $reason',
      name: 'ProxyServer',
      error: originalError,
    );
  }

  /// API関連のログ
  static void apiInfo(String message, {String? apiName}) {
    _log(
      LogLevel.info,
      message,
      name: apiName ?? 'API',
    );
  }

  /// API エラーログ
  static void apiError(String message,
      {String? apiName, Object? error, StackTrace? stackTrace}) {
    _log(
      LogLevel.error,
      message,
      name: apiName ?? 'API',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
