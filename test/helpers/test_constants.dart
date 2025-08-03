// test/helpers/test_constants.dart

/// テスト実行時に使用される定数値を一元管理するクラス
///
/// テスト用ダミーAPIキーや共通設定値を定義し、
/// 複数のテストファイルで重複する定数値を統一します。
class TestConstants {
  // プライベートコンストラクタ（インスタンス化防止）
  TestConstants._();

  /// HotPepper API用テストダミーキー
  ///
  /// 実際のAPI呼び出しは行わず、テスト環境での設定値検証のみに使用
  static const String dummyHotpepperApiKey =
      'test_dummy_hotpepper_key_for_testing_12345';

  /// Google Maps API用テストダミーキー
  ///
  /// 実際のAPI呼び出しは行わず、テスト環境での設定値検証のみに使用
  static const String dummyGoogleMapsApiKey =
      'test_dummy_google_maps_key_for_testing_12345';

  /// テスト環境用環境変数のデフォルト設定
  ///
  /// DotEnv初期化エラー時のフォールバック設定として使用
  static const String defaultTestEnvironmentConfig = '''
FLUTTER_ENV=test
HOTPEPPER_API_KEY=$dummyHotpepperApiKey
GOOGLE_MAPS_API_KEY=$dummyGoogleMapsApiKey
LOCATION_MODE=test
PERMISSION_TEST_MODE=mock
TEST_DEBUG_LOGGING=true''';

  /// テスト用環境変数キー定数
  static const String hotpepperApiKeyEnv = 'HOTPEPPER_API_KEY';
  static const String googleMapsApiKeyEnv = 'GOOGLE_MAPS_API_KEY';
  static const String flutterEnvKey = 'FLUTTER_ENV';
  static const String testEnvValue = 'test';
}
