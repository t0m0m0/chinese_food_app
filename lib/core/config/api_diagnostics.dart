import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:chinese_food_app/core/config/app_config.dart';
import 'package:chinese_food_app/core/config/security_config.dart';
import 'package:chinese_food_app/core/network/app_http_client.dart';

/// API接続テスト結果
class ApiConnectionTestResult {
  final String testType;
  final bool isSuccessful;
  final String? errorMessage;
  final Duration duration;
  final Map<String, dynamic> details;

  const ApiConnectionTestResult({
    required this.testType,
    required this.isSuccessful,
    this.errorMessage,
    required this.duration,
    this.details = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'testType': testType,
      'isSuccessful': isSuccessful,
      'errorMessage': errorMessage,
      'duration': duration.inMilliseconds,
      'details': details,
    };
  }

  @override
  String toString() {
    final status = isSuccessful ? '✅' : '❌';
    final error = errorMessage != null ? ' - $errorMessage' : '';
    return '$status $testType (${duration.inMilliseconds}ms)$error';
  }
}

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
///
/// API接続テスト機能（旧 ApiConnectionTester）も含む
class ApiDiagnostics {
  static ApiDiagnosticsResult? _cachedResult;
  static DateTime? _lastDiagnosticTime;
  static const Duration _cacheExpiry = Duration(minutes: 5);

  // HTTP クライアント（接続テスト用）
  static final _httpClient = AppHttpClient();

  // ============================================
  // 診断機能
  // ============================================

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

  // ============================================
  // 接続テスト機能 (旧 ApiConnectionTester)
  // ============================================

  /// 基本的な接続テスト
  static Future<ApiConnectionTestResult> testBasicConnectivity({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      developer.log('🔍 基本接続テストを開始', name: 'ApiDiagnostics');

      // DNS解決テスト（タイムアウト付き）
      final addresses = await InternetAddress.lookup('webservice.recruit.co.jp')
          .timeout(timeout);
      if (addresses.isEmpty) {
        throw Exception('DNS解決に失敗しました');
      }

      stopwatch.stop();

      return ApiConnectionTestResult(
        testType: 'basic_connectivity',
        isSuccessful: true,
        duration: stopwatch.elapsed,
        details: {
          'dns_resolved': true,
          'ip_addresses': addresses.map((a) => a.address).toList(),
        },
      );
    } on TimeoutException {
      stopwatch.stop();

      return ApiConnectionTestResult(
        testType: 'basic_connectivity',
        isSuccessful: false,
        errorMessage: 'DNS解決がタイムアウトしました (${timeout.inSeconds}秒)',
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();

      return ApiConnectionTestResult(
        testType: 'basic_connectivity',
        isSuccessful: false,
        errorMessage: e.toString(),
        duration: stopwatch.elapsed,
      );
    }
  }

  /// APIキー検証テスト
  static Future<ApiConnectionTestResult> testApiKeyValidation() async {
    final stopwatch = Stopwatch()..start();

    try {
      developer.log('🔍 APIキー検証テストを開始', name: 'ApiDiagnostics');

      // 初期化確認
      if (!AppConfig.isInitialized) {
        await AppConfig.initialize();
      }

      // APIキー取得試行
      final apiKey = await AppConfig.hotpepperApiKey;

      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('APIキーが設定されていません');
      }

      if (apiKey.length < 8) {
        throw Exception('APIキーの形式が不正です');
      }

      stopwatch.stop();

      return ApiConnectionTestResult(
        testType: 'api_key_validation',
        isSuccessful: true,
        duration: stopwatch.elapsed,
        details: {
          'api_key_length': apiKey.length,
          'api_key_prefix': apiKey.substring(0, 4),
        },
      );
    } catch (e) {
      stopwatch.stop();

      return ApiConnectionTestResult(
        testType: 'api_key_validation',
        isSuccessful: false,
        errorMessage: e.toString(),
        duration: stopwatch.elapsed,
      );
    }
  }

  /// 設定検証テスト
  static Future<ApiConnectionTestResult> testConfigValidation() async {
    final stopwatch = Stopwatch()..start();

    try {
      developer.log('🔍 設定検証テストを開始', name: 'ApiDiagnostics');

      final diagnostics = await getComprehensiveDiagnostics();

      if (!diagnostics.isConfigValid) {
        throw Exception('設定に問題があります: ${diagnostics.issues.join(', ')}');
      }

      stopwatch.stop();

      return ApiConnectionTestResult(
        testType: 'config_validation',
        isSuccessful: true,
        duration: stopwatch.elapsed,
        details: {
          'environment': diagnostics.environment,
          'security_mode': diagnostics.securityMode,
          'initialization_status': diagnostics.initializationStatus,
        },
      );
    } catch (e) {
      stopwatch.stop();

      return ApiConnectionTestResult(
        testType: 'config_validation',
        isSuccessful: false,
        errorMessage: e.toString(),
        duration: stopwatch.elapsed,
      );
    }
  }

