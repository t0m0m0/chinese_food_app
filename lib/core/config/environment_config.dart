import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'environment_detector.dart';
import 'environment_initializer.dart';
import 'api_key_constants.dart';
import 'logging_config.dart';

/// アプリケーション環境の定義
enum Environment {
  /// 開発環境
  development,

  /// テスト環境
  test,

  /// ステージング環境
  staging,

  /// 本番環境
  production;

  /// 現在の環境名を取得
  String get name => toString().split('.').last;
}

/// 環境別設定管理クラス
class EnvironmentConfig {
  // 初期化フラグ
  static bool _initialized = false;

  /// テスト用: 初期化状態をリセット
  @visibleForTesting
  static void resetForTesting() {
    _initialized = false;
    EnvironmentDetector.setTestContext(); // テストコンテキストを明示的に設定
  }

  /// テスト用: テストコンテキストをクリア
  @visibleForTesting
  static void clearTestContext() {
    EnvironmentDetector.clearTestContext();
  }

  /// 現在の環境を取得
  static Environment get current {
    final env = EnvironmentDetector.detectEnvironment();

    try {
      return Environment.values.firstWhere((e) => e.name == env);
    } catch (e) {
      // 無効な環境名の場合はdevelopmentをデフォルトとする
      return Environment.development;
    }
  }

  /// 現在の環境が開発環境かどうか
  static bool get isDevelopment => current == Environment.development;

  /// 現在の環境がテスト環境かどうか
  static bool get isTest => current == Environment.test;

  /// 現在の環境がステージング環境かどうか
  static bool get isStaging => current == Environment.staging;

  /// 現在の環境が本番環境かどうか
  static bool get isProduction => current == Environment.production;

  /// 初期化（.envファイル読み込み - 動的チェック対応）
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // テスト環境の場合
      if (EnvironmentDetector.isTestEnvironment()) {
        await EnvironmentInitializer.initializeTestEnvironment();
      } else {
        // 開発/本番環境の場合
        await EnvironmentInitializer
            .initializeProductionOrDevelopmentEnvironment();
      }
    } catch (e) {
      LoggingConfig.errorLog('初期化エラー: $e');
      // エラー時のフォールバック処理
      await EnvironmentInitializer.initializeFallback();
    }

    _initialized = true;
    LoggingConfig.debugLog('EnvironmentConfig初期化完了: ${current.name}環境');
  }

  /// HotPepper API キーを取得（全環境共通）
  static String get hotpepperApiKey {
    // 初期化チェック
    if (!_initialized) {
      // テスト環境では環境変数から取得を試行
      if (EnvironmentDetector.isTestEnvironment()) {
        return const String.fromEnvironment(
            ApiKeyConstants.hotpepperApiKeyField,
            defaultValue: ApiKeyConstants.testDummyHotpepperApiKey);
      }
      // 初期化されていない場合は環境変数からのみ取得
      return const String.fromEnvironment(ApiKeyConstants.hotpepperApiKeyField,
          defaultValue: '');
    }

    try {
      // .envファイルから取得を試行
      final envKey = dotenv.env[ApiKeyConstants.hotpepperApiKeyField];
      if (envKey != null && envKey.isNotEmpty) {
        return envKey;
      }
    } catch (e) {
      // dotenvエラーの場合は環境変数にフォールバック
    }

    // 環境変数から取得（フォールバック）
    return const String.fromEnvironment(ApiKeyConstants.hotpepperApiKeyField,
        defaultValue: '');
  }

  /// 実際に使用するHotPepper APIキーを取得
  static String get effectiveHotpepperApiKey => hotpepperApiKey;

  /// 初期化されているかどうかを確認
  static bool get isInitialized => _initialized;

  /// HotPepper API のベースURL
  static String get hotpepperApiUrl {
    return 'https://webservice.recruit.co.jp/hotpepper/gourmet/v1/';
  }

  /// デバッグ情報を取得
  static Map<String, dynamic> get debugInfo {
    return {
      'environment': current.name,
      'hotpepperApiKey': effectiveHotpepperApiKey.isNotEmpty
          ? '${effectiveHotpepperApiKey.substring(0, 8)}...'
          : '(未設定)',
      'googleMapsApiKey': '(未使用：WebView実装)',
      'hotpepperApiUrl': hotpepperApiUrl,
    };
  }
}
