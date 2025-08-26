/// ASO (App Store Optimization) 設定を管理するクラス
/// アプリストア最適化のためのメタデータとキーワード戦略を定義
class AsoConfig {
  /// アプリ基本情報（日本語）
  static const String appDisplayName = '町中華探索アプリ「マチアプ」';
  static const String appShortName = 'マチアプ';
  static const String appTagline = '町中華を発見・記録する究極のグルメアプリ';

  /// アプリ詳細説明（App Store/Play Store用）
  static const String appStoreDescription = '''
町中華を愛するあなたのための究極の探索アプリ「マチアプ」

【主な機能】
🍜 マッチングアプリ風UI - スワイプで店舗選択
🔍 位置情報検索 - 近くの町中華を発見
📝 訪問記録 - 思い出を残そう
📱 シンプルで使いやすいデザイン

【こんな人におすすめ】
• 町中華巡りが趣味の方
• 美味しい中華料理店を探している方
• グルメ記録を残したい方
• 新しい店を開拓したい方

地元の隠れた名店から定番の町中華まで、あなたの中華料理ライフをサポートします。
''';

  /// キーワード戦略（検索最適化用）
  static const List<String> primaryKeywords = [
    '町中華',
    '中華料理',
    'グルメ',
    '料理',
    'レストラン',
    '食べログ',
    'ラーメン',
    '餃子',
    '定食',
  ];

  static const List<String> secondaryKeywords = [
    '探索',
    '検索',
    '記録',
    '発見',
    'マップ',
    '位置情報',
    'スワイプ',
    '評価',
    '口コミ',
    '地図',
  ];

  /// カテゴリ情報
  static const String primaryCategory = 'フード&ドリンク';
  static const String secondaryCategory = 'ライフスタイル';

  /// ターゲット年齢層
  static const String targetAgeGroup = '18歳以上';
  static const String contentRating = '全年齢対象';

  /// 地域設定
  static const List<String> targetRegions = ['日本'];
  static const String primaryLanguage = 'ja';
  static const List<String> supportedLanguages = ['ja'];

  /// アプリストア用スクリーンショットキーワード
  static const List<String> screenshotKeywords = [
    'スワイプ画面',
    '検索機能',
    'マイメニュー',
    '店舗詳細',
    '訪問記録',
    'マップ表示',
  ];

  /// レビュー促進設定
  static const int minUsageSessionsForReview = 3;
  static const int minStoresVisitedForReview = 2;
  static const int daysSinceInstallForReview = 7;
  static const int daysBetweenReviewPrompts = 30;

  /// アップデート情報
  static const String currentVersion = '1.0.0';
  static const String versionReleaseNotes = '''
【初回リリース】
• 町中華を探索・記録する機能
• スワイプによる直感的な操作
• 位置情報を使った店舗検索
• 訪問記録とメモ機能
• シンプルで分かりやすいUI
''';

  /// アプリアイコン・ブランドカラー
  static const String appIconDescription = '中華料理をイメージした暖色系デザイン';
  static const String brandPrimaryColor = '#FF6B35'; // 中華系オレンジ
  static const String brandSecondaryColor = '#2196F3'; // アクセントブルー

  /// ASO分析用メトリクス
  static const List<String> competitorApps = [
    'ぐるなび',
    '食べログ',
    'Retty',
    'HotPepper',
  ];

  /// 検索キーワード組み合わせ生成
  static List<String> generateKeywordCombinations() {
    final combinations = <String>[];

    for (final primary in primaryKeywords) {
      combinations.add(primary);
      for (final secondary in secondaryKeywords) {
        combinations.add('$primary $secondary');
        combinations.add('$secondary $primary');
      }
    }

    return combinations;
  }

  /// アプリストア説明文用キーワード密度チェック
  static Map<String, int> getKeywordDensity(String description) {
    final keywordCount = <String, int>{};
    final words = description.toLowerCase().split(RegExp(r'\s+'));

    for (final keyword in [...primaryKeywords, ...secondaryKeywords]) {
      final count =
          words.where((word) => word.contains(keyword.toLowerCase())).length;
      if (count > 0) {
        keywordCount[keyword] = count;
      }
    }

    return keywordCount;
  }

