/// アプリケーション設定管理クラス
/// 
/// 環境変数やAPIキーなどの機密情報を安全に管理します。
/// 本番環境では適切な設定管理ツールの使用を推奨します。
class AppConfig {
  /// ホットペッパーAPIキー
  /// 
  /// 環境変数 HOTPEPPER_API_KEY から取得
  /// 設定されていない場合はnullを返す
  static String? get hotpepperApiKey {
    // TODO: 本番環境では flutter_dotenv や secure_storage を使用
    // 現在は開発用として const で定義
    return const String.fromEnvironment('HOTPEPPER_API_KEY');
  }

  /// Google Maps APIキー
  /// 
  /// 環境変数 GOOGLE_MAPS_API_KEY から取得
  /// 設定されていない場合はnullを返す
  static String? get googleMapsApiKey {
    return const String.fromEnvironment('GOOGLE_MAPS_API_KEY');
  }

  /// APIキーが設定されているかどうかをチェック
  static bool get hasHotpepperApiKey {
    final key = hotpepperApiKey;
    return key != null && key.isNotEmpty && key != 'YOUR_API_KEY_HERE';
  }

  /// Google Maps APIキーが設定されているかどうかをチェック
  static bool get hasGoogleMapsApiKey {
    final key = googleMapsApiKey;
    return key != null && key.isNotEmpty && key != 'YOUR_API_KEY_HERE';
  }

  /// 開発環境かどうかを判定
  static bool get isDevelopment {
    return const bool.fromEnvironment('DEVELOPMENT', defaultValue: true);
  }

  /// 本番環境かどうかを判定
  static bool get isProduction {
    return const bool.fromEnvironment('PRODUCTION', defaultValue: false);
  }

  /// デバッグ情報を表示
  static Map<String, dynamic> get debugInfo {
    return {
      'isDevelopment': isDevelopment,
      'isProduction': isProduction,
      'hasHotpepperApiKey': hasHotpepperApiKey,
      'hasGoogleMapsApiKey': hasGoogleMapsApiKey,
    };
  }
}