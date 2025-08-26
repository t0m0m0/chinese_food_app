import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:chinese_food_app/core/config/aso_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// アプリレビュー促進サービス
/// ASO最適化の一環として、適切なタイミングでユーザーにレビューを促す
class AppReviewService {
  static const String _keyInstallDate = 'app_install_date';
  static const String _keyUsageSessionCount = 'usage_session_count';
  static const String _keyStoresVisited = 'stores_visited_count';
  static const String _keyLastReviewPrompt = 'last_review_prompt_date';
  static const String _keyReviewCompleted = 'review_completed';
  static const String _keyReviewDeclined = 'review_declined';

  /// アプリインストール日を記録
  static Future<void> recordInstallDate() async {
    final prefs = await SharedPreferences.getInstance();

    if (!prefs.containsKey(_keyInstallDate)) {
      await prefs.setInt(
          _keyInstallDate, DateTime.now().millisecondsSinceEpoch);
    }
  }

  /// 使用セッション数を増加
  static Future<void> incrementUsageSession() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_keyUsageSessionCount) ?? 0;
    await prefs.setInt(_keyUsageSessionCount, currentCount + 1);
  }

  /// 訪問店舗数を増加
  static Future<void> incrementStoresVisited() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_keyStoresVisited) ?? 0;
    await prefs.setInt(_keyStoresVisited, currentCount + 1);
  }

  /// レビューが完了したことを記録
  static Future<void> markReviewCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReviewCompleted, true);
    await prefs.setInt(
        _keyLastReviewPrompt, DateTime.now().millisecondsSinceEpoch);
  }

  /// レビューが拒否されたことを記録
  static Future<void> markReviewDeclined() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReviewDeclined, true);
    await prefs.setInt(
        _keyLastReviewPrompt, DateTime.now().millisecondsSinceEpoch);
  }

  /// インストールからの経過日数を取得
  static Future<int> getDaysSinceInstall() async {
    final prefs = await SharedPreferences.getInstance();
    final installDateMs = prefs.getInt(_keyInstallDate);

    if (installDateMs == null) {
      // インストール日が記録されていない場合は今日を基準とする
      await recordInstallDate();
      return 0;
    }

    final installDate = DateTime.fromMillisecondsSinceEpoch(installDateMs);
    final daysSince = DateTime.now().difference(installDate).inDays;
    return daysSince;
  }

  /// 使用セッション数を取得
  static Future<int> getUsageSessionCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUsageSessionCount) ?? 0;
  }

  /// 訪問店舗数を取得
  static Future<int> getStoresVisitedCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyStoresVisited) ?? 0;
  }

  /// 最後のレビュープロンプトからの経過日数を取得
  static Future<int> getDaysSinceLastPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPromptMs = prefs.getInt(_keyLastReviewPrompt);

    if (lastPromptMs == null) {
      return 999; // プロンプト表示履歴なし
    }

    final lastPrompt = DateTime.fromMillisecondsSinceEpoch(lastPromptMs);
    return DateTime.now().difference(lastPrompt).inDays;
  }

  /// レビュー完了済みかチェック
  static Future<bool> isReviewCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyReviewCompleted) ?? false;
  }

  /// レビュー拒否済みかチェック
  static Future<bool> isReviewDeclined() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyReviewDeclined) ?? false;
  }

  /// レビュープロンプト表示の判定
  static Future<bool> shouldShowReviewPrompt() async {
    // 既にレビューが完了している場合は表示しない
    if (await isReviewCompleted()) {
      return false;
    }

    // 前回拒否されてから十分な期間が経過していない場合は表示しない
    if (await isReviewDeclined()) {
      final daysSinceLastPrompt = await getDaysSinceLastPrompt();
      if (daysSinceLastPrompt < AsoConfig.daysBetweenReviewPrompts) {
        return false;
      }
    }

    // すべての条件をチェック
    final daysSinceInstall = await getDaysSinceInstall();
    final usageSessionCount = await getUsageSessionCount();
    final storesVisitedCount = await getStoresVisitedCount();
    final daysSinceLastPrompt = await getDaysSinceLastPrompt();

    final shouldShow =
        daysSinceInstall >= AsoConfig.daysSinceInstallForReview &&
            usageSessionCount >= AsoConfig.minUsageSessionsForReview &&
            storesVisitedCount >= AsoConfig.minStoresVisitedForReview &&
            daysSinceLastPrompt >= AsoConfig.daysBetweenReviewPrompts;

    return shouldShow;
  }

  /// アプリストアのレビューページを開く
  static Future<void> openAppStoreReview() async {
    try {
      if (Platform.isAndroid) {
        // Google Play Storeのレビューページを開く
        await _openPlayStoreReview();
      } else if (Platform.isIOS) {
        // App Storeのレビューページを開く
        await _openAppStoreReview();
      }

      // レビューページを開いた記録
      await markReviewCompleted();
    } catch (e) {
      // レビューページのオープンに失敗した場合のログ
      debugPrint('Failed to open app store review: $e');
    }
  }

  /// App Storeのレビューページを開く（iOS）
  static Future<void> _openAppStoreReview() async {
    const platform = MethodChannel('app_review_channel');
    try {
      await platform.invokeMethod('openAppStoreReview');
    } on PlatformException catch (e) {
      debugPrint('Failed to open App Store review: ${e.message}');
      rethrow;
    }
  }

  /// Google Play Storeのレビューページを開く（Android）
  static Future<void> _openPlayStoreReview() async {
    const platform = MethodChannel('app_review_channel');
    try {
      await platform.invokeMethod('openPlayStoreReview');
    } on PlatformException catch (e) {
      debugPrint('Failed to open Play Store review: ${e.message}');
      rethrow;
    }
  }

  /// レビュー促進ダイアログのメッセージ取得
  static String getReviewPromptMessage() {
    return '''
${AsoConfig.appShortName}をご利用いただき、ありがとうございます！

あなたの町中華探索はいかがですか？
もしアプリを気に入っていただけましたら、ぜひレビューをお聞かせください。

あなたの声が、より良いアプリ作りの励みになります！
''';
  }

  /// ユーザーの使用統計を取得
  static Future<Map<String, dynamic>> getUserUsageStats() async {
    return {
      'daysSinceInstall': await getDaysSinceInstall(),
      'usageSessionCount': await getUsageSessionCount(),
      'storesVisitedCount': await getStoresVisitedCount(),
      'daysSinceLastPrompt': await getDaysSinceLastPrompt(),
      'isReviewCompleted': await isReviewCompleted(),
      'isReviewDeclined': await isReviewDeclined(),
      'shouldShowReviewPrompt': await shouldShowReviewPrompt(),
    };
  }

  /// レビュー促進システムの初期化
  static Future<void> initialize() async {
    await recordInstallDate();
  }

  /// レビュー促進の適切なタイミングかチェック（ヘルパー関数）
  static Future<bool> checkReviewTrigger({
    required bool isStoreVisited,
    required bool isSessionStarted,
  }) async {
    if (isSessionStarted) {
      await incrementUsageSession();
    }

    if (isStoreVisited) {
      await incrementStoresVisited();
    }

    return await shouldShowReviewPrompt();
  }

  /// デバッグ用：すべての記録をクリア
  static Future<void> clearAllRecords() async {
    if (kDebugMode) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyInstallDate);
      await prefs.remove(_keyUsageSessionCount);
      await prefs.remove(_keyStoresVisited);
      await prefs.remove(_keyLastReviewPrompt);
      await prefs.remove(_keyReviewCompleted);
      await prefs.remove(_keyReviewDeclined);
    }
  }

  /// デバッグ用：強制的にレビュープロンプト条件を満たす
  static Future<void> triggerReviewPrompt() async {
    if (kDebugMode) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          _keyUsageSessionCount, AsoConfig.minUsageSessionsForReview);
      await prefs.setInt(
          _keyStoresVisited, AsoConfig.minStoresVisitedForReview);
      final daysToSubtract = AsoConfig.daysSinceInstallForReview + 1;
      await prefs.setInt(
          _keyInstallDate,
          DateTime.now()
              .subtract(Duration(days: daysToSubtract))
              .millisecondsSinceEpoch);
      await prefs.remove(_keyLastReviewPrompt);
      await prefs.remove(_keyReviewCompleted);
      await prefs.remove(_keyReviewDeclined);
    }
  }
}
