/// API関連の定数を管理するクラス
class ApiConstants {
  ApiConstants._(); // プライベートコンストラクタでインスタンス化を防ぐ

  /// デフォルト位置情報（新宿駅）
  static const double defaultLatitude = 35.6917;
  static const double defaultLongitude = 139.7006;

  /// API検索のデフォルト設定
  static const int defaultStoreCount = 50; // スワイプ画面で十分な店舗数を取得
  static const String defaultKeyword = '中華';
  static const int defaultRange = 3; // 1000m

  /// 重複チェック用の閾値
  static const double duplicateThreshold = 0.001; // 約110m

  /// API制限設定
  static const Duration apiRateLimit = Duration(seconds: 1);
  static const int maxDailyRequests = 3000;
  static const int maxRequestsPerSecond = 5;
}
