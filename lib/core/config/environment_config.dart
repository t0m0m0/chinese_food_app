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

  /// HotPepper API キーを取得（全環境共通）
  static String get hotpepperApiKey {
    return const String.fromEnvironment(
      'HOTPEPPER_API_KEY',
      defaultValue: '',
    );
  }

  /// Google Maps API キーを取得（全環境共通）
  static String get googleMapsApiKey {
    return const String.fromEnvironment(
      'GOOGLE_MAPS_API_KEY',
      defaultValue: '',
    );
  }

  /// 実際に使用するHotPepper APIキーを取得
  static String get effectiveHotpepperApiKey => hotpepperApiKey;

  /// 実際に使用するGoogle Maps APIキーを取得
  static String get effectiveGoogleMapsApiKey => googleMapsApiKey;

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
