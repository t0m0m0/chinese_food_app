import '../config/config_manager.dart';

/// アプリケーション定数クラス
///
/// 注意: API関連の設定は ConfigManager を使用してください。
/// このクラスは環境に依存しない固定値のみを定義します。
class AppConstants {
  // アプリ情報
  static const String appName = 'マチアプ';
  static const String appVersion = '1.0.0';

  // データベース
  static const String databaseName = 'machiapp.db';
  static const int databaseVersion = 2;

  // UI関連
  static const double cardBorderRadius = 12.0;
  static const double defaultPadding = 16.0;

  // API関連 - 環境別設定のため ConfigManager を使用
  /// HotPepper API ベースURL
  /// 実際の使用時は ConfigManager.hotpepperApiUrl を使用してください
  static String get hotpepperApiUrl => ConfigManager.hotpepperApiUrl;

  /// HotPepper API キー
  /// 実際の使用時は ConfigManager.hotpepperApiKey を使用してください
  static String get hotpepperApiKey => ConfigManager.hotpepperApiKey;

  /// Google Maps API キー
  /// 実際の使用時は ConfigManager.googleMapsApiKey を使用してください
  static String get googleMapsApiKey => ConfigManager.googleMapsApiKey;

  /// APIキーが有効かどうかを判定（既存コードとの互換性維持）
  static bool get hasValidApiKeys => ConfigManager.hasValidApiKeys;

  // HotPepper API 設定
  static const int hotpepperApiTimeout = 10; // 秒
  static const int hotpepperApiRetryCount = 3;
  static const int hotpepperMaxResults = 100;

  // Google Maps 設定
  static const double defaultMapZoom = 15.0;
  static const double defaultLocationRadius = 1000.0; // メートル

  // アプリ設定
  static const int maxPhotoFileSize = 5 * 1024 * 1024; // 5MB
  static const List<String> supportedImageExtensions = [
    '.jpg',
    '.jpeg',
    '.png'
  ];

  // キャッシュ設定
  static const int cacheExpirationHours = 24;
  static const int maxCacheEntries = 1000;
}
