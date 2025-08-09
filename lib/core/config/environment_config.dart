import 'package:flutter/foundation.dart';
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

  /// 現在の環境を取得
  static Environment get current {
    // テスト環境判定を最優先で実行
    if (_isTestEnvironment()) {
      return Environment.test;
    }

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

    try {
      return Environment.values.firstWhere((e) => e.name == env);
    } catch (e) {
      // 無効な環境名の場合はdevelopmentをデフォルトとする
      return Environment.development;
    }
  }

  /// テスト環境かどうかを判定
  static bool _isTestEnvironment() {
    // Flutter test環境の検出
    if (const bool.fromEnvironment('flutter.test', defaultValue: false) ||
        const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false)) {
      return true;
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

  /// 初期化（.envファイル読み込み）
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // テスト環境では.env.testファイルを優先
      if (_isTestEnvironment() ||
          const bool.fromEnvironment('flutter.test', defaultValue: false) ||
          const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false)) {
        // テスト環境では.env.testファイルを確実に読み込み
        if (dotenv.env.isEmpty || dotenv.env['FLUTTER_ENV'] != 'test') {
          await dotenv.load(fileName: '.env.test');
          // テスト環境であることを明示的に設定
          dotenv.env['FLUTTER_ENV'] = 'test';
        }
      } else {
        // 本番環境では.envファイルを読み込み
        debugPrint('🔧 .envファイルの読み込みを開始');
        await dotenv.load();
        debugPrint('✅ .envファイルの読み込み完了');
        debugPrint('📋 読み込まれた環境変数:');
        debugPrint('  FLUTTER_ENV: ${dotenv.env['FLUTTER_ENV']}');
        debugPrint(
            '  HOTPEPPER_API_KEY: ${dotenv.env['HOTPEPPER_API_KEY']?.isNotEmpty == true ? '設定済み(${dotenv.env['HOTPEPPER_API_KEY']?.length}文字)' : '未設定'}');
        debugPrint(
            '  GOOGLE_MAPS_API_KEY: ${dotenv.env['GOOGLE_MAPS_API_KEY']?.isNotEmpty == true ? '設定済み(${dotenv.env['GOOGLE_MAPS_API_KEY']?.length}文字)' : '未設定'}');
      }
    } catch (e) {
      debugPrint('❌ .envファイルの読み込みエラー: $e');
      // .envファイルが存在しない場合は無視
      // テスト環境の場合は最低限の設定を行う
      if (_isTestEnvironment() ||
          const bool.fromEnvironment('flutter.test', defaultValue: false) ||
          const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false)) {
        try {
          dotenv.testLoad(fileInput: 'FLUTTER_ENV=test');
        } catch (testLoadError) {
          // 最後の手段として環境変数のみ設定
          dotenv.env['FLUTTER_ENV'] = 'test';
        }
      }
    }

    _initialized = true;
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

  /// Google Maps API キーを取得（全環境共通）
  static String get googleMapsApiKey {
    // 初期化チェック
    if (!_initialized) {
      // テスト環境では環境変数から取得を試行
      if (_isTestEnvironment()) {
        return const String.fromEnvironment('GOOGLE_MAPS_API_KEY',
            defaultValue: 'AIzaSyTestDummyGoogleMapsKey12345678901');
      }
      // 初期化されていない場合は環境変数からのみ取得
      return const String.fromEnvironment('GOOGLE_MAPS_API_KEY',
          defaultValue: '');
    }

    try {
      // .envファイルから取得を試行
      final envKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
      if (envKey != null && envKey.isNotEmpty) {
        return envKey;
      }
    } catch (e) {
      // dotenvエラーの場合は環境変数にフォールバック
    }

    // 環境変数から取得（フォールバック）
    return const String.fromEnvironment('GOOGLE_MAPS_API_KEY',
        defaultValue: '');
  }

  /// 実際に使用するHotPepper APIキーを取得
  static String get effectiveHotpepperApiKey => hotpepperApiKey;

  /// 実際に使用するGoogle Maps APIキーを取得
  static String get effectiveGoogleMapsApiKey => googleMapsApiKey;

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
      'googleMapsApiKey': effectiveGoogleMapsApiKey.isNotEmpty
          ? '${effectiveGoogleMapsApiKey.substring(0, 8)}...'
          : '(未設定)',
      'hotpepperApiUrl': hotpepperApiUrl,
    };
  }
}
