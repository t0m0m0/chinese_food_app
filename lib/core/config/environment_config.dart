import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
///
/// 環境検出、初期化、設定管理を統合的に行うクラス。
/// 旧 EnvironmentDetector, EnvironmentInitializer の機能を含む。
class EnvironmentConfig {
  // 初期化フラグ
  static bool _initialized = false;

  // テスト実行フラグ（テスト時に明示的に設定）
  static bool _isInTestContext = false;

  // ============================================
  // 環境検出機能 (旧 EnvironmentDetector)
  // ============================================

  /// テスト用: テストコンテキストを設定
  @visibleForTesting
  static void setTestContext() {
    _isInTestContext = true;
  }

  /// テスト用: テストコンテキストをクリア
  @visibleForTesting
  static void clearTestContext() {
    _isInTestContext = false;
  }

  /// テスト用: 初期化状態をリセット
  @visibleForTesting
  static void resetForTesting() {
    _initialized = false;
    setTestContext(); // テストコンテキストを明示的に設定
  }

  /// 現在の環境文字列を検出
  static String _detectEnvironment() {
    String env = 'development';

    try {
      // DotEnvが初期化されている場合は、DotEnvから環境を取得
      if (dotenv.env.isNotEmpty) {
        env = dotenv.env['FLUTTER_ENV'] ?? 'development';
      } else {
        // DotEnvが利用できない場合は、コンパイル時環境変数から取得
        env = const String.fromEnvironment('FLUTTER_ENV',
            defaultValue: 'development');
      }
    } catch (e) {
      // DotEnvが初期化されていない場合は、コンパイル時環境変数から取得
      env = const String.fromEnvironment('FLUTTER_ENV',
          defaultValue: 'development');
    }

    // テスト環境の場合でも、明示的に設定された環境を優先
    // ただし、明示的な環境設定がない場合のみテストをデフォルトにする
    if (_isTestEnvironment() && env == 'development') {
      env = 'test';
    }

    return env;
  }

  /// テスト環境かどうかを判定
  static bool _isTestEnvironment() {
    // テストコンテキストフラグが設定されている場合
    if (_isInTestContext) {
      return true;
    }

    // Flutter test環境の検出
    if (const bool.fromEnvironment('flutter.test', defaultValue: false) ||
        const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false)) {
      return true;
    }

    // kDebugMode でテスト環境の可能性をチェック
    if (kDebugMode) {
      // デバッグモードでスタックトレースからテスト実行を検出
      try {
        final stackTrace = StackTrace.current;
        if (stackTrace.toString().contains('flutter_test') ||
            stackTrace.toString().contains('test_api')) {
          return true;
        }
      } catch (e) {
        // スタックトレース取得に失敗した場合は無視
      }
    }

    // DotEnvからのテスト環境検出
    try {
      if (dotenv.env.isNotEmpty && dotenv.env['FLUTTER_ENV'] == 'test') {
        return true;
      }
    } catch (e) {
      // DotEnv未初期化の場合は無視
    }

