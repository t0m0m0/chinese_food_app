import 'package:flutter/material.dart';
import 'package:chinese_food_app/core/services/app_review_service.dart';
import 'package:chinese_food_app/core/services/aso_analytics_service.dart';
import 'package:chinese_food_app/presentation/widgets/app_review_prompt_dialog.dart';

/// ASO機能をアプリ全体に統合するサービス
/// レビュー促進、分析データ収集、ユーザー体験の最適化を統合管理
class AsoIntegrationService {
  /// サービス初期化（アプリ起動時に呼び出し）
  static Future<void> initialize() async {
    await Future.wait([
      AppReviewService.initialize(),
      AsoAnalyticsService.initialize(),
    ]);
  }

  /// アプリ起動時の処理
  static Future<void> onAppLaunch(BuildContext context) async {
    // セッション開始をトラッキング
    await AsoAnalyticsService.recordSessionStart();

    // レビュープロンプトの表示判定
    if (context.mounted) {
      await AppReviewHelper.checkOnAppLaunch(context);
    }
  }

  /// 店舗検索実行時の処理
  static Future<void> onStoreSearch({
    required String searchType,
    required int resultCount,
    String? keyword,
  }) async {
    // 検索分析データを記録
    await AsoAnalyticsService.recordSearch(
      searchType: searchType,
      resultCount: resultCount,
    );

    // 機能使用を記録
    await AsoAnalyticsService.recordFeatureUsage(
      featureName: 'store_search',
      parameters: {
        'type': searchType,
        'results': resultCount,
        'keyword': keyword,
      },
    );
  }

  /// スワイプアクション実行時の処理
  static Future<void> onStoreSwipe({
    required BuildContext context,
    required String direction,
    required String storeId,
  }) async {
    // スワイプデータを記録
    await AsoAnalyticsService.recordSwipe(
      direction: direction,
      storeId: storeId,
    );

    // 機能使用を記録
    await AsoAnalyticsService.recordFeatureUsage(
      featureName: 'store_swipe',
      parameters: {
        'direction': direction,
        'storeId': storeId,
      },
    );
  }

  /// 店舗詳細表示時の処理
  static Future<void> onStoreView({
    required BuildContext context,
    required String storeId,
    required String source,
  }) async {
    // 店舗表示を記録
    await AsoAnalyticsService.recordStoreView(
      storeId: storeId,
      source: source,
    );

    // 機能使用を記録
    await AsoAnalyticsService.recordFeatureUsage(
      featureName: 'store_detail_view',
      parameters: {
        'storeId': storeId,
        'source': source,
      },
    );
  }

  /// 店舗訪問記録作成時の処理
  static Future<void> onStoreVisit({
    required BuildContext context,
    required String storeId,
  }) async {
    // 機能使用を記録
    await AsoAnalyticsService.recordFeatureUsage(
      featureName: 'store_visit_record',
      parameters: {
        'storeId': storeId,
      },
    );

    // レビュープロンプトの表示判定
    if (context.mounted) {
      await AppReviewHelper.checkOnStoreVisit(context);
    }
  }

  /// 写真追加時の処理
  static Future<void> onPhotoAdd({
    required String storeId,
    required String photoType,
  }) async {
    await AsoAnalyticsService.recordFeatureUsage(
      featureName: 'photo_add',
      parameters: {
        'storeId': storeId,
        'type': photoType,
      },
    );
  }

  /// マップ表示時の処理
  static Future<void> onMapView({
    required String storeId,
    required String mapType,
  }) async {
    await AsoAnalyticsService.recordFeatureUsage(
      featureName: 'map_view',
      parameters: {
        'storeId': storeId,
        'mapType': mapType,
      },
    );
  }

  /// 外部アプリ起動時の処理
  static Future<void> onExternalAppLaunch({
    required String appType,
    required String storeId,
  }) async {
    await AsoAnalyticsService.recordFeatureUsage(
      featureName: 'external_app_launch',
      parameters: {
        'appType': appType,
        'storeId': storeId,
      },
    );
  }

  /// 設定画面表示時の処理
  static Future<void> onSettingsView() async {
    await AsoAnalyticsService.recordFeatureUsage(
      featureName: 'settings_view',
    );
  }

  /// エラー発生時の処理
  static Future<void> onError({
    required String errorType,
    required String errorMessage,
    String? context,
  }) async {
    await AsoAnalyticsService.recordFeatureUsage(
      featureName: 'error_occurred',
      parameters: {
        'type': errorType,
        'message': errorMessage,
        'context': context,
      },
    );
  }

  /// 長期間使用ユーザーへの特別プロンプト
  static Future<void> checkLoyalUserReward(BuildContext context) async {
    final stats = await AppReviewService.getUserUsageStats();
    final daysSinceInstall = stats['daysSinceInstall'] as int;
    final totalSessions = stats['usageSessionCount'] as int;

    // 2週間以上かつ10セッション以上の場合、特別なレビュー促進
    if (daysSinceInstall >= 14 && totalSessions >= 10) {
      final shouldShow = await AppReviewService.shouldShowReviewPrompt();
      if (shouldShow && context.mounted) {
        await _showLoyalUserDialog(context);
      }
    }
  }

