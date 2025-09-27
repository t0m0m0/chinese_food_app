/// 検索関連の設定を管理するクラス
class SearchConfig {
  /// 検索デフォルト設定
  static const String defaultKeyword = '中華';
  static const int defaultRange =
      3; // 1:300m, 2:500m, 3:1000m, 4:2000m, 5:3000m
  static const int defaultCount = 20;
  static const int defaultStart = 1;

  /// 検索範囲設定
  static const Map<int, int> rangeToMeters = {
    1: 300,
    2: 500,
    3: 1000,
    4: 2000,
    5: 3000,
  };

  /// 検索範囲のラベル表示（UI用）
  static const Map<int, String> rangeLabels = {
    1: '300m',
    2: '500m',
    3: '1000m',
    4: '2000m',
    5: '3000m',
  };

  /// 検索範囲の説明文（ツールチップ用）
  static const Map<int, String> rangeDescriptions = {
    1: '最寄り（300m圏内）',
    2: '近場（500m圏内）',
    3: '徒歩圏内（1000m圏内）',
    4: '少し遠め（2000m圏内）',
    5: '広範囲（3000m圏内）',
  };

  /// 検索結果の取得件数設定
  static const int minCount = 1;
  static const int maxCount = 100;
  static const int defaultPageSize = 20;

  /// 検索開始位置設定
  static const int minStart = 1;
  static const int maxStart = 1000;

  /// 検索キーワード設定
  static const List<String> allowedKeywords = [
    '中華',
    '中華料理',
    '町中華',
    '餃子',
    'ラーメン',
    '炒飯',
    '炒め物',
    '麺類',
    '定食',
  ];

  /// 検索フィルタ設定
  static const List<String> budgetRanges = [
    '～500円',
    '501～1000円',
    '1001～1500円',
    '1501～2000円',
    '2001～3000円',
    '3001～4000円',
    '4001～5000円',
    '5001円～',
  ];

  /// 検索ソート設定
  static const List<String> sortOptions = [
    'distance', // 距離順
    'rating', // 評価順
    'budget', // 予算順
    'name', // 店名順
  ];

  /// 検索設定の妥当性チェック
  static bool isValidRange(int range) {
    return rangeToMeters.containsKey(range);
  }

  /// 検索設定の妥当性チェック
  static bool isValidCount(int count) {
    return count >= minCount && count <= maxCount;
  }

  /// 検索設定の妥当性チェック
  static bool isValidStart(int start) {
    return start >= minStart && start <= maxStart;
  }

  /// 検索設定の妥当性チェック
  static bool isValidKeyword(String keyword) {
    return keyword.isNotEmpty && keyword.length <= 100;
  }

  /// 検索キーワードが許可されているかどうかを判定
  static bool isAllowedKeyword(String keyword) {
    return allowedKeywords.contains(keyword);
  }

  /// 検索範囲をメートルに変換
  static int? rangeToMeter(int range) {
    return rangeToMeters[range];
  }

  /// 検索範囲のラベルを取得
  static String? getRangeLabel(int range) {
    return rangeLabels[range];
  }

  /// 検索範囲の説明を取得
  static String? getRangeDescription(int range) {
    return rangeDescriptions[range];
  }

  /// メートルを検索範囲に変換
  static int? meterToRange(int meter) {
    for (final entry in rangeToMeters.entries) {
      if (entry.value == meter) {
        return entry.key;
      }
    }
    return null;
  }

  /// 予算範囲が有効かどうかを判定
  static bool isValidBudgetRange(String budgetRange) {
    return budgetRanges.contains(budgetRange);
  }

  /// ソートオプションが有効かどうかを判定
  static bool isValidSortOption(String sortOption) {
    return sortOptions.contains(sortOption);
  }

  /// デバッグ情報を取得
  static Map<String, dynamic> get debugInfo {
    return {
      'defaultKeyword': defaultKeyword,
      'defaultRange': defaultRange,
      'defaultCount': defaultCount,
      'defaultStart': defaultStart,
      'rangeToMeters': rangeToMeters,
      'rangeLabels': rangeLabels,
      'rangeDescriptions': rangeDescriptions,
      'minCount': minCount,
      'maxCount': maxCount,
      'defaultPageSize': defaultPageSize,
      'minStart': minStart,
      'maxStart': maxStart,
      'allowedKeywords': allowedKeywords,
      'budgetRanges': budgetRanges,
      'sortOptions': sortOptions,
    };
  }
}