    return false;
  }

  // ============================================
  // 環境初期化機能 (旧 EnvironmentInitializer)
  // ============================================

  /// .envファイルがassetsに存在するかチェック
  static Future<bool> _envFileExists(String fileName) async {
    try {
      await rootBundle.loadString(fileName);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// テスト環境の初期化
  static Future<void> _initializeTestEnvironment() async {
    LoggingConfig.debugLog('テスト環境での初期化を開始');

    // テスト中で既にdotenvが設定されている場合は、既存の設定を保持
    final hasExistingTestConfig =
        dotenv.env.isNotEmpty && dotenv.env.containsKey('FLUTTER_ENV');

    if (!hasExistingTestConfig) {
      // .env.testファイルの存在確認
      if (await _envFileExists('.env.test')) {
        LoggingConfig.debugLog('.env.testファイルの読み込みを開始');
        await dotenv.load(fileName: '.env.test');
        LoggingConfig.debugLog('.env.testファイルの読み込み完了');
      } else {
        LoggingConfig.warningLog('.env.testファイルが存在しないため、テスト用設定で初期化');
        await _loadTestDefaults();
      }

      // テスト環境では、既存の FLUTTER_ENV 設定を尊重する
      // dotenv.testLoad() で明示的に設定されている場合はそれを優先
      if (dotenv.env['FLUTTER_ENV']?.isEmpty ?? true) {
        dotenv.env['FLUTTER_ENV'] = 'test';
      }
    } else {
      LoggingConfig.debugLog('テスト中で既存の設定を保持: ${dotenv.env['FLUTTER_ENV']}');
    }
  }

  /// 本番・開発環境の初期化
  static Future<void> _initializeProductionOrDevelopmentEnvironment() async {
    LoggingConfig.debugLog('.envファイルの存在確認中...');

    if (await _envFileExists('.env')) {
      LoggingConfig.debugLog('.envファイルが見つかりました。読み込み開始');
      await dotenv.load(fileName: '.env');
      LoggingConfig.debugLog('.envファイルの読み込み完了');

      _logEnvironmentVariables();
    } else {
      LoggingConfig.warningLog('.envファイルが存在しません。環境変数から直接取得します');
      await _loadEnvironmentDefaults();
      LoggingConfig.debugLog('環境変数からの設定完了');
    }
  }

  /// エラー時のフォールバック初期化
  static Future<void> _initializeFallback() async {
    if (_isTestEnvironment()) {
      await _initializeTestFallback();
    } else {
      await _initializeDevelopmentFallback();
    }
  }

  /// テスト用デフォルト設定をロード
  static Future<void> _loadTestDefaults() async {
    dotenv.testLoad(fileInput: '''
FLUTTER_ENV=test
HOTPEPPER_API_KEY=testdummyhotpepperkey123456789

''');
  }

  /// 環境変数からのデフォルト設定をロード
  static Future<void> _loadEnvironmentDefaults() async {
    dotenv.testLoad(fileInput: '''
FLUTTER_ENV=${const String.fromEnvironment('FLUTTER_ENV', defaultValue: 'development')}
HOTPEPPER_API_KEY=${const String.fromEnvironment('HOTPEPPER_API_KEY', defaultValue: '')}

''');
  }

  /// 環境変数のログ出力
  static void _logEnvironmentVariables() {
    LoggingConfig.debugLog('読み込まれた環境変数:');
    LoggingConfig.debugLog('  FLUTTER_ENV: ${dotenv.env['FLUTTER_ENV']}');
    LoggingConfig.debugLog(
        '  HOTPEPPER_API_KEY: ${dotenv.env['HOTPEPPER_API_KEY']?.isNotEmpty == true ? '設定済み(${dotenv.env['HOTPEPPER_API_KEY']?.length}文字)' : '未設定'}');
  }

  /// テスト環境用フォールバック初期化
  static Future<void> _initializeTestFallback() async {
    try {
      await _loadTestDefaults();
      LoggingConfig.debugLog('テスト環境フォールバック初期化完了');
    } catch (fallbackError) {
      LoggingConfig.errorLog('フォールバック初期化も失敗: $fallbackError');
      dotenv.env['FLUTTER_ENV'] = 'test';
      dotenv.env['HOTPEPPER_API_KEY'] = 'testdummyhotpepperkey123456789';
    }
  }

  /// 開発環境用フォールバック初期化
  static Future<void> _initializeDevelopmentFallback() async {
    LoggingConfig.debugLog('開発環境フォールバックで初期化します');
    dotenv.testLoad(fileInput: '''
FLUTTER_ENV=development
HOTPEPPER_API_KEY=${const String.fromEnvironment('HOTPEPPER_API_KEY', defaultValue: '')}

''');
  }

  // ============================================
  // 公開API
  // ============================================

  /// 現在の環境を取得
  static Environment get current {
    final env = _detectEnvironment();

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
      if (_isTestEnvironment()) {
        await _initializeTestEnvironment();
      } else {
        // 開発/本番環境の場合
        await _initializeProductionOrDevelopmentEnvironment();
      }
    } catch (e) {
      LoggingConfig.errorLog('初期化エラー: $e');
      // エラー時のフォールバック処理
      await _initializeFallback();
    }

    _initialized = true;
    LoggingConfig.debugLog('EnvironmentConfig初期化完了: ${current.name}環境');
  }

  /// HotPepper API キーを取得（全環境共通）
  static String get hotpepperApiKey {
    // 初期化チェック
    if (!_initialized) {
      // テスト環境では環境変数から取得を試行
      if (_isTestEnvironment()) {
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

  /// Backend API のベースURL
  static String get backendApiUrl {
    try {
      final envUrl = dotenv.env['BACKEND_API_URL'];
      if (envUrl != null && envUrl.isNotEmpty) {
        return envUrl;
      }
    } catch (e) {
      // dotenvエラーの場合は環境変数にフォールバック
    }

    // 環境変数から取得（フォールバック）
    return const String.fromEnvironment('BACKEND_API_URL',
        defaultValue: 'https://api.chinese-food-app.com');
  }

  /// Backend API トークンを取得
  static String get backendApiToken {
    try {
      final envToken = dotenv.env['BACKEND_API_TOKEN'];
      if (envToken != null && envToken.isNotEmpty) {
        return envToken;
      }
    } catch (e) {
      // dotenvエラーの場合は環境変数にフォールバック
    }

    // 環境変数から取得（フォールバック）
    return const String.fromEnvironment('BACKEND_API_TOKEN', defaultValue: '');
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
      'backendApiUrl': backendApiUrl,
      'backendApiToken': backendApiToken.isNotEmpty
          ? '${backendApiToken.substring(0, 8)}...'
          : '(未設定)',
    };
  }
}

/// 後方互換性のためのエイリアス
///
/// @deprecated 代わりに [EnvironmentConfig] を直接使用してください。
/// このクラスは将来のバージョンで削除される予定です。
@Deprecated('Use EnvironmentConfig instead')
class EnvironmentDetector {
  /// テスト用: テストコンテキストを設定
  static void setTestContext() => EnvironmentConfig.setTestContext();

  /// テスト用: テストコンテキストをクリア
  static void clearTestContext() => EnvironmentConfig.clearTestContext();

  /// 現在の環境文字列を検出
  static String detectEnvironment() => EnvironmentConfig._detectEnvironment();

  /// テスト環境かどうかを判定
  static bool isTestEnvironment() => EnvironmentConfig._isTestEnvironment();

  /// 開発環境かどうかを判定
  static bool isDevelopmentEnvironment(String env) => env == 'development';

  /// 本番環境かどうかを判定
  static bool isProductionEnvironment(String env) => env == 'production';

  /// ステージング環境かどうかを判定
  static bool isStagingEnvironment(String env) => env == 'staging';

  /// テスト環境かどうかを判定（環境文字列から）
  static bool isTestEnvironmentFromString(String env) => env == 'test';
}

/// 後方互換性のためのエイリアス
///
/// @deprecated 代わりに [EnvironmentConfig] を直接使用してください。
/// このクラスは将来のバージョンで削除される予定です。
@Deprecated('Use EnvironmentConfig instead')
class EnvironmentInitializer {
  /// テスト環境の初期化
  static Future<void> initializeTestEnvironment() =>
      EnvironmentConfig._initializeTestEnvironment();

  /// 本番・開発環境の初期化
  static Future<void> initializeProductionOrDevelopmentEnvironment() =>
      EnvironmentConfig._initializeProductionOrDevelopmentEnvironment();

  /// エラー時のフォールバック初期化
  static Future<void> initializeFallback() =>
      EnvironmentConfig._initializeFallback();
}
