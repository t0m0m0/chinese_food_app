import 'package:shared_preferences/shared_preferences.dart';
import 'package:chinese_food_app/core/config/aso_config.dart';

/// ASO分析・トラッキングサービス
/// アプリ使用データを収集し、ストア最適化の効果を測定
class AsoAnalyticsService {
  static const String _keyFirstLaunchDate = 'first_launch_date';
  static const String _keyTotalSessions = 'total_sessions';
  static const String _keySearchCount = 'search_count';
  static const String _keySwipeCount = 'swipe_count';
  static const String _keyStoreViewCount = 'store_view_count';

  /// 初回起動日を記録
  static Future<void> recordFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();

    if (!prefs.containsKey(_keyFirstLaunchDate)) {
      await prefs.setInt(
          _keyFirstLaunchDate, DateTime.now().millisecondsSinceEpoch);
    }
  }

  /// セッション開始を記録
  static Future<void> recordSessionStart() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_keyTotalSessions) ?? 0;
    await prefs.setInt(_keyTotalSessions, currentCount + 1);

    // 日別セッション数も記録
    final today = _getTodayKey();
    final todayCount = prefs.getInt('session_$today') ?? 0;
    await prefs.setInt('session_$today', todayCount + 1);
  }

  /// 検索実行を記録
  static Future<void> recordSearch({
    required String searchType, // 'location', 'keyword', etc.
    required int resultCount,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // 総検索回数
    final totalCount = prefs.getInt(_keySearchCount) ?? 0;
    await prefs.setInt(_keySearchCount, totalCount + 1);

    // 検索タイプ別集計
    final typeCount = prefs.getInt('search_${searchType}_count') ?? 0;
    await prefs.setInt('search_${searchType}_count', typeCount + 1);

    // 検索結果数の記録
    final resultKey = 'search_results_${DateTime.now().millisecondsSinceEpoch}';
    await prefs.setInt(resultKey, resultCount);
  }

  /// スワイプアクションを記録
  static Future<void> recordSwipe({
    required String direction, // 'left', 'right'
    required String storeId,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // 総スワイプ回数
    final totalCount = prefs.getInt(_keySwipeCount) ?? 0;
    await prefs.setInt(_keySwipeCount, totalCount + 1);

    // 方向別集計
    final directionCount = prefs.getInt('swipe_${direction}_count') ?? 0;
    await prefs.setInt('swipe_${direction}_count', directionCount + 1);

    // 今日のスワイプ数
    final today = _getTodayKey();
    final todayCount = prefs.getInt('swipe_$today') ?? 0;
    await prefs.setInt('swipe_$today', todayCount + 1);
  }

  /// 店舗詳細表示を記録
  static Future<void> recordStoreView({
    required String storeId,
    required String source, // 'swipe', 'search', 'mylist'
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // 総表示回数
    final totalCount = prefs.getInt(_keyStoreViewCount) ?? 0;
    await prefs.setInt(_keyStoreViewCount, totalCount + 1);

    // 流入元別集計
    final sourceCount = prefs.getInt('store_view_${source}_count') ?? 0;
    await prefs.setInt('store_view_${source}_count', sourceCount + 1);
  }

  /// 機能使用を記録
  static Future<void> recordFeatureUsage({
    required String featureName,
    Map<String, dynamic>? parameters,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final featureCount = prefs.getInt('feature_${featureName}_count') ?? 0;
    await prefs.setInt('feature_${featureName}_count', featureCount + 1);

    // パラメータがある場合は別途記録
    if (parameters != null) {
      final paramKey =
          'feature_${featureName}_params_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString(paramKey, parameters.toString());
    }
  }

  /// ユーザーエンゲージメント指標を計算
  static Future<Map<String, dynamic>> getUserEngagementMetrics() async {
    final prefs = await SharedPreferences.getInstance();

    final firstLaunchMs = prefs.getInt(_keyFirstLaunchDate);
    final totalSessions = prefs.getInt(_keyTotalSessions) ?? 0;
    final searchCount = prefs.getInt(_keySearchCount) ?? 0;
    final swipeCount = prefs.getInt(_keySwipeCount) ?? 0;
    final storeViewCount = prefs.getInt(_keyStoreViewCount) ?? 0;

    int daysSinceFirstLaunch = 0;
    if (firstLaunchMs != null) {
      final firstLaunch = DateTime.fromMillisecondsSinceEpoch(firstLaunchMs);
      daysSinceFirstLaunch = DateTime.now().difference(firstLaunch).inDays + 1;
    }

    final averageSessionsPerDay =
        daysSinceFirstLaunch > 0 ? totalSessions / daysSinceFirstLaunch : 0.0;

    final averageActionsPerSession = totalSessions > 0
        ? (searchCount + swipeCount + storeViewCount) / totalSessions
        : 0.0;

    return {
      'totalSessions': totalSessions,
      'daysSinceFirstLaunch': daysSinceFirstLaunch,
      'averageSessionsPerDay': averageSessionsPerDay,
      'averageActionsPerSession': averageActionsPerSession,
      'searchCount': searchCount,
      'swipeCount': swipeCount,
      'storeViewCount': storeViewCount,
      'engagementScore': _calculateEngagementScore(
        totalSessions: totalSessions,
        daysSinceFirstLaunch: daysSinceFirstLaunch,
        searchCount: searchCount,
        swipeCount: swipeCount,
      ),
    };
  }

  /// リテンション（継続率）データを取得
  static Future<Map<String, dynamic>> getRetentionMetrics() async {
    final prefs = await SharedPreferences.getInstance();

    final retentionData = <String, int>{};
    final currentDate = DateTime.now();

    // 過去30日間の日別セッション数を取得
    for (int i = 0; i < 30; i++) {
      final date = currentDate.subtract(Duration(days: i));
      final dateKey = _getDateKey(date);
      final sessionCount = prefs.getInt('session_$dateKey') ?? 0;
      retentionData[dateKey] = sessionCount;
    }

    // リテンション率を計算
    final activeDays = retentionData.values.where((count) => count > 0).length;
    final retentionRate = activeDays / 30.0;

    return {
      'activeDaysLast30': activeDays,
      'retentionRate': retentionRate,
      'dailySessions': retentionData,
    };
  }

  /// ASO効果測定レポートを生成
  static Future<Map<String, dynamic>> generateAsoReport() async {
    final engagementMetrics = await getUserEngagementMetrics();
    final retentionMetrics = await getRetentionMetrics();
    final prefs = await SharedPreferences.getInstance();

    // 機能別使用統計
    final featureUsage = <String, int>{};
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('feature_') && key.endsWith('_count')) {
        final featureName = key.substring(8, key.length - 6);
        featureUsage[featureName] = prefs.getInt(key) ?? 0;
      }
    }

    // スワイプ分析
    final swipeLeftCount = prefs.getInt('swipe_left_count') ?? 0;
    final swipeRightCount = prefs.getInt('swipe_right_count') ?? 0;
    final totalSwipes = swipeLeftCount + swipeRightCount;
    final rightSwipeRate =
        totalSwipes > 0 ? swipeRightCount / totalSwipes : 0.0;

    // 検索分析
    final searchLocationCount = prefs.getInt('search_location_count') ?? 0;
    final searchKeywordCount = prefs.getInt('search_keyword_count') ?? 0;

    // 流入元分析
    final storeViewSwipeCount = prefs.getInt('store_view_swipe_count') ?? 0;
    final storeViewSearchCount = prefs.getInt('store_view_search_count') ?? 0;
    final storeViewMylistCount = prefs.getInt('store_view_mylist_count') ?? 0;

    return {
      'reportGeneratedAt': DateTime.now().toIso8601String(),
      'asoConfig': AsoConfig.debugInfo,
      'userEngagement': engagementMetrics,
      'retention': retentionMetrics,
      'featureUsage': featureUsage,
      'swipeAnalysis': {
        'totalSwipes': totalSwipes,
        'leftSwipes': swipeLeftCount,
        'rightSwipes': swipeRightCount,
        'rightSwipeRate': rightSwipeRate,
      },
      'searchAnalysis': {
        'totalSearches': searchLocationCount + searchKeywordCount,
        'locationSearches': searchLocationCount,
        'keywordSearches': searchKeywordCount,
      },
      'trafficSources': {
        'swipeToDetail': storeViewSwipeCount,
        'searchToDetail': storeViewSearchCount,
        'mylistToDetail': storeViewMylistCount,
      },
      'asoScore': AsoConfig.calculateAsoScore(),
      'optimizationSuggestions': AsoConfig.getOptimizationSuggestions(),
    };
  }

  /// エンゲージメントスコアを計算
  static double _calculateEngagementScore({
    required int totalSessions,
    required int daysSinceFirstLaunch,
    required int searchCount,
    required int swipeCount,
  }) {
    if (daysSinceFirstLaunch == 0) return 0.0;

    final sessionScore = (totalSessions / daysSinceFirstLaunch) * 10;
    final actionScore =
        ((searchCount + swipeCount) / totalSessions.clamp(1, double.infinity)) *
            5;
    final retentionBonus = daysSinceFirstLaunch > 7 ? 10 : 0;

    return (sessionScore + actionScore + retentionBonus).clamp(0, 100);
  }

  /// 今日の日付キーを取得
  static String _getTodayKey() => _getDateKey(DateTime.now());

  /// 日付キーを生成
  static String _getDateKey(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }

  /// サービス初期化
  static Future<void> initialize() async {
    await recordFirstLaunch();
    await recordSessionStart();
  }

  /// デバッグ用：全データをクリア
  static Future<void> clearAllAnalyticsData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs
        .getKeys()
        .where((key) =>
            key.startsWith('session_') ||
            key.startsWith('search_') ||
            key.startsWith('swipe_') ||
            key.startsWith('store_view_') ||
            key.startsWith('feature_') ||
            key == _keyFirstLaunchDate ||
            key == _keyTotalSessions ||
            key == _keySearchCount ||
            key == _keySwipeCount ||
            key == _keyStoreViewCount)
        .toList();

    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  /// キーワード効果測定
  static Future<Map<String, dynamic>> analyzeKeywordEffectiveness() async {
    final report = await generateAsoReport();
    final keywordDensity =
        AsoConfig.getKeywordDensity(AsoConfig.appStoreDescription);

    return {
      'keywordDensity': keywordDensity,
      'searchAnalysis': report['searchAnalysis'],
      'engagementScore': report['userEngagement']['engagementScore'],
      'recommendations': _generateKeywordRecommendations(
        keywordDensity,
        report['searchAnalysis'] as Map<String, dynamic>,
      ),
    };
  }

  /// キーワード推奨事項を生成
  static List<String> _generateKeywordRecommendations(
    Map<String, int> keywordDensity,
    Map<String, dynamic> searchAnalysis,
  ) {
    final recommendations = <String>[];

    if (keywordDensity.length < 5) {
      recommendations.add('アプリ説明文により多くの関連キーワードを含める');
    }

    final locationSearches = searchAnalysis['locationSearches'] as int;
    final keywordSearches = searchAnalysis['keywordSearches'] as int;

    if (locationSearches > keywordSearches * 2) {
      recommendations.add('位置情報関連キーワードを強化');
    }

    if (keywordSearches > locationSearches * 2) {
      recommendations.add('料理名・ジャンル関連キーワードを強化');
    }

    return recommendations;
  }
}
