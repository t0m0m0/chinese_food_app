import 'dart:developer' as developer;
import '../exceptions/infrastructure/security_exception.dart';
import 'security_logging_config.dart';

/// セキュリティエラーの重要度
enum SecurityErrorSeverity {
  /// 警告レベル - ログ出力のみ、処理継続
  warning,

  /// エラーレベル - ログ出力、例外をスロー
  error,

  /// クリティカルレベル - ログ出力、即座に例外をスロー
  critical,
}

/// セキュリティエラーハンドリングの統一化クラス
class SecurityErrorHandler {
  /// セキュリティエラーを統一的に処理
  static void handleSecurityError(
    String operation,
    dynamic error,
    SecurityErrorSeverity severity, {
    String? context,
    Map<String, dynamic>? additionalData,
  }) {
    // 環境別ログレベル制御
    final logLevel = _getLogLevel(severity);
    if (!SecurityLoggingConfig.shouldLog(logLevel)) {
      // ログレベルが環境設定を満たさない場合はスキップ
      // ただし、例外は重要度に応じてスローする
      _handleExceptionOnly(severity, operation, error, context);
      return;
    }

    // ログ出力（環境設定に応じて実行）
    final errorMessage = 'Security operation failed: $operation';
    final sanitizedData = _sanitizeLogData(additionalData);

    developer.log(
      errorMessage,
      error: error,
      name: 'Security',
      level: logLevel,
    );

    if (sanitizedData.isNotEmpty) {
      developer.log(
        'Additional context: $sanitizedData',
        name: 'Security',
        level: logLevel,
      );
    }

    // 重要度に応じた処理
    switch (severity) {
      case SecurityErrorSeverity.warning:
        // 警告レベル：ログのみ、処理継続
        break;

      case SecurityErrorSeverity.error:
      case SecurityErrorSeverity.critical:
        // エラー・クリティカルレベル：例外をスロー
        throw SecurityException(
          'Security error in $operation${context != null ? ' ($context)' : ''}',
          context: context ?? operation,
          originalException:
              error is Exception ? error : Exception(error.toString()),
        );
    }
  }

  /// セキュリティエラーを安全にログ出力（例外をスローしない）
  static void logSecurityWarning(
    String operation,
    dynamic error, {
    String? context,
    Map<String, dynamic>? additionalData,
  }) {
    try {
      handleSecurityError(
        operation,
        error,
        SecurityErrorSeverity.warning,
        context: context,
        additionalData: additionalData,
      );
    } catch (e) {
      // ログ処理自体でエラーが発生した場合は、最低限の出力のみ
      developer.log('Failed to log security warning: $e', name: 'Security');
    }
  }

  /// ログレベルの取得
  static int _getLogLevel(SecurityErrorSeverity severity) {
    switch (severity) {
      case SecurityErrorSeverity.warning:
        return 900; // WARNING
      case SecurityErrorSeverity.error:
        return 1000; // ERROR
      case SecurityErrorSeverity.critical:
        return 1200; // SEVERE
    }
  }

  /// 例外処理のみを実行（ログ出力なし）
  static void _handleExceptionOnly(
    SecurityErrorSeverity severity,
    String operation,
    dynamic error,
    String? context,
  ) {
    switch (severity) {
      case SecurityErrorSeverity.warning:
        // 警告レベル：何もしない
        break;

      case SecurityErrorSeverity.error:
      case SecurityErrorSeverity.critical:
        // エラー・クリティカルレベル：例外をスロー
        throw SecurityException(
          'Security error in $operation${context != null ? ' ($context)' : ''}',
          context: context ?? operation,
          originalException:
              error is Exception ? error : Exception(error.toString()),
        );
    }
  }

  /// ログデータから機密情報を除去
  static Map<String, dynamic> _sanitizeLogData(Map<String, dynamic>? data) {
    if (data == null) return {};

    final sanitized = <String, dynamic>{};

    for (final entry in data.entries) {
      final key = entry.key.toLowerCase();
      final value = entry.value;

      // 機密情報キーワードのチェック
      if (_isSensitiveKey(key)) {
        sanitized[entry.key] = _redactValue(value);
      } else if (value is Map<String, dynamic>) {
        sanitized[entry.key] = _sanitizeLogData(value);
      } else {
        sanitized[entry.key] = value;
      }
    }

    return sanitized;
  }

  /// 機密情報キーかどうかを判定
  static bool _isSensitiveKey(String key) {
    const sensitiveKeywords = [
      'api_key',
      'apikey',
      'token',
      'secret',
      'password',
      'passwd',
      'pwd',
      'key',
      'auth',
      'credential'
    ];

    return sensitiveKeywords.any((keyword) => key.contains(keyword));
  }

  /// 値を編集
  static String _redactValue(dynamic value) {
    if (value == null) return '[NULL]';

    final stringValue = value.toString();
    if (stringValue.length <= 4) {
      return '[REDACTED]';
    }

    // 最初の2文字と最後の2文字を表示、中間を*で隠す
    final start = stringValue.substring(0, 2);
    final end = stringValue.substring(stringValue.length - 2);
    final middleLength = stringValue.length - 4;
    final middle = '*' * (middleLength > 8 ? 8 : middleLength);

    return '$start$middle$end';
  }
}
