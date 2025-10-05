import 'dart:developer' as developer;
import 'package:chinese_food_app/core/config/app_config.dart';
import 'package:chinese_food_app/core/config/security_config.dart';

/// API設定の診断情報
class ApiDiagnosticsResult {
  final bool isConfigValid;
  final String hotpepperApiKeyStatus;
  final String initializationStatus;
  final String securityMode;
  final String environment;
  final DateTime timestamp;
  final List<String> issues;
  final List<String> suggestions;

  const ApiDiagnosticsResult({
    required this.isConfigValid,
    required this.hotpepperApiKeyStatus,
    required this.initializationStatus,
    required this.securityMode,
    required this.environment,
    required this.timestamp,
    required this.issues,
    required this.suggestions,
  });

  Map<String, dynamic> toJson() {
    return {
      'isConfigValid': isConfigValid,
      'hotpepperApiKeyStatus': hotpepperApiKeyStatus,
      'initializationStatus': initializationStatus,
      'securityMode': securityMode,
      'environment': environment,
      'timestamp': timestamp.toIso8601String(),
      'issues': issues,
      'suggestions': suggestions,
    };
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('🔍 API設定診断結果');
    buffer.writeln('時刻: ${timestamp.toIso8601String()}');
    buffer.writeln('環境: $environment');
    buffer.writeln('設定状態: ${isConfigValid ? "✅ 正常" : "❌ 問題あり"}');
    buffer.writeln('APIキー: $hotpepperApiKeyStatus');
    buffer.writeln('初期化: $initializationStatus');
    buffer.writeln('セキュリティ: $securityMode');

    if (issues.isNotEmpty) {
      buffer.writeln('\n❌ 問題:');
      for (final issue in issues) {
        buffer.writeln('  • $issue');
      }
    }

    if (suggestions.isNotEmpty) {
      buffer.writeln('\n💡 推奨対応:');
      for (final suggestion in suggestions) {
        buffer.writeln('  • $suggestion');
      }
    }

    return buffer.toString();
  }
}

/// API設定の診断ユーティリティ
class ApiDiagnostics {
  static ApiDiagnosticsResult? _cachedResult;
  static DateTime? _lastDiagnosticTime;
  static const Duration _cacheExpiry = Duration(minutes: 5);

  /// キャッシュされた結果が有効かどうかを確認
  static bool _isResultCached() {
    if (_cachedResult == null || _lastDiagnosticTime == null) {
      return false;
    }

    final now = DateTime.now();
    return now.difference(_lastDiagnosticTime!) < _cacheExpiry;
  }

  /// 包括的なAPI設定診断を実行
  static Future<ApiDiagnosticsResult> getComprehensiveDiagnostics({
    bool forceRefresh = false,
  }) async {
    // キャッシュされた結果があり、強制更新でない場合はキャッシュを返す
    if (!forceRefresh && _isResultCached()) {
      developer.log('🔍 キャッシュされた診断結果を使用', name: 'ApiDiagnostics');
      return _cachedResult!;
    }

    return await _performDiagnostics();
  }

  /// 実際の診断処理を実行
  static Future<ApiDiagnosticsResult> _performDiagnostics() async {
    developer.log('🔍 API設定診断を開始', name: 'ApiDiagnostics');

    final timestamp = DateTime.now();
    final issues = <String>[];
    final suggestions = <String>[];

    // 初期化状態チェック
    final initializationStatus = _checkInitializationStatus();
    if (initializationStatus != 'initialized') {
      issues.add('AppConfigが適切に初期化されていません');
      suggestions.add('main()でAppConfig.initialize()を呼び出してください');
    }

    // APIキー状態チェック
    final hotpepperApiKeyStatus = await _checkHotpepperApiKeyStatus();
    if (hotpepperApiKeyStatus == 'missing') {
      issues.add('HotPepper APIキーが設定されていません');
      suggestions.add('.envファイルにHOTPEPPER_API_KEY=your_key_here を設定してください');
    }

    // セキュリティ設定チェック
    final securityMode = _getSecurityMode();
    if (securityMode == 'secure' && hotpepperApiKeyStatus == 'available') {
      issues.add('セキュアモードでAPIキーが設定されています');
      suggestions.add('セキュアモードではプロキシサーバー経由を使用してください');
    }

    // 環境情報
    final environment = _getEnvironmentInfo();

    // 基本的な推奨事項を追加
    if (suggestions.isEmpty && issues.isEmpty) {
      suggestions.add('設定は正常です。定期的な診断実行を推奨します');
    }

    final isConfigValid = issues.isEmpty;

    final result = ApiDiagnosticsResult(
      isConfigValid: isConfigValid,
      hotpepperApiKeyStatus: hotpepperApiKeyStatus,
      initializationStatus: initializationStatus,
      securityMode: securityMode,
      environment: environment,
      timestamp: timestamp,
      issues: issues,
      suggestions: suggestions,
    );

    developer.log('🔍 診断完了: ${isConfigValid ? "正常" : "問題あり"}',
        name: 'ApiDiagnostics');

    // 結果をキャッシュ
    _cachedResult = result;
    _lastDiagnosticTime = DateTime.now();

    return result;
  }

  /// 初期化状態をチェック
  static String _checkInitializationStatus() {
    return AppConfig.isInitialized ? 'initialized' : 'not_initialized';
  }

  /// HotPepper APIキーの状態をチェック
  static Future<String> _checkHotpepperApiKeyStatus() async {
    try {
      // 初期化されていない場合は初期化を試行
      if (!AppConfig.isInitialized) {
        await AppConfig.initialize();
      }

      final apiKey = await AppConfig.hotpepperApiKey;
      if (apiKey == null || apiKey.isEmpty) {
        return 'missing';
      }

      // 最低限の妥当性チェック（長さなど）
      if (apiKey.length < 8) {
        return 'invalid';
      }

      return 'available';
    } catch (e) {
      developer.log('APIキー状態チェックエラー: $e', name: 'ApiDiagnostics');
      return 'error';
    }
  }

  /// セキュリティモードを取得
  static String _getSecurityMode() {
    if (SecurityConfig.isSecureMode) {
      return 'secure';
    } else if (SecurityConfig.isProxyMode) {
      return 'proxy';
    } else {
      return 'legacy';
    }
  }

  /// 環境情報を取得
  static String _getEnvironmentInfo() {
    if (AppConfig.isProduction) {
      return 'production';
    } else if (AppConfig.isDevelopment) {
      return 'development';
    } else {
      return 'unknown';
    }
  }

  /// 簡易診断（ログ出力付き）
  static Future<void> logDiagnostics({bool forceRefresh = false}) async {
    final diagnostics =
        await getComprehensiveDiagnostics(forceRefresh: forceRefresh);
    developer.log(diagnostics.toString(), name: 'ApiDiagnostics');
  }

  /// 診断キャッシュをクリア
  static void clearCache() {
    _cachedResult = null;
    _lastDiagnosticTime = null;
    developer.log('🔍 診断キャッシュをクリアしました', name: 'ApiDiagnostics');
  }
}
