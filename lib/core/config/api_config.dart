/// API関連の設定を管理するクラス
class ApiConfig {
  /// HotPepper API設定
  static const String hotpepperApiUrl =
      'https://webservice.recruit.co.jp/hotpepper/gourmet/v1/';
  static const int hotpepperApiTimeout = 10; // 秒
  static const int hotpepperApiRetryCount = 3;
  static const int hotpepperMaxResults = 100;
  static const int hotpepperRateLimit = 5; // 1秒間のリクエスト数制限
  static const int hotpepperDailyLimit = 3000; // 1日のリクエスト数制限

  /// Google Maps API設定
  static const String googleMapsApiUrl =
      'https://maps.googleapis.com/maps/api/';
  static const int googleMapsApiTimeout = 15; // 秒
  static const int googleMapsApiRetryCount = 2;

  /// 共通API設定
  static const String userAgent = 'MachiApp/1.0.0';
  static const Map<String, String> commonHeaders = {
    'User-Agent': userAgent,
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  /// API設定の妥当性チェック
  static bool isValidTimeout(int timeout) {
    return timeout > 0 && timeout <= 60;
  }

  /// API設定の妥当性チェック
  static bool isValidRetryCount(int retryCount) {
    return retryCount >= 0 && retryCount <= 5;
  }

  /// API設定の妥当性チェック
  static bool isValidMaxResults(int maxResults) {
    return maxResults > 0 && maxResults <= 100;
  }

  /// デバッグ情報を取得
  static Map<String, dynamic> get debugInfo {
    return {
      'hotpepperApiUrl': hotpepperApiUrl,
      'hotpepperApiTimeout': hotpepperApiTimeout,
      'hotpepperApiRetryCount': hotpepperApiRetryCount,
      'hotpepperMaxResults': hotpepperMaxResults,
      'hotpepperRateLimit': hotpepperRateLimit,
      'hotpepperDailyLimit': hotpepperDailyLimit,
      'googleMapsApiUrl': googleMapsApiUrl,
      'googleMapsApiTimeout': googleMapsApiTimeout,
      'googleMapsApiRetryCount': googleMapsApiRetryCount,
      'userAgent': userAgent,
    };
  }
}
