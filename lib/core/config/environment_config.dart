import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

  // テスト実行フラグ（テスト時に明示的に設定）
  static bool _isInTestContext = false;

  /// テスト用: 初期化状態をリセット
  @visibleForTesting
  static void resetForTesting() {
    _initialized = false;
    _isInTestContext = true; // テストコンテキストを明示的に設定
  }

  /// テスト用: テストコンテキストをクリア
  @visibleForTesting
  static void clearTestContext() {
    _isInTestContext = false;
  }

  /// 現在の環境を取得
  static Environment get current {
    // 通常の環境判定ロジック
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

    try {
      return Environment.values.firstWhere((e) => e.name == env);
    } catch (e) {
      // 無効な環境名の場合はdevelopmentをデフォルトとする
      return Environment.development;
    }
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

  /// 現在の環境が開発環境かどうか
  static bool get isDevelopment => current == Environment.development;

  /// 現在の環境がテスト環境かどうか
  static bool get isTest => current == Environment.test;

  /// 現在の環境がステージング環境かどうか
  static bool get isStaging => current == Environment.staging;

  /// 現在の環境が本番環境かどうか
  static bool get isProduction => current == Environment.production;

  /// .envファイルがassetsに存在するかチェック
  static Future<bool> _envFileExists(String fileName) async {
    try {
      await rootBundle.loadString(fileName);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 初期化（.envファイル読み込み - 動的チェック対応）
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // テスト環境では.env.testファイルを優先
      if (_isTestEnvironment() ||
          const bool.fromEnvironment('flutter.test', defaultValue: false) ||
          const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false)) {
        debugPrint('🧪 テスト環境での初期化を開始');

        // テスト中で既にdotenvが設定されている場合は、既存の設定を保持
        final hasExistingTestConfig =
            dotenv.env.isNotEmpty && dotenv.env.containsKey('FLUTTER_ENV');

        if (!hasExistingTestConfig) {
          // .env.testファイルの存在確認
          if (await _envFileExists('.env.test')) {
            debugPrint('🔧 .env.testファイルの読み込みを開始');
            await dotenv.load(fileName: '.env.test');
            debugPrint('✅ .env.testファイルの読み込み完了');
          } else {
            debugPrint('⚠️ .env.testファイルが存在しないため、テスト用設定で初期化');
            dotenv.testLoad(fileInput: '''
FLUTTER_ENV=test
HOTPEPPER_API_KEY=testdummyhotpepperkey123456789

''');
          }

          // テスト環境では、既存の FLUTTER_ENV 設定を尊重する
          // dotenv.testLoad() で明示的に設定されている場合はそれを優先
          if (dotenv.env['FLUTTER_ENV']?.isEmpty ?? true) {
            dotenv.env['FLUTTER_ENV'] = 'test';
          }
        } else {
          debugPrint('🔧 テスト中で既存の設定を保持: ${dotenv.env['FLUTTER_ENV']}');
        }
      } else {
        // 開発/本番環境では.envファイルをチェック
        debugPrint('🔧 .envファイルの存在確認中...');

        if (await _envFileExists('.env')) {
          debugPrint('✅ .envファイルが見つかりました。読み込み開始');
          await dotenv.load(fileName: '.env');
          debugPrint('✅ .envファイルの読み込み完了');

          debugPrint('📋 読み込まれた環境変数:');
          debugPrint('  FLUTTER_ENV: ${dotenv.env['FLUTTER_ENV']}');
          debugPrint(
              '  HOTPEPPER_API_KEY: ${dotenv.env['HOTPEPPER_API_KEY']?.isNotEmpty == true ? '設定済み(${dotenv.env['HOTPEPPER_API_KEY']?.length}文字)' : '未設定'}');
        } else {
          debugPrint('⚠️ .envファイルが存在しません。環境変数から直接取得します');
          // 環境変数から直接設定を行う
          dotenv.testLoad(fileInput: '''
FLUTTER_ENV=${const String.fromEnvironment('FLUTTER_ENV', defaultValue: 'development')}
HOTPEPPER_API_KEY=${const String.fromEnvironment('HOTPEPPER_API_KEY', defaultValue: '')}

''');
          debugPrint('✅ 環境変数からの設定完了');
        }
      }
    } catch (e) {
      debugPrint('❌ 初期化エラー: $e');

      // エラー時のフォールバック処理
      if (_isTestEnvironment() ||
          const bool.fromEnvironment('flutter.test', defaultValue: false) ||
          const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false)) {
        // テスト環境用フォールバック
        try {
          dotenv.testLoad(fileInput: '''
FLUTTER_ENV=test
HOTPEPPER_API_KEY=testdummyhotpepperkey123456789

''');
          debugPrint('🔄 テスト環境フォールバック初期化完了');
        } catch (fallbackError) {
          debugPrint('❌ フォールバック初期化も失敗: $fallbackError');
          dotenv.env['FLUTTER_ENV'] = 'test';
          dotenv.env['HOTPEPPER_API_KEY'] = 'testdummyhotpepperkey123456789';
        }
      } else {
        // 開発環境用フォールバック
        debugPrint('🔄 開発環境フォールバックで初期化します');
        dotenv.testLoad(fileInput: '''
FLUTTER_ENV=development
HOTPEPPER_API_KEY=${const String.fromEnvironment('HOTPEPPER_API_KEY', defaultValue: '')}

''');
      }
    }

    _initialized = true;
    debugPrint('🎯 EnvironmentConfig初期化完了: ${current.name}環境');
  }

  /// HotPepper API キーを取得（全環境共通）
  static String get hotpepperApiKey {
    // 初期化チェック
    if (!_initialized) {
      // テスト環境では環境変数から取得を試行
      if (_isTestEnvironment()) {
        return const String.fromEnvironment('HOTPEPPER_API_KEY',
            defaultValue: 'testdummyhotpepperkey123456789');
      }
      // 初期化されていない場合は環境変数からのみ取得
      return const String.fromEnvironment('HOTPEPPER_API_KEY',
          defaultValue: '');
    }

    try {
      // .envファイルから取得を試行
      final envKey = dotenv.env['HOTPEPPER_API_KEY'];
      if (envKey != null && envKey.isNotEmpty) {
        return envKey;
      }
    } catch (e) {
      // dotenvエラーの場合は環境変数にフォールバック
    }

    // 環境変数から取得（フォールバック）
    return const String.fromEnvironment('HOTPEPPER_API_KEY', defaultValue: '');
  }

  /// Google Maps API キーを取得（WebView実装により使用していません）
  @Deprecated('WebView地図実装によりGoogle Maps APIキーは不要です')
  static String get googleMapsApiKey {
    // WebView実装により不要だが、互換性のため空文字列を返す
    return '';
  }

  /// 実際に使用するHotPepper APIキーを取得
  static String get effectiveHotpepperApiKey => hotpepperApiKey;

  /// 実際に使用するGoogle Maps APIキーを取得（WebView実装により不要）
  @Deprecated('WebView地図実装によりGoogle Maps APIキーは不要です')
  static String get effectiveGoogleMapsApiKey => '';

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
