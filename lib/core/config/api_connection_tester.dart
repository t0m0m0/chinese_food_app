import 'dart:developer' as developer;
import 'dart:io';
import 'package:chinese_food_app/core/config/app_config.dart';
import 'package:chinese_food_app/core/config/api_diagnostics.dart';
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

/// API接続テスト機能
class ApiConnectionTester {
  static final _httpClient = AppHttpClient();

  /// 基本的な接続テスト
  static Future<ApiConnectionTestResult> testBasicConnectivity() async {
    final stopwatch = Stopwatch()..start();

    try {
      developer.log('🔍 基本接続テストを開始', name: 'ApiConnectionTester');

      // DNS解決テスト
      final addresses =
          await InternetAddress.lookup('webservice.recruit.co.jp');
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
      developer.log('🔍 APIキー検証テストを開始', name: 'ApiConnectionTester');

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
      developer.log('🔍 設定検証テストを開始', name: 'ApiConnectionTester');

      final diagnostics = await ApiDiagnostics.getComprehensiveDiagnostics();

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
  static Future<ApiConnectionTestResult> testActualApiCall() async {
    final stopwatch = Stopwatch()..start();

    try {
      developer.log('🔍 実際のAPI通信テストを開始', name: 'ApiConnectionTester');

      // 実際のAPIキーが設定されている場合のみテスト
      final apiKey = await AppConfig.hotpepperApiKey;
      if (apiKey == null || apiKey.isEmpty || apiKey.startsWith('test_')) {
        throw Exception('実際のAPIキーが必要です（テスト用キーは使用不可）');
      }

      // 最小限のリクエストでAPI接続テスト
      final url = 'https://webservice.recruit.co.jp/hotpepper/gourmet/v1/';
      final response = await _httpClient.get(
        url,
        queryParameters: {
          'key': apiKey,
          'format': 'json',
          'count': '1',
          'keyword': '中華',
        },
      );

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
  }) async {
    developer.log('🔍 包括的API接続テストを開始', name: 'ApiConnectionTester');

    final results = <ApiConnectionTestResult>[];

    // 基本テスト
    results.add(await testBasicConnectivity());
    results.add(await testApiKeyValidation());
    results.add(await testConfigValidation());

    // 実際のAPI呼び出しテスト（オプション）
    if (includeActualApiCall) {
      results.add(await testActualApiCall());
    }

    final successCount = results.where((r) => r.isSuccessful).length;
    developer.log(
      '🔍 包括テスト完了: $successCount/${results.length} 成功',
      name: 'ApiConnectionTester',
    );

    return results;
  }

  /// テスト結果の詳細ログ出力
  static void logTestResults(List<ApiConnectionTestResult> results) {
    developer.log('📊 API接続テスト結果:', name: 'ApiConnectionTester');

    for (final result in results) {
      developer.log(result.toString(), name: 'ApiConnectionTester');
    }

    final successCount = results.where((r) => r.isSuccessful).length;
    final overall = successCount == results.length ? '✅ 全テスト成功' : '❌ 一部テスト失敗';

    developer.log('🎯 総合結果: $overall ($successCount/${results.length})',
        name: 'ApiConnectionTester');
  }
}
