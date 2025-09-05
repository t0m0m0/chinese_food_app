/// キャッシュ設定管理
///
/// アプリケーション全体のキャッシュ動作を管理する設定クラス
/// パフォーマンス最適化とメモリ効率のバランスを制御
class CacheConfig {
  CacheConfig._();

  /// ストア関連キャッシュの設定
  static const Duration storeCacheMaxAge = Duration(seconds: 30);

  /// API検索結果キャッシュの設定
  static const Duration searchCacheMaxAge = Duration(minutes: 5);

  /// 位置情報キャッシュの設定
  static const Duration locationCacheMaxAge = Duration(minutes: 10);

  /// 画像キャッシュの設定
  static const Duration imageCacheMaxAge = Duration(hours: 24);

  /// デバッグモード用：短いキャッシュ期間（テスト・開発時）
  static const Duration debugCacheMaxAge = Duration(seconds: 5);

  /// キャッシュサイズ制限
  static const int maxCacheEntries = 1000;

  /// 大容量キャッシュのサイズ制限（画像等）
  static const int maxLargeCacheEntries = 100;

  /// キャッシュクリーンアップの閾値（この確率でクリーンアップ実行）
  static const double cacheCleanupProbability = 0.1; // 10%

  /// メモリ圧迫時の自動キャッシュクリア閾値（MB）
  static const int memoryCriticalThresholdMB = 100;

  /// 開発環境判定用フラグ（将来的に環境設定と連携）
  static const bool isDevelopment = true; // TODO: 環境設定から取得

  /// 実際に使用するストアキャッシュ期間（環境に応じて動的切り替え）
  static Duration get activeStoreCacheMaxAge {
    return isDevelopment ? debugCacheMaxAge : storeCacheMaxAge;
  }

  /// ミリ秒単位でのストアキャッシュ期間取得（後方互換性）
  static int get storeCacheMaxAgeMilliseconds {
    return activeStoreCacheMaxAge.inMilliseconds;
  }
}
