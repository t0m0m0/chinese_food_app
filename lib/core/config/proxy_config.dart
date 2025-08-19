/// プロキシサーバー設定管理
///
/// APIキーセキュリティ強化のため、プロキシサーバー経由での
/// API呼び出しを管理するための設定クラス
class ProxyConfig {
  /// プロキシサーバーのベースURL
  ///
  /// 開発環境とプロダクション環境で異なるURLを使用
  static const String _devProxyUrl = 'http://localhost:8787';
  static const String _prodProxyUrl =
      'https://chinese-food-app-proxy.your-account.workers.dev';

  /// 現在の環境に応じたプロキシサーバーURL
  static String get baseUrl {
    // TODO: 環境変数またはConfigManagerから取得
    const String environment =
        String.fromEnvironment('FLUTTER_ENV', defaultValue: 'development');

    switch (environment) {
      case 'production':
        return _prodProxyUrl;
      case 'staging':
        return _prodProxyUrl; // ステージング環境も本番と同じプロキシを使用
      case 'development':
      case 'test':
      default:
        return _devProxyUrl;
    }
  }

  /// HotPepper API プロキシエンドポイント
  static String get hotpepperSearchUrl => '$baseUrl/api/hotpepper/search';

  /// Google Maps API プロキシエンドポイント（将来拡張用）
  static String get googleMapsUrl => '$baseUrl/api/google-maps';

  /// ヘルスチェックエンドポイント
  static String get healthCheckUrl => '$baseUrl/health';

  /// プロキシサーバーのタイムアウト設定（秒）
  static const int timeoutSeconds = 30;

  /// リトライ回数設定
  static const int retryCount = 2;

  /// プロキシサーバーが利用可能かどうかの設定
  ///
  /// falseの場合は従来のAPI直接呼び出しにフォールバック
  static const bool enabled = true;

  /// 共通リクエストヘッダー
  static Map<String, String> get commonHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'ChineseFoodApp/1.0',
      };

  /// 環境別設定情報
  static Map<String, dynamic> get environmentInfo => {
        'environment':
            const String.fromEnvironment('FLUTTER_ENV', defaultValue: 'development'),
        'proxy_url': baseUrl,
        'enabled': enabled,
        'timeout': timeoutSeconds,
        'retry_count': retryCount,
      };
}
