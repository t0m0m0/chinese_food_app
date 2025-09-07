import 'dart:developer' as developer;

/// アプリケーション環境の種類
enum AppEnvironment {
  development,
  test,
  staging,
  production,
}

/// ログレベル設定
class SecurityLoggingConfig {
  static AppEnvironment? _currentEnvironment;
  static Map<AppEnvironment, int>? _logLevelConfig;

  /// 現在の環境を設定
  static void initialize({AppEnvironment? environment}) {
    _currentEnvironment = environment ?? _detectEnvironment();
    _logLevelConfig = _getDefaultLogLevels();

    developer.log(
      'SecurityLogging initialized for environment: ${_currentEnvironment!.name}',
      name: 'SecurityConfig',
    );
  }

  /// 現在の環境を取得
  static AppEnvironment get currentEnvironment {
    return _currentEnvironment ?? _detectEnvironment();
  }

  /// 指定されたレベルでログ出力すべきかを判定
  static bool shouldLog(int logLevel) {
    final environment = currentEnvironment;
    final minimumLevel = _logLevelConfig?[environment] ??
        _getDefaultMinimumLogLevel(environment);

    return logLevel >= minimumLevel;
  }

  /// 環境に応じたログレベルを取得
  static int getEnvironmentLogLevel() {
    final environment = currentEnvironment;
    return _logLevelConfig?[environment] ??
        _getDefaultMinimumLogLevel(environment);
  }

  /// 本番環境で安全なデバッグモード判定
  static bool isProductionSafeDebugMode() {
    final environment = currentEnvironment;

    if (environment == AppEnvironment.production) {
      // 本番環境では明示的にDEBUG=trueが設定された場合のみtrue
      return const bool.fromEnvironment('DEBUG', defaultValue: false);
    } else {
      // 開発・テスト環境では現在の動作を維持
      return const bool.fromEnvironment('DEBUG', defaultValue: true);
    }
  }

  /// 環境別デバッグ設定を取得
  static Map<String, dynamic> getEnvironmentDebugConfig() {
    final environment = currentEnvironment;

    return {
      'environment': environment.name,
      'debug_enabled': isProductionSafeDebugMode(),
      'log_level': getEnvironmentLogLevel(),
      'security_logging': shouldLog(900), // WARNING以上
      'detailed_errors': environment != AppEnvironment.production,
      'sensitive_data_logging': environment == AppEnvironment.development,
    };
  }

  /// 本番環境向けセキュアログ設定を取得
  static Map<String, dynamic> getProductionSecureConfig() {
    return {
      'log_level': 1000, // ERROR以上のみ
      'sensitive_data_redaction': true,
      'detailed_stack_traces': false,
      'error_aggregation': true,
      'performance_monitoring': true,
      'security_events_only': true,
      'max_log_retention_days': 7,
    };
  }

  /// 環境を自動検出
  static AppEnvironment _detectEnvironment() {
    // 環境変数から判定
    const envString =
        String.fromEnvironment('FLUTTER_ENV', defaultValue: 'development');

    switch (envString.toLowerCase()) {
      case 'production':
      case 'prod':
        return AppEnvironment.production;
      case 'staging':
      case 'stage':
        return AppEnvironment.staging;
      case 'test':
      case 'testing':
        return AppEnvironment.test;
      case 'development':
      case 'dev':
      default:
        return AppEnvironment.development;
    }
  }

  /// デフォルトのログレベル設定を取得
  static Map<AppEnvironment, int> _getDefaultLogLevels() {
    return {
      AppEnvironment.development: 800, // INFO以上
      AppEnvironment.test: 900, // WARNING以上
      AppEnvironment.staging: 900, // WARNING以上
      AppEnvironment.production: 1000, // ERROR以上
    };
  }

  /// 環境に応じたデフォルト最小ログレベルを取得
  static int _getDefaultMinimumLogLevel(AppEnvironment environment) {
    switch (environment) {
      case AppEnvironment.development:
        return 800; // INFO
      case AppEnvironment.test:
      case AppEnvironment.staging:
        return 900; // WARNING
      case AppEnvironment.production:
        return 1000; // ERROR
    }
  }

  /// セキュリティイベント専用ログ
  static void logSecurityEvent(
    String event,
    String details, {
    Map<String, dynamic>? metadata,
  }) {
    if (!shouldLog(1000)) return; // ERROR レベル

    final sanitizedMetadata = _sanitizeSecurityMetadata(metadata);

    developer.log(
      'SECURITY_EVENT: $event - $details',
      name: 'SecurityEvent',
      level: 1000,
    );

    if (sanitizedMetadata.isNotEmpty) {
      developer.log(
        'Security event metadata: $sanitizedMetadata',
        name: 'SecurityEvent',
        level: 1000,
      );
    }
  }

  /// セキュリティメタデータのサニタイズ
  static Map<String, dynamic> _sanitizeSecurityMetadata(
      Map<String, dynamic>? metadata) {
    if (metadata == null) return {};

    final sanitized = <String, dynamic>{};
    final environment = currentEnvironment;

    for (final entry in metadata.entries) {
      final key = entry.key.toLowerCase();
      final value = entry.value;

      // 本番環境では機密データを完全に除外
      if (environment == AppEnvironment.production &&
          _isSensitiveSecurityKey(key)) {
        sanitized[entry.key] = '[REDACTED_PROD]';
      } else if (_isSensitiveSecurityKey(key)) {
        // 開発環境でも一部マスキング
        sanitized[entry.key] = _maskSecurityValue(value);
      } else {
        sanitized[entry.key] = value;
      }
    }

    return sanitized;
  }

  /// セキュリティ関連の機密キーかどうかを判定
  static bool _isSensitiveSecurityKey(String key) {
    const sensitiveKeys = [
      'token',
      'key',
      'password',
      'secret',
      'auth',
      'credential',
      'session',
      'cookie',
      'bearer'
    ];

    return sensitiveKeys.any((sensitiveKey) => key.contains(sensitiveKey));
  }

  /// セキュリティ値のマスキング
  static String _maskSecurityValue(dynamic value) {
    if (value == null) return '[NULL]';

    final stringValue = value.toString();
    if (stringValue.length <= 4) return '[MASKED]';

    return '${stringValue.substring(0, 2)}***${stringValue.substring(stringValue.length - 2)}';
  }
}
