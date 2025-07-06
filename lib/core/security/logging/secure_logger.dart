import 'dart:developer' as developer;
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// ログレベル
enum LogLevel {
  debug(0),
  info(800),
  warning(900),
  error(1000);

  const LogLevel(this.value);
  final int value;
}

/// セキュアロガー
///
/// 機密情報のログ出力を防止し、安全なログ記録を提供します。
class SecureLogger {
  /// 機密情報として扱うキーワードのパターン
  static final Set<RegExp> _sensitivePatterns = {
    // APIキー関連
    RegExp(r'api[_-]?key', caseSensitive: false),
    RegExp(r'access[_-]?token', caseSensitive: false),
    RegExp(r'secret', caseSensitive: false),
    RegExp(r'password', caseSensitive: false),
    RegExp(r'passwd', caseSensitive: false),
    RegExp(r'pwd', caseSensitive: false),

    // 認証関連
    RegExp(r'authorization', caseSensitive: false),
    RegExp(r'bearer', caseSensitive: false),
    RegExp(r'basic', caseSensitive: false),
    RegExp(r'session[_-]?id', caseSensitive: false),
    RegExp(r'cookie', caseSensitive: false),

    // 個人情報関連
    RegExp(r'email', caseSensitive: false),
    RegExp(r'phone', caseSensitive: false),
    RegExp(r'address', caseSensitive: false),
    RegExp(r'name', caseSensitive: false),
    RegExp(r'user[_-]?id', caseSensitive: false),

    // クレジットカード関連
    RegExp(r'card[_-]?number', caseSensitive: false),
    RegExp(r'cvv', caseSensitive: false),
    RegExp(r'expiry', caseSensitive: false),
  };

  /// 機密情報として扱う値のパターン
  static final Set<RegExp> _sensitiveValuePatterns = {
    // Base64エンコードされた長い文字列
    RegExp(r'^[A-Za-z0-9+/]{20,}={0,2}$'),

    // 長い英数字文字列（APIキーやトークンの可能性）
    RegExp(r'^[a-zA-Z0-9]{20,}$'),

    // JWTトークンのような形式
    RegExp(r'^[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+\.[A-Za-z0-9-_]*$'),

    // 16進数文字列（ハッシュ値など）
    RegExp(r'^[a-fA-F0-9]{32,}$'),
  };

