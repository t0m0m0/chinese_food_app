import 'package:flutter_dotenv/flutter_dotenv.dart';

/// アプリケーション環境の定義
enum Environment {
  /// 開発環境
  development,

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
    const env =
        String.fromEnvironment('FLUTTER_ENV', defaultValue: 'development');

    try {
      return Environment.values.firstWhere((e) => e.name == env);
    } catch (e) {
      // 無効な環境名の場合はdevelopmentをデフォルトとする
      return Environment.development;
    }
  }

  /// 現在の環境が開発環境かどうか
  static bool get isDevelopment => current == Environment.development;

  /// 現在の環境がステージング環境かどうか
  static bool get isStaging => current == Environment.staging;

  /// 現在の環境が本番環境かどうか
  static bool get isProduction => current == Environment.production;

  /// 初期化（.envファイル読み込み）
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // テスト環境では.env.testファイルを優先
      if (const bool.fromEnvironment('flutter.test', defaultValue: false) ||
          const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false)) {
        // テスト環境では既にTestEnvSetupで.env.testが読み込まれているため、
        // 再読み込みを避けてDotEnvの状態を保持
        if (dotenv.env.isNotEmpty) {
          _initialized = true;
          return;
        }
        // .env.testが読み込まれていない場合のみ読み込み
        await dotenv.load(fileName: '.env.test');
      } else {
        // 本番環境では.envファイルを読み込み
        await dotenv.load();
      }
    } catch (e) {
      // .envファイルが存在しない場合は無視
    }

    _initialized = true;
  }

  /// HotPepper API キーを取得（全環境共通）
  static String get hotpepperApiKey {
    // .envファイルから取得を試行
    final envKey = dotenv.env['HOTPEPPER_API_KEY'];
    if (envKey != null && envKey.isNotEmpty) {
      return envKey;
    }

    // 環境変数から取得（フォールバック）
    return const String.fromEnvironment('HOTPEPPER_API_KEY', defaultValue: '');
  }

  /// Google Maps API キーを取得（全環境共通）
  static String get googleMapsApiKey {
    // .envファイルから取得を試行
    final envKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (envKey != null && envKey.isNotEmpty) {
      return envKey;
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
