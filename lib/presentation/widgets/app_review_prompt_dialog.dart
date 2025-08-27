import 'package:flutter/material.dart';
import 'package:chinese_food_app/core/config/aso_config.dart';
import 'package:chinese_food_app/core/services/app_review_service.dart';

/// アプリレビューを促すダイアログウィジェット
/// ASO最適化の一環として、適切なタイミングでレビューを促進
class AppReviewPromptDialog extends StatelessWidget {
  final VoidCallback? onReviewCompleted;
  final VoidCallback? onReviewDeclined;

  const AppReviewPromptDialog({
    super.key,
    this.onReviewCompleted,
    this.onReviewDeclined,
  });

  /// ダイアログを表示
  static Future<void> show(
    BuildContext context, {
    VoidCallback? onReviewCompleted,
    VoidCallback? onReviewDeclined,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AppReviewPromptDialog(
        onReviewCompleted: onReviewCompleted,
        onReviewDeclined: onReviewDeclined,
      ),
    );
  }

  /// 適切なタイミングかチェックしてダイアログを表示
  static Future<bool> showIfAppropriate(
    BuildContext context, {
    VoidCallback? onReviewCompleted,
    VoidCallback? onReviewDeclined,
  }) async {
    final shouldShow = await AppReviewService.shouldShowReviewPrompt();
    if (shouldShow && context.mounted) {
      await show(
        context,
        onReviewCompleted: onReviewCompleted,
        onReviewDeclined: onReviewDeclined,
      );
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Row(
        children: [
          Icon(
            Icons.star,
            color: Colors.amber,
            size: 28,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'アプリを評価してください',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppReviewService.getReviewPromptMessage(),
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: Colors.amber, size: 20),
              Icon(Icons.star, color: Colors.amber, size: 20),
              Icon(Icons.star, color: Colors.amber, size: 20),
              Icon(Icons.star, color: Colors.amber, size: 20),
              Icon(Icons.star, color: Colors.amber, size: 20),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop();
            await AppReviewService.markReviewDeclined();
            onReviewDeclined?.call();
          },
          child: const Text(
            '後で',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.of(context).pop();
            await AppReviewService.openAppStoreReview();
            onReviewCompleted?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'レビューする',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

/// レビュー促進バナーウィジェット（非侵入的な表示）
class AppReviewBanner extends StatelessWidget {
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const AppReviewBanner({
    super.key,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.amber, Colors.orange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.star_rate_rounded,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '気に入っていただけましたか？',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'レビューでアプリを応援してください',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(
                Icons.close,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// レビューサンクスメッセージウィジェット
class AppReviewThanksDialog extends StatelessWidget {
  const AppReviewThanksDialog({super.key});

  static Future<void> show(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) => const AppReviewThanksDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Row(
        children: [
          Icon(
            Icons.favorite,
            color: Colors.red,
            size: 28,
          ),
          SizedBox(width: 8),
          Text(
            'ありがとうございます！',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
      content: Text(
        'レビューをいただき、ありがとうございます。\nあなたの声が、${AsoConfig.appShortName}をより良くする励みになります！\n\nこれからも町中華探索をお楽しみください。',
        style: const TextStyle(fontSize: 16, height: 1.5),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            '探索を続ける',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

/// レビュー促進用のヘルパークラス
class AppReviewHelper {
  /// アプリ起動時のレビューチェック
  static Future<bool> checkOnAppLaunch(BuildContext context) async {
    await AppReviewService.incrementUsageSession();
    if (context.mounted) {
      return await AppReviewPromptDialog.showIfAppropriate(context);
    }
    return false;
  }

  /// 店舗訪問時のレビューチェック
  static Future<bool> checkOnStoreVisit(BuildContext context) async {
    await AppReviewService.incrementStoresVisited();
    if (context.mounted) {
      return await AppReviewPromptDialog.showIfAppropriate(context);
    }
    return false;
  }

  /// 特定のアクション完了時のレビューチェック
  static Future<bool> checkOnActionComplete(
    BuildContext context, {
    bool incrementSession = false,
    bool incrementStoreVisit = false,
  }) async {
    if (incrementSession) {
      await AppReviewService.incrementUsageSession();
    }

    if (incrementStoreVisit) {
      await AppReviewService.incrementStoresVisited();
    }

    if (context.mounted) {
      return await AppReviewPromptDialog.showIfAppropriate(context);
    }
    return false;
  }
}
