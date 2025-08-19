/// セキュリティ設定管理
///
/// APIキー保護とプロキシサーバー関連の設定を管理
class SecurityConfig {
  /// プロキシサーバーの利用可能性
  ///
  /// プロキシサーバーが利用できない場合は
  /// 従来のAPI直接呼び出しにフォールバック
  static const bool proxyEnabled = bool.fromEnvironment(
    'PROXY_ENABLED',
    defaultValue: true,
  );

  /// プロキシサーバーのベースURL
  static const String proxyBaseUrl = String.fromEnvironment(
    'PROXY_BASE_URL',
    defaultValue: 'https://chinese-food-app-proxy.your-account.workers.dev',
  );

  /// APIキー除去フラグ
  ///
  /// trueの場合、APIキーに依存する処理を無効化し、
  /// プロキシサーバー経由でのみAPI呼び出しを行う
  static const bool apiKeysRemoved = bool.fromEnvironment(
    'API_KEYS_REMOVED',
    defaultValue: false,
  );

  /// セキュリティモードの設定
  ///
  /// - 'legacy': 従来のAPIキー管理（デフォルト）
  /// - 'proxy': プロキシサーバー経由のみ
  /// - 'secure': APIキー完全除去モード
  static const String securityMode = String.fromEnvironment(
    'SECURITY_MODE',
    defaultValue: 'legacy',
  );

  /// レガシーモード（従来のAPIキー管理）
  static bool get isLegacyMode => securityMode == 'legacy';

  /// プロキシモード（プロキシサーバー優先、フォールバック有り）
  static bool get isProxyMode => securityMode == 'proxy';

  /// セキュアモード（APIキー完全除去、プロキシのみ）
  static bool get isSecureMode => securityMode == 'secure';

  /// APIキーが必要かどうか
  static bool get requiresApiKeys => isLegacyMode && !apiKeysRemoved;

  /// プロキシサーバーが必須かどうか
  static bool get requiresProxy => isSecureMode || apiKeysRemoved;

  /// フォールバック機能が利用可能かどうか
  static bool get fallbackEnabled => !isSecureMode && !apiKeysRemoved;

  /// セキュリティ設定の詳細情報
  static Map<String, dynamic> get securityInfo => {
        'security_mode': securityMode,
        'proxy_enabled': proxyEnabled,
        'proxy_base_url': proxyBaseUrl,
        'api_keys_removed': apiKeysRemoved,
        'requires_api_keys': requiresApiKeys,
        'requires_proxy': requiresProxy,
        'fallback_enabled': fallbackEnabled,
      };

  /// セキュリティ設定の検証
  static List<String> validateSecurityConfig() {
    final errors = <String>[];

    // セキュアモードなのにプロキシが無効の場合
    if (isSecureMode && !proxyEnabled) {
      errors.add('セキュアモードではプロキシサーバーが必須です');
    }

    // プロキシベースURLが未設定の場合
    if (requiresProxy && proxyBaseUrl.isEmpty) {
      errors.add('プロキシサーバーのベースURLが設定されていません');
    }

    // 不正なセキュリティモードの場合
    if (!['legacy', 'proxy', 'secure'].contains(securityMode)) {
      errors.add('無効なセキュリティモード: $securityMode');
    }

    return errors;
  }
}
