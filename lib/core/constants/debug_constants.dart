import 'package:flutter/foundation.dart';

/// デバッグログ制御用の定数クラス
///
/// 環境変数で制御可能。本番環境（kReleaseMode）では自動的に無効化される。
///
/// ## 使用方法
///
/// ### 開発時にログを有効化:
/// ```bash
/// # 特定のログのみ有効化
/// flutter run --dart-define=ENABLE_API_LOG=true
///
/// # 複数のログを有効化
/// flutter run \
///   --dart-define=ENABLE_API_LOG=true \
///   --dart-define=ENABLE_SWIPE_FILTER_LOG=true
/// ```
///
/// ### テスト時:
/// ```bash
/// flutter test \
///   --dart-define=ENABLE_API_LOG=true
/// ```
class DebugConstants {
  DebugConstants._(); // プライベートコンストラクタでインスタンス化を防ぐ

  // 環境変数で制御（デフォルトはfalse）
  static const bool _enableSwipeFilterLog =
      bool.fromEnvironment('ENABLE_SWIPE_FILTER_LOG', defaultValue: false);
  static const bool _enableApiLog =
      bool.fromEnvironment('ENABLE_API_LOG', defaultValue: false);
  static const bool _enableStoreProviderLog =
      bool.fromEnvironment('ENABLE_STORE_PROVIDER_LOG', defaultValue: false);
  static const bool _enableRepositoryLog =
      bool.fromEnvironment('ENABLE_REPOSITORY_LOG', defaultValue: false);

  /// スワイプフィルタリングのデバッグログを出力するか
  ///
  /// デバッグモード時のみ有効。本番環境では常にfalse。
  static bool get enableSwipeFilterLog => kDebugMode && _enableSwipeFilterLog;

  /// API呼び出しのデバッグログを出力するか
  ///
  /// デバッグモード時のみ有効。本番環境では常にfalse。
  static bool get enableApiLog => kDebugMode && _enableApiLog;

  /// ストアプロバイダーのデバッグログを出力するか
  ///
  /// デバッグモード時のみ有効。本番環境では常にfalse。
  static bool get enableStoreProviderLog =>
      kDebugMode && _enableStoreProviderLog;

  /// リポジトリのデバッグログを出力するか
  ///
  /// デバッグモード時のみ有効。本番環境では常にfalse。
  static bool get enableRepositoryLog => kDebugMode && _enableRepositoryLog;

  /// 全てのログが有効化されているか
  static bool get allLogsEnabled =>
      enableSwipeFilterLog &&
      enableApiLog &&
      enableStoreProviderLog &&
      enableRepositoryLog;

  /// いずれかのログが有効化されているか
  static bool get anyLogEnabled =>
      enableSwipeFilterLog ||
      enableApiLog ||
      enableStoreProviderLog ||
      enableRepositoryLog;
}
