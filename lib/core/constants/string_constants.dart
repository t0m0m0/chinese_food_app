/// アプリケーション全体で使用される文字列定数の一元管理
///
/// ハードコードされた文字列を避け、保守性と国際化対応を向上させるための定数クラス
class StringConstants {
  StringConstants._();

  /// 検索関連の文字列定数
  static const String defaultSearchKeyword = '中華';
  static const String searchGenreName = '中華料理';
  static const String townChineseKeyword = '町中華';

  /// アプリケーション関連の文字列定数
  static const String appShortName = 'マチアプ';
  static const String appFullName = '町中華探索アプリ「マチアプ」';
  static const String appDescription = '中華料理店を発見・記録するグルメアプリ';

  /// ボタンラベル・UI文字列
  static const String searchButtonLabel = '中華料理店を検索';
  static const String noResultsMessage = '検索ボタンを押して中華料理店を探しましょう';

  /// 店舗関連の文字列定数
  static const String testStoreName = 'テスト中華料理店';
  static const String sampleStorePrefix = '町中華';

  /// メッセージ・通知関連
  static const String reviewPromptMessage = 'あなたの町中華探索はいかがですか？';
  static const String reviewThanksMessage = 'これからも町中華探索をお楽しみください。';

  /// データベース・API関連
  static const String apiKeywordParameter = '中華';

  /// キーワード・タグ一覧
  static const List<String> searchKeywords = [
    '中華',
    '中華料理',
    '町中華',
  ];

  /// 許可されたキーワード（セキュリティ・バリデーション用）
  static const List<String> allowedKeywords = [
    '中華',
    '中華料理',
    '町中華',
  ];

  /// デバッグ・テスト用定数
  static const String debugStoreNameTemplate = 'テスト中華料理店';

  /// ジャンル分類用定数
  static const Map<String, String> genreMapping = {
    'chinese': '中華料理',
    'townChinese': '町中華',
  };

  /// 検索オプション・フィルター用
  static const Map<String, String> searchFilters = {
    'cuisine_type': '中華料理',
    'establishment_type': '町中華',
  };
}
