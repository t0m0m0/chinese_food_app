import 'dart:developer' as developer;

import '../config/api_config.dart';
import '../config/config_manager.dart';
import '../config/database_config.dart';
import '../config/ui_config.dart';

/// アプリケーション定数クラス
///
/// 注意: 設定値は分野別設定クラス（ApiConfig、UiConfig等）を使用してください。
/// このクラスは既存コードとの互換性維持のために残されています。
class AppConstants {
  // アプリ情報 - UiConfigから取得
  static String get appName => UiConfig.appName;
  static String get appVersion => UiConfig.appVersion;

  // データベース - DatabaseConfigから取得
  static String get databaseName => DatabaseConfig.databaseName;
  static int get databaseVersion => DatabaseConfig.databaseVersion;

  // UI関連 - UiConfigから取得
  static double get cardBorderRadius => UiConfig.cardBorderRadius;
  static double get defaultPadding => UiConfig.defaultPadding;

  // API関連 - ConfigManagerから取得（環境別設定）
  /// HotPepper API ベースURL
  /// 実際の使用時は ApiConfig.hotpepperApiUrl を使用してください
  static String get hotpepperApiUrl => ApiConfig.hotpepperApiUrl;

  /// HotPepper API キー
  /// 実際の使用時は ConfigManager.hotpepperApiKey を使用してください
  static String get hotpepperApiKey => ConfigManager.hotpepperApiKey;

  /// Google Maps API キー
  /// 実際の使用時は ConfigManager.googleMapsApiKey を使用してください
  static String get googleMapsApiKey => ConfigManager.googleMapsApiKey;

  /// APIキーが有効かどうかを判定（既存コードとの互換性維持）
  static bool get hasValidApiKeys => ConfigManager.hasValidApiKeys;

  // HotPepper API 設定 - ApiConfigから取得
  static int get hotpepperApiTimeout => ApiConfig.hotpepperApiTimeout;
  static int get hotpepperApiRetryCount => ApiConfig.hotpepperApiRetryCount;
  static int get hotpepperMaxResults => ApiConfig.hotpepperMaxResults;

  // Google Maps 設定 - UiConfigから取得
  static double get defaultMapZoom => UiConfig.defaultMapZoom;
  static double get defaultLocationRadius =>
      UiConfig.defaultMapZoom * 100; // 概算値

  // アプリ設定 - 固定値（変更頻度が低いため）
  static const int maxPhotoFileSize = 5 * 1024 * 1024; // 5MB
  static const List<String> supportedImageExtensions = [
    '.jpg',
    '.jpeg',
    '.png'
  ];

  // キャッシュ設定 - 固定値（変更頻度が低いため）
  static const int cacheExpirationHours = 24;
  static const int maxCacheEntries = 1000;

  /// 非推奨警告
  @Deprecated(
      'AppConstants の使用は非推奨です。代わりに分野別設定クラス（ApiConfig、UiConfig等）を使用してください。')
  static void showDeprecationWarning() {
    // 開発環境でのみ警告を表示
    if (ConfigManager.isDevelopment) {
      developer.log(
        'Warning: AppConstants is deprecated. Use domain-specific config classes instead.',
        name: 'AppConstants',
      );
    }
  }
}
