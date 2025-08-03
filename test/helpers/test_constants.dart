// test/helpers/test_constants.dart

/// テスト・CI・ビルド環境で使用される定数値を一元管理するクラス
///
/// テスト用ダミーAPIキー、CI設定値、ビルド設定値など、
/// 複数の環境・ファイルで重複する定数値を統一管理します。
///
/// 対象範囲:
/// - テスト環境 (.env.test)
/// - CI/CD環境 (.github/workflows/ci.yml)
/// - 統合テスト環境
/// - ビルド環境
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
FLUTTER_ENV=$testEnvValue
HOTPEPPER_API_KEY=$dummyHotpepperApiKey
GOOGLE_MAPS_API_KEY=$dummyGoogleMapsApiKey
LOCATION_MODE=$locationModeTest
PERMISSION_TEST_MODE=$permissionTestModeMock
TEST_DEBUG_LOGGING=$testDebugLoggingTrue''';

  /// テスト用環境変数キー定数
  static const String hotpepperApiKeyEnv = 'HOTPEPPER_API_KEY';
  static const String googleMapsApiKeyEnv = 'GOOGLE_MAPS_API_KEY';
  static const String flutterEnvKey = 'FLUTTER_ENV';
  static const String testEnvValue = 'test';

  /// CI/CD環境用ダミーAPIキー
  ///
  /// CI環境で使用される追加のダミーキー値
  static const String ciDummyGoogleMapsApiKey =
      'AIzaSyDUMMY_KEY_FOR_CI_ENVIRONMENT_12345';
  static const String buildDummyHotpepperApiKey =
      'dummy_hotpepper_key_for_build_12345';
  static const String buildDummyGoogleMapsApiKey =
      'dummy_maps_key_for_build_12345';

  /// 統合テスト用ダミーAPIキー
  static const String integrationTestHotpepperApiKey =
      'integration_test_key_12345';
  static const String integrationTestGoogleMapsApiKey =
      'integration_test_maps_key_12345';

  /// CI環境用追加設定
  static const String ciTestEnvSource = 'ci';
  static const String ciEnvironmentValue = 'github_actions';
  static const String integrationEnvValue = 'integration';
  static const String locationModeTest = 'test';
  static const String locationModeMock = 'mock';
  static const String permissionTestModeMock = 'mock';
  static const String testDebugLoggingTrue = 'true';

  /// Flutter環境値定数
  static const String productionEnvValue = 'production';
  static const String developmentEnvValue = 'development';
  static const String stagingEnvValue = 'staging';

  /// 統合テスト環境用環境変数設定
  static const String integrationTestEnvironmentConfig = '''
FLUTTER_ENV=$integrationEnvValue
HOTPEPPER_API_KEY=$integrationTestHotpepperApiKey
GOOGLE_MAPS_API_KEY=$integrationTestGoogleMapsApiKey
LOCATION_MODE=$locationModeMock''';
}
