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

  /// 共通API設定
  static const String userAgent = 'MachiApp/1.0.0';
  static const Map<String, String> commonHeaders = {
    'User-Agent': userAgent,
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  /// 検証用定数
  static const int minTimeoutSeconds = 1;
  static const int maxTimeoutSeconds = 60;
  static const int minRetryCount = 0;
  static const int maxRetryCount = 5;
  static const int minMaxResults = 1;
  static const int maxMaxResults = 100;

  /// タイムアウト値の妥当性チェック（1-60秒）
  static bool isValidTimeout(int timeout) {
    return timeout >= minTimeoutSeconds && timeout <= maxTimeoutSeconds;
  }

  /// リトライ回数の妥当性チェック（0-5回）
  static bool isValidRetryCount(int retryCount) {
    return retryCount >= minRetryCount && retryCount <= maxRetryCount;
  }

  /// 最大結果数の妥当性チェック（1-100件）
  static bool isValidMaxResults(int maxResults) {
    return maxResults >= minMaxResults && maxResults <= maxMaxResults;
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
      'userAgent': userAgent,
    };
  }
}