  /// 熟練ユーザー向けの特別ダイアログ
  static Future<void> _showLoyalUserDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Text('マチアプマスター！'),
          ],
        ),
        content: const Text(
          'あなたは真のマチアプマスターです！\n'
          '多くの町中華を発見し、記録してくださってありがとうございます。\n\n'
          'もしアプリを気に入っていただけましたら、\n'
          'App Storeでのレビューで他のグルメ愛好家にも教えてあげてください！',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await AppReviewService.markReviewDeclined();
            },
            child: const Text('後で'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await AppReviewService.openAppStoreReview();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text('レビューする', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// アプリパフォーマンス情報取得
  static Future<Map<String, dynamic>> getPerformanceMetrics() async {
    final analytics = await AsoAnalyticsService.generateAsoReport();
    final reviewStats = await AppReviewService.getUserUsageStats();

    return {
      'analytics': analytics,
      'reviewPromptReadiness': reviewStats,
      'overallHealth': _calculateAppHealth(analytics, reviewStats),
    };
  }

  /// アプリ健全性スコアを計算
  static Map<String, dynamic> _calculateAppHealth(
    Map<String, dynamic> analytics,
    Map<String, dynamic> reviewStats,
  ) {
    final engagement = analytics['userEngagement'] as Map<String, dynamic>;
    final retention = analytics['retention'] as Map<String, dynamic>;

    final engagementScore = engagement['engagementScore'] as double;
    final retentionRate = retention['retentionRate'] as double;
    final daysSinceInstall = reviewStats['daysSinceInstall'] as int;

    // 健全性スコア計算
    double healthScore = 0;
    healthScore += engagementScore * 0.4; // エンゲージメント40%
    healthScore += retentionRate * 100 * 0.3; // リテンション30%
    healthScore +=
        (daysSinceInstall > 7 ? 30 : daysSinceInstall * 4.3); // 継続性30%

    String healthStatus;
    if (healthScore >= 80) {
      healthStatus = 'Excellent';
    } else if (healthScore >= 60) {
      healthStatus = 'Good';
    } else if (healthScore >= 40) {
      healthStatus = 'Fair';
    } else {
      healthStatus = 'Poor';
    }

    return {
      'score': healthScore.clamp(0, 100),
      'status': healthStatus,
      'recommendations': _getHealthRecommendations(healthScore, analytics),
    };
  }

  /// 健全性改善提案を生成
  static List<String> _getHealthRecommendations(
    double healthScore,
    Map<String, dynamic> analytics,
  ) {
    final recommendations = <String>[];

    if (healthScore < 60) {
      recommendations.add('ユーザーエンゲージメントの向上が必要');
      recommendations.add('新機能の追加やUI改善を検討');
    }

    final retention = analytics['retention'] as Map<String, dynamic>;
    final retentionRate = retention['retentionRate'] as double;

    if (retentionRate < 0.3) {
      recommendations.add('ユーザーリテンションの改善が必要');
      recommendations.add('プッシュ通知や定期的な更新の検討');
    }

    final swipeAnalysis = analytics['swipeAnalysis'] as Map<String, dynamic>;
    final rightSwipeRate = swipeAnalysis['rightSwipeRate'] as double;

    if (rightSwipeRate < 0.3) {
      recommendations.add('店舗の魅力度向上やおすすめアルゴリズムの改善');
    }

    return recommendations;
  }

  /// ASO統合レポートの生成（管理者向け）
  static Future<Map<String, dynamic>> generateIntegratedReport() async {
    final performance = await getPerformanceMetrics();
    final keywordAnalysis =
        await AsoAnalyticsService.analyzeKeywordEffectiveness();

    return {
      'reportType': 'ASO_INTEGRATED_REPORT',
      'generatedAt': DateTime.now().toIso8601String(),
      'performance': performance,
      'keywordAnalysis': keywordAnalysis,
      'actionItems': _generateActionItems(performance, keywordAnalysis),
    };
  }

  /// アクションアイテム生成
  static List<Map<String, dynamic>> _generateActionItems(
    Map<String, dynamic> performance,
    Map<String, dynamic> keywordAnalysis,
  ) {
    final actionItems = <Map<String, dynamic>>[];

    final healthInfo = performance['overallHealth'] as Map<String, dynamic>;
    final healthScore = healthInfo['score'] as double;

    if (healthScore < 70) {
      actionItems.add({
        'priority': 'HIGH',
        'category': 'User Experience',
        'action': 'ユーザーエンゲージメントの改善',
        'description': '健全性スコアが${healthScore.toStringAsFixed(1)}と低いため、UX改善が必要',
      });
    }

    final recommendations = keywordAnalysis['recommendations'] as List<String>;
    if (recommendations.isNotEmpty) {
      actionItems.add({
        'priority': 'MEDIUM',
        'category': 'ASO Keywords',
        'action': 'キーワード戦略の最適化',
        'description': recommendations.join(', '),
      });
    }

    return actionItems;
  }
}
