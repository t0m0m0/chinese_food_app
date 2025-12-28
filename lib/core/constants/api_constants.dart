/// API関連の定数を管理するクラス
class ApiConstants {
  ApiConstants._(); // プライベートコンストラクタでインスタンス化を防ぐ

  /// デフォルト位置情報（新宿駅）
  static const double defaultLatitude = 35.6917;
  static const double defaultLongitude = 139.7006;

  /// API検索のデフォルト設定
  static const int defaultStoreCount = 100; // HotPepper API上限まで取得
  static const String defaultKeyword = '中華';
  static const int defaultRange = 3; // 1000m

  /// ページネーション設定
  static const int paginationThreshold = 10; // 次ページ取得のトリガー閾値（残り枚数）
  static const int autoPaginationThreshold = 20; // 自動ページ取得の閾値（フィルタリング後）

  /// 重複チェック用の閾値
  static const double duplicateThreshold = 0.001; // 約110m

  /// API制限設定
  static const Duration apiRateLimit = Duration(seconds: 1);
  static const int maxDailyRequests = 3000;
  static const int maxRequestsPerSecond = 5;
}
