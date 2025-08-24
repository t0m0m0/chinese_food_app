/// アプリストア配布用のメタデータを管理するクラス
///
/// アプリ名、説明文、バージョン情報、ASO用キーワードなど、
/// リリース時に必要なメタデータを一元管理する
class AppMetadata {
  AppMetadata._();

  // アプリ基本情報
  static const String appName = '町中華探索アプリ「マチアプ」';
  static const String appNameShort = 'マチアプ';

  static const String appDescription =
      '町中華を探索・記録するアプリ。スワイプで店舗発見、マップ検索、訪問記録が簡単に！';

  static const String appDescriptionDetail = '''
町中華探索アプリ「マチアプ」は、あなたの町中華ライフをより楽しくするためのアプリです。

【主な機能】
🍜 スワイプで店舗発見
マッチングアプリのような直感的なUIで、気になる町中華を発見できます。右スワイプで「行きたい」、左スワイプで「興味なし」を選択。

🗺️ 地図で周辺検索
現在地や指定した場所の近くにある中華料理店をマップ上で確認。HotPepper APIを活用した豊富な店舗データベース。

📝 訪問記録を保存
実際に訪れた店舗の写真、メニュー、感想を記録。あなただけの町中華記録帳を作成できます。

【こんな方におすすめ】
・町中華が大好きな方
・新しいお店を開拓したい方
・食べ歩きの記録を残したい方
・ラーメン、餃子、定食などB級グルメファンの方

シンプルで使いやすいUIで、町中華探索がもっと楽しくなります！
  ''';

  // プラットフォーム設定
  static const String androidPackageName = 'com.machiapp.chinese_food';
  static const String iosBundleId = 'com.machiapp.chineseFoodApp';

  // バージョン情報（pubspec.yamlから取得）
  static const String version = '1.0.0';
  static const String buildNumber = '1';

  // ASO（アプリストア最適化）キーワード
  static const List<String> asoKeywords = [
    '中華料理',
    '町中華',
    'レストラン検索',
    'グルメアプリ',
    'お店探し',
    '食べ歩き',
    'ラーメン',
    '餃子',
    '定食',
    'マップ',
  ];

  static String get asoKeywordsString {
    return asoKeywords.take(5).join(', '); // 50文字以内に調整
  }

  // ストア設定
  static const String ageRating = 'すべて';
  static const String category = 'フード&ドリンク';

  // プライバシーポリシーURL（将来設定予定）
  static const String privacyPolicyUrl = 'https://machiapp.example.com/privacy';

  /// デバッグ用情報を提供
  static String debugInfo() {
    return '''
AppMetadata Debug Info:
- appName: $appName
- version: $version
- buildNumber: $buildNumber
- androidPackageName: $androidPackageName
- iosBundleId: $iosBundleId
- category: $category
- ageRating: $ageRating
- asoKeywords: ${asoKeywords.join(', ')}
- privacyPolicyUrl: $privacyPolicyUrl
    '''
        .trim();
  }
}