  /// デバッグログ
  static void debug(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(
      LogLevel.debug,
      message,
      name: name,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  /// 情報ログ
  static void info(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(
      LogLevel.info,
      message,
      name: name,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  /// 警告ログ
  static void warning(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(
      LogLevel.warning,
      message,
      name: name,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  /// エラーログ
  static void error(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(
      LogLevel.error,
      message,
      name: name,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  /// 内部ログ記録メソッド
  static void _log(
    LogLevel level,
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    // メッセージから機密情報を除去
    final sanitizedMessage = _sanitizeMessage(message);

    // データから機密情報を除去
    Map<String, dynamic>? sanitizedData;
    if (data != null) {
      sanitizedData = _sanitizeData(data);
    }

    // エラーオブジェクトから機密情報を除去
    final sanitizedError = error != null ? _sanitizeError(error) : null;

    // 最終メッセージを構築
    final logMessage = _buildLogMessage(
      sanitizedMessage,
      sanitizedData,
      sanitizedError,
    );

    // dart:developerを使用してログ出力
    developer.log(
      logMessage,
      name: name ?? 'SecureApp',
      level: level.value,
      error: sanitizedError,
      stackTrace: stackTrace,
    );
  }

  /// メッセージから機密情報を除去
  static String _sanitizeMessage(String message) {
    String sanitized = message;

    // URL内のAPIキーやトークンを除去
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'([?&](?:api_key|token|key|secret)=)[^&\s]+',
          caseSensitive: false),
      (match) => '${match.group(1)}[REDACTED]',
    );

    // JSON文字列内の機密情報を除去
    sanitized = sanitized.replaceAllMapped(
      RegExp(
          r'"([^"]*(?:api_key|token|password|secret|key)[^"]*)"\s*:\s*"[^"]*"',
          caseSensitive: false),
      (match) => '"${match.group(1)}":"[REDACTED]"',
    );

    // 長い英数字文字列（APIキーやトークンの可能性）を除去
    for (final pattern in _sensitiveValuePatterns) {
      sanitized =
          sanitized.replaceAllMapped(pattern, (match) => '[REDACTED_TOKEN]');
    }

    return sanitized;
  }

  /// データマップから機密情報を除去
  static Map<String, dynamic> _sanitizeData(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};

    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;

      // キー名が機密情報を示すかチェック
      if (_isSensitiveKey(key)) {
        sanitized[key] = _redactValue(value);
      } else if (value is Map<String, dynamic>) {
        // ネストしたマップを再帰的に処理
        sanitized[key] = _sanitizeData(value);
      } else if (value is List) {
        // リストの要素を処理
        sanitized[key] = _sanitizeList(value);
      } else if (value is String && _isSensitiveValue(value)) {
        // 値自体が機密情報の可能性があるかチェック
        sanitized[key] = _redactValue(value);
      } else {
        sanitized[key] = value;
      }
    }

    return sanitized;
  }

  /// リストから機密情報を除去
  static List<dynamic> _sanitizeList(List<dynamic> list) {
    return list.map((item) {
      if (item is Map<String, dynamic>) {
        return _sanitizeData(item);
      } else if (item is List) {
        return _sanitizeList(item);
      } else if (item is String && _isSensitiveValue(item)) {
        return _redactValue(item);
      } else {
        return item;
      }
    }).toList();
  }

  /// エラーオブジェクトから機密情報を除去
  static Object _sanitizeError(Object error) {
    final errorString = error.toString();
    final sanitizedString = _sanitizeMessage(errorString);

    // 元のエラー型を保持しつつ、メッセージを置換
    if (error is Exception) {
      return Exception(sanitizedString);
    } else {
      return sanitizedString;
    }
  }

  /// キー名が機密情報を示すかチェック
  static bool _isSensitiveKey(String key) {
    return _sensitivePatterns.any((pattern) => pattern.hasMatch(key));
  }

  /// 値が機密情報の可能性があるかチェック
  static bool _isSensitiveValue(String value) {
    // 空文字や短い文字列は除外
    if (value.length < 10) return false;

    return _sensitiveValuePatterns.any((pattern) => pattern.hasMatch(value));
  }

  /// 値を編集する
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
    final middle = '*' * (middleLength > 10 ? 10 : middleLength);

    return '$start$middle$end';
  }

  /// ログメッセージを構築
  static String _buildLogMessage(
    String message,
    Map<String, dynamic>? data,
    Object? error,
  ) {
    final buffer = StringBuffer(message);

    if (data != null && data.isNotEmpty) {
      buffer.write(' | Data: ${jsonEncode(data)}');
    }

    if (error != null) {
      buffer.write(' | Error: $error');
    }

    return buffer.toString();
  }

  /// 機密情報パターンを追加
  static void addSensitivePattern(RegExp pattern) {
    _sensitivePatterns.add(pattern);
  }

  /// 機密情報値パターンを追加
  static void addSensitiveValuePattern(RegExp pattern) {
    _sensitiveValuePatterns.add(pattern);
  }

  /// ハッシュ化されたログID生成（デバッグ用）
  static String generateLogId(String content) {
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 8);
  }

  /// 本番環境でのログレベル制御
  static bool shouldLog(LogLevel level) {
    // 本番環境では警告以上のみログ出力
    const isProduction =
        bool.fromEnvironment('PRODUCTION', defaultValue: false);

    if (isProduction) {
      return level.value >= LogLevel.warning.value;
    }

    // 開発環境では全てのログを出力
    return true;
  }

  /// デバッグモードかどうかを判定
  static bool get isDebugMode {
    return const bool.fromEnvironment('DEBUG', defaultValue: true);
  }
}

/// セキュアロガーのミックスイン
///
/// クラスに簡単にセキュアログ機能を追加できます。
mixin SecureLogging {
  /// クラス名をログ名として使用
  String get loggerName => runtimeType.toString();

  /// デバッグログ
  void logDebug(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    SecureLogger.debug(
      message,
      name: loggerName,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  /// 情報ログ
  void logInfo(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    SecureLogger.info(
      message,
      name: loggerName,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  /// 警告ログ
  void logWarning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    SecureLogger.warning(
      message,
      name: loggerName,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  /// エラーログ
  void logError(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    SecureLogger.error(
      message,
      name: loggerName,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }
}