  /// HotPepper API実際の通信テスト（オプション）
  static Future<ApiConnectionTestResult> testActualApiCall({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      developer.log('🔍 実際のAPI通信テストを開始', name: 'ApiDiagnostics');

      // 実際のAPIキーが設定されている場合のみテスト
      final apiKey = await AppConfig.hotpepperApiKey;
      if (apiKey == null || apiKey.isEmpty || apiKey.startsWith('test_')) {
        throw Exception('実際のAPIキーが必要です（テスト用キーは使用不可）');
      }

      // 最小限のリクエストでAPI接続テスト（タイムアウト付き）
      final url = 'https://webservice.recruit.co.jp/hotpepper/gourmet/v1/';
      final response = await _httpClient.get(
        url,
        queryParameters: {
          'key': apiKey,
          'format': 'json',
          'count': '1',
          'keyword': '中華',
        },
      ).timeout(timeout);

      final isSuccess = response.isSuccess;
      if (!isSuccess) {
        throw Exception('API呼び出しエラー: ${response.errorMessage}');
      }

      stopwatch.stop();

      return ApiConnectionTestResult(
        testType: 'actual_api_call',
        isSuccessful: true,
        duration: stopwatch.elapsed,
        details: {
          'response_received': true,
          'api_accessible': true,
        },
      );
    } on TimeoutException {
      stopwatch.stop();

      return ApiConnectionTestResult(
        testType: 'actual_api_call',
        isSuccessful: false,
        errorMessage: 'API呼び出しがタイムアウトしました (${timeout.inSeconds}秒)',
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();

      return ApiConnectionTestResult(
        testType: 'actual_api_call',
        isSuccessful: false,
        errorMessage: e.toString(),
        duration: stopwatch.elapsed,
      );
    }
  }

  /// 包括的なテスト実行
  static Future<List<ApiConnectionTestResult>> runComprehensiveTest({
    bool includeActualApiCall = false,
    Duration connectivityTimeout = const Duration(seconds: 10),
    Duration apiCallTimeout = const Duration(seconds: 15),
  }) async {
    developer.log('🔍 包括的API接続テストを開始', name: 'ApiDiagnostics');

    final results = <ApiConnectionTestResult>[];

    // 基本テスト
    results.add(await testBasicConnectivity(timeout: connectivityTimeout));
    results.add(await testApiKeyValidation());
    results.add(await testConfigValidation());

    // 実際のAPI呼び出しテスト（オプション）
    if (includeActualApiCall) {
      results.add(await testActualApiCall(timeout: apiCallTimeout));
    }

    final successCount = results.where((r) => r.isSuccessful).length;
    developer.log(
      '🔍 包括テスト完了: $successCount/${results.length} 成功',
      name: 'ApiDiagnostics',
    );

    return results;
  }

  /// テスト結果の詳細ログ出力
  static void logTestResults(List<ApiConnectionTestResult> results) {
    developer.log('📊 API接続テスト結果:', name: 'ApiDiagnostics');

    for (final result in results) {
      developer.log(result.toString(), name: 'ApiDiagnostics');
    }

    final successCount = results.where((r) => r.isSuccessful).length;
    final overall = successCount == results.length ? '✅ 全テスト成功' : '❌ 一部テスト失敗';

    developer.log('🎯 総合結果: $overall ($successCount/${results.length})',
        name: 'ApiDiagnostics');
  }
}

/// 後方互換性のためのエイリアス
///
/// @deprecated 代わりに [ApiDiagnostics] を直接使用してください。
/// このクラスは将来のバージョンで削除される予定です。
@Deprecated('Use ApiDiagnostics instead')
class ApiConnectionTester {
  /// 基本的な接続テスト
  static Future<ApiConnectionTestResult> testBasicConnectivity({
    Duration timeout = const Duration(seconds: 10),
  }) =>
      ApiDiagnostics.testBasicConnectivity(timeout: timeout);

  /// APIキー検証テスト
  static Future<ApiConnectionTestResult> testApiKeyValidation() =>
      ApiDiagnostics.testApiKeyValidation();

  /// 設定検証テスト
  static Future<ApiConnectionTestResult> testConfigValidation() =>
      ApiDiagnostics.testConfigValidation();

  /// HotPepper API実際の通信テスト
  static Future<ApiConnectionTestResult> testActualApiCall({
    Duration timeout = const Duration(seconds: 15),
  }) =>
      ApiDiagnostics.testActualApiCall(timeout: timeout);

  /// 包括的なテスト実行
  static Future<List<ApiConnectionTestResult>> runComprehensiveTest({
    bool includeActualApiCall = false,
    Duration connectivityTimeout = const Duration(seconds: 10),
    Duration apiCallTimeout = const Duration(seconds: 15),
  }) =>
      ApiDiagnostics.runComprehensiveTest(
        includeActualApiCall: includeActualApiCall,
        connectivityTimeout: connectivityTimeout,
        apiCallTimeout: apiCallTimeout,
      );

  /// テスト結果の詳細ログ出力
  static void logTestResults(List<ApiConnectionTestResult> results) =>
      ApiDiagnostics.logTestResults(results);
}
