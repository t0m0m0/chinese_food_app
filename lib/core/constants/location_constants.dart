/// 位置情報関連の定数定義
class LocationConstants {
  /// キャッシュ有効期限（デフォルト: 5分）
  static const Duration defaultCacheExpiration = Duration(minutes: 5);

  /// 位置の変化距離閾値（メートル）- これを超えたら新しい位置を取得
  static const double significantDistanceThreshold = 100.0; // 100m

  /// 高精度と判断する精度の閾値（メートル）
  static const double highAccuracyThreshold = 20.0; // 20m

  /// バッテリー低下の閾値
  static const double lowBatteryThreshold = 0.20; // 20%

  /// バッテリー最適化モードでの位置情報取得間隔
  static const Duration batteryOptimizedInterval = Duration(minutes: 2);

  /// 通常モードでの位置情報取得間隔
  static const Duration normalInterval = Duration(seconds: 30);

  /// 位置情報取得のデフォルトタイムアウト
  static const Duration defaultLocationTimeout = Duration(seconds: 10);

  /// バッテリー最適化モードでのタイムアウト（短縮）
  static const Duration batteryOptimizedTimeout = Duration(seconds: 5);

  /// パフォーマンス監視用の移動平均ウィンドウサイズ
  static const int performanceMetricsWindowSize = 10;

  /// ストリーム更新の最小間隔（デバウンス）
  static const Duration streamDebounceInterval = Duration(milliseconds: 500);

  /// Isolateでの処理に切り替える閾値（処理時間）
  static const Duration isolateThreshold = Duration(milliseconds: 100);
}