  /// ASO最適化スコア計算
  static double calculateAsoScore() {
    double score = 0.0;

    // アプリ名にキーワードが含まれているかチェック
    final nameKeywordCount = primaryKeywords
        .where((keyword) =>
            appDisplayName.toLowerCase().contains(keyword.toLowerCase()))
        .length;
    score += nameKeywordCount * 10;

    // 説明文のキーワード密度
    final densityMap = getKeywordDensity(appStoreDescription);
    score += densityMap.length * 5;

    // レビュー促進設定があるか
    if (minUsageSessionsForReview > 0) score += 10;

    // 多言語対応
    score += supportedLanguages.length * 5;

    // ターゲット地域が明確
    score += targetRegions.length * 5;

    return score.clamp(0, 100);
  }

  /// デバッグ情報取得
  static Map<String, dynamic> get debugInfo {
    return {
      'appDisplayName': appDisplayName,
      'appShortName': appShortName,
      'appTagline': appTagline,
      'primaryKeywords': primaryKeywords,
      'secondaryKeywords': secondaryKeywords,
      'primaryCategory': primaryCategory,
      'targetAgeGroup': targetAgeGroup,
      'targetRegions': targetRegions,
      'primaryLanguage': primaryLanguage,
      'supportedLanguages': supportedLanguages,
      'currentVersion': currentVersion,
      'brandPrimaryColor': brandPrimaryColor,
      'brandSecondaryColor': brandSecondaryColor,
      'reviewPromptSettings': {
        'minUsageSessionsForReview': minUsageSessionsForReview,
        'minStoresVisitedForReview': minStoresVisitedForReview,
        'daysSinceInstallForReview': daysSinceInstallForReview,
        'daysBetweenReviewPrompts': daysBetweenReviewPrompts,
      },
      'asoScore': calculateAsoScore(),
      'keywordCombinations': generateKeywordCombinations().take(10).toList(),
      'descriptionKeywordDensity': getKeywordDensity(appStoreDescription),
    };
  }

  /// アプリストア最適化チェックリスト
  static Map<String, bool> get optimizationChecklist {
    return {
      'アプリ名にキーワード含有': primaryKeywords.any((keyword) =>
          appDisplayName.toLowerCase().contains(keyword.toLowerCase())),
      '説明文が充実': appStoreDescription.length > 500,
      'キーワード戦略策定': primaryKeywords.isNotEmpty && secondaryKeywords.isNotEmpty,
      'レビュー促進設定': minUsageSessionsForReview > 0,
      'ターゲット地域明確': targetRegions.isNotEmpty,
      'ブランドカラー設定': brandPrimaryColor.isNotEmpty,
      'バージョンノート記載': versionReleaseNotes.isNotEmpty,
      'カテゴリ選択完了': primaryCategory.isNotEmpty,
      '競合分析実施': competitorApps.isNotEmpty,
      'スクリーンショット計画': screenshotKeywords.isNotEmpty,
    };
  }

  /// ASO改善提案生成
  static List<String> getOptimizationSuggestions() {
    final suggestions = <String>[];
    final checklist = optimizationChecklist;

    if (!checklist['アプリ名にキーワード含有']!) {
      suggestions.add('アプリ名により多くの検索キーワードを含める');
    }

    if (!checklist['説明文が充実']!) {
      suggestions.add('アプリストア説明文をより詳細に充実させる');
    }

    if (calculateAsoScore() < 80) {
      suggestions.add(
          'ASO総合スコアの向上が必要（現在: ${calculateAsoScore().toStringAsFixed(1)}点）');
    }

    final keywordDensity = getKeywordDensity(appStoreDescription);
    if (keywordDensity.length < 5) {
      suggestions.add('説明文により多くの関連キーワードを含める');
    }

    return suggestions;
  }
}
