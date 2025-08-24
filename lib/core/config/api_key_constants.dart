/// APIキー関連の定数定義
class ApiKeyConstants {
  /// HotPepper APIキーの最小文字数
  static const int hotpepperApiKeyMinLength = 16;

  /// HotPepper APIキーの有効文字パターン（英数字のみ）
  static const String hotpepperApiKeyPattern = r'^[a-zA-Z0-9]+$';

  /// テスト環境用ダミーAPIキー
  static const String testDummyHotpepperApiKey =
      'testdummyhotpepperkey123456789';

  /// APIキーフィールド名
  static const String hotpepperApiKeyField = 'HOTPEPPER_API_KEY';

  /// 環境変数フィールド名
  static const String flutterEnvField = 'FLUTTER_ENV';

  /// 各環境名
  static const String developmentEnv = 'development';
  static const String testEnv = 'test';
  static const String stagingEnv = 'staging';
  static const String productionEnv = 'production';

  /// エラーメッセージ
  static const String hotpepperApiKeyMissingError = 'が設定されていません';
  static const String hotpepperApiKeyFormatError = 'HotPepper API キーの形式が無効です';
  static const String hotpepperApiKeyFormatRequirement = '最低16文字の英数字が必要';
}
