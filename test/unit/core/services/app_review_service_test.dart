import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chinese_food_app/core/services/app_review_service.dart';
import 'package:chinese_food_app/core/config/aso_config.dart';

void main() {
  group('AppReviewService', () {
    setUp(() async {
      // テスト用のSharedPreferencesを初期化
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() async {
      // テスト後にデータをクリア
      await AppReviewService.clearAllRecords();
    });

    group('Installation Tracking', () {
      test('should record install date on first call', () async {
        // Act
        await AppReviewService.recordInstallDate();
        final daysSince = await AppReviewService.getDaysSinceInstall();

        // Assert
        expect(daysSince, equals(0));
      });

      test('should not override existing install date', () async {
        // Arrange
        await AppReviewService.recordInstallDate();

        // Act - Call again after a delay simulation
        await AppReviewService.recordInstallDate();
        final daysSince = await AppReviewService.getDaysSinceInstall();

        // Assert - Should still be 0 (same day)
        expect(daysSince, equals(0));
      });
    });

    group('Usage Session Tracking', () {
      test('should increment usage session count', () async {
        // Act
        await AppReviewService.incrementUsageSession();
        await AppReviewService.incrementUsageSession();
        await AppReviewService.incrementUsageSession();

        final count = await AppReviewService.getUsageSessionCount();

        // Assert
        expect(count, equals(3));
      });

      test('should start from zero when no data', () async {
        // Act
        final count = await AppReviewService.getUsageSessionCount();

        // Assert
        expect(count, equals(0));
      });
    });

    group('Store Visit Tracking', () {
      test('should increment stores visited count', () async {
        // Act
        await AppReviewService.incrementStoresVisited();
        await AppReviewService.incrementStoresVisited();

        final count = await AppReviewService.getStoresVisitedCount();

        // Assert
        expect(count, equals(2));
      });
    });

    group('Review Status Tracking', () {
      test('should track review completion', () async {
        // Act
        await AppReviewService.markReviewCompleted();

        // Assert
        expect(await AppReviewService.isReviewCompleted(), isTrue);
        expect(await AppReviewService.isReviewDeclined(), isFalse);
      });

      test('should track review decline', () async {
        // Act
        await AppReviewService.markReviewDeclined();

        // Assert
        expect(await AppReviewService.isReviewDeclined(), isTrue);
        expect(await AppReviewService.isReviewCompleted(), isFalse);
      });

      test('should track days since last prompt', () async {
        // Act
        await AppReviewService.markReviewDeclined();
        final daysSince = await AppReviewService.getDaysSinceLastPrompt();

        // Assert
        expect(daysSince, equals(0));
      });
    });

    group('Review Prompt Logic', () {
      test('should not show prompt when review completed', () async {
        // Arrange
        await _setUpReviewConditions();
        await AppReviewService.markReviewCompleted();

        // Act
        final shouldShow = await AppReviewService.shouldShowReviewPrompt();

        // Assert
        expect(shouldShow, isFalse);
      });

      test('should not show prompt when recently declined', () async {
        // Arrange
        await _setUpReviewConditions();
        await AppReviewService.markReviewDeclined();

        // Act
        final shouldShow = await AppReviewService.shouldShowReviewPrompt();

        // Assert
        expect(shouldShow, isFalse);
      });

      test('should show prompt when all conditions met', () async {
        // Arrange - Set up conditions that meet all requirements
        await AppReviewService.recordInstallDate();

        // Simulate passing enough days
        final prefs = await SharedPreferences.getInstance();
        final pastDate = DateTime.now()
            .subtract(Duration(days: AsoConfig.daysSinceInstallForReview + 1))
            .millisecondsSinceEpoch;
        await prefs.setInt('app_install_date', pastDate);

        // Set required usage
        for (int i = 0; i < AsoConfig.minUsageSessionsForReview; i++) {
          await AppReviewService.incrementUsageSession();
        }

        for (int i = 0; i < AsoConfig.minStoresVisitedForReview; i++) {
          await AppReviewService.incrementStoresVisited();
        }

        // Act
        final shouldShow = await AppReviewService.shouldShowReviewPrompt();

        // Assert
        expect(shouldShow, isTrue);
      });

      test('should not show prompt when insufficient usage', () async {
        // Arrange
        await AppReviewService.recordInstallDate();
        // Don't increment usage enough

        // Act
        final shouldShow = await AppReviewService.shouldShowReviewPrompt();

        // Assert
        expect(shouldShow, isFalse);
      });

      test('should not show prompt when too soon after install', () async {
        // Arrange
        await AppReviewService.recordInstallDate(); // Today
        await _setUsageRequirements();

        // Act
        final shouldShow = await AppReviewService.shouldShowReviewPrompt();

        // Assert
        expect(shouldShow, isFalse);
      });
    });

    group('User Statistics', () {
      test('should provide comprehensive user usage stats', () async {
        // Arrange
        await AppReviewService.recordInstallDate();
        await AppReviewService.incrementUsageSession();
        await AppReviewService.incrementUsageSession();
        await AppReviewService.incrementStoresVisited();

        // Act
        final stats = await AppReviewService.getUserUsageStats();

        // Assert
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats['usageSessionCount'], equals(2));
        expect(stats['storesVisitedCount'], equals(1));
        expect(stats['daysSinceInstall'], equals(0));
        expect(stats['isReviewCompleted'], isFalse);
        expect(stats['isReviewDeclined'], isFalse);
        expect(stats['shouldShowReviewPrompt'], isA<bool>());
      });
    });

    group('Review Trigger Helper', () {
      test('should trigger review check on actions', () async {
        // Arrange
        await _setUpReviewConditions();

        // Act
        final shouldShow = await AppReviewService.checkReviewTrigger(
          isStoreVisited: true,
          isSessionStarted: true,
        );

        // Assert
        expect(shouldShow, isA<bool>());
        expect(await AppReviewService.getUsageSessionCount(), greaterThan(0));
        expect(await AppReviewService.getStoresVisitedCount(), greaterThan(0));
      });
    });

    group('Review Message', () {
      test('should provide localized review prompt message', () {
        // Act
        final message = AppReviewService.getReviewPromptMessage();

        // Assert
        expect(message, isNotEmpty);
        expect(message, contains(AsoConfig.appShortName));
        expect(message, contains('ありがとうございます'));
        expect(message, contains('レビュー'));
      });
    });

    group('Initialization', () {
      test('should initialize properly', () async {
        // Act & Assert - Should not throw
        await AppReviewService.initialize();

        // Should record install date
        final daysSince = await AppReviewService.getDaysSinceInstall();
        expect(daysSince, equals(0));
      });
    });

    group('Debug Functions', () {
      test('should clear all records in debug mode', () async {
        // Arrange
        await AppReviewService.incrementUsageSession();
        await AppReviewService.incrementStoresVisited();
        await AppReviewService.markReviewCompleted();

        // Act
        await AppReviewService.clearAllRecords();

        // Assert
        expect(await AppReviewService.getUsageSessionCount(), equals(0));
        expect(await AppReviewService.getStoresVisitedCount(), equals(0));
        expect(await AppReviewService.isReviewCompleted(), isFalse);
      });

      test('should trigger review prompt in debug mode', () async {
        // Act
        await AppReviewService.triggerReviewPrompt();

        // Assert
        final shouldShow = await AppReviewService.shouldShowReviewPrompt();
        expect(shouldShow, isTrue);

        final stats = await AppReviewService.getUserUsageStats();
        expect(stats['usageSessionCount'],
            equals(AsoConfig.minUsageSessionsForReview));
        expect(stats['storesVisitedCount'],
            equals(AsoConfig.minStoresVisitedForReview));
      });
    });
  });
}

/// テスト用ヘルパー：レビュー条件を満たすようにセットアップ
Future<void> _setUpReviewConditions() async {
  final prefs = await SharedPreferences.getInstance();

  // 十分な日数が経過したことをシミュレート
  final daysToSubtract = AsoConfig.daysSinceInstallForReview + 1;
  final pastDate = DateTime.now()
      .subtract(Duration(days: daysToSubtract))
      .millisecondsSinceEpoch;
  await prefs.setInt('app_install_date', pastDate);

  // 必要な使用回数を設定
  await _setUsageRequirements();
}

/// テスト用ヘルパー：使用要件を満たす
Future<void> _setUsageRequirements() async {
  for (int i = 0; i < AsoConfig.minUsageSessionsForReview; i++) {
    await AppReviewService.incrementUsageSession();
  }

  for (int i = 0; i < AsoConfig.minStoresVisitedForReview; i++) {
    await AppReviewService.incrementStoresVisited();
  }
}
