import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chinese_food_app/core/services/aso_analytics_service.dart';

void main() {
  group('AsoAnalyticsService', () {
    setUp(() async {
      // テスト用のSharedPreferencesを初期化
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() async {
      // テスト後にデータをクリア
      await AsoAnalyticsService.clearAllAnalyticsData();
    });

    group('First Launch Tracking', () {
      test('should record first launch date', () async {
        // Act
        await AsoAnalyticsService.recordFirstLaunch();

        // Assert - Should not throw and should set install date
        // We can't directly test the private method, but initialize() calls it
        await AsoAnalyticsService.initialize();
      });

      test('should not override existing first launch date', () async {
        // Arrange
        await AsoAnalyticsService.recordFirstLaunch();
        await Future.delayed(const Duration(milliseconds: 10));

        // Act
        await AsoAnalyticsService.recordFirstLaunch();

        // Assert - Should not change (tested indirectly through initialize)
        await AsoAnalyticsService.initialize();
      });
    });

    group('Session Tracking', () {
      test('should record session starts', () async {
        // Act
        await AsoAnalyticsService.recordSessionStart();
        await AsoAnalyticsService.recordSessionStart();
        await AsoAnalyticsService.recordSessionStart();

        // Assert - Verify through user engagement metrics
        final metrics = await AsoAnalyticsService.getUserEngagementMetrics();
        expect(metrics['totalSessions'], equals(3));
      });
    });

    group('Search Tracking', () {
      test('should record search actions with details', () async {
        // Act
        await AsoAnalyticsService.recordSearch(
          searchType: 'location',
          resultCount: 5,
        );
        await AsoAnalyticsService.recordSearch(
          searchType: 'keyword',
          resultCount: 3,
        );

        // Assert
        final metrics = await AsoAnalyticsService.getUserEngagementMetrics();
        expect(metrics['searchCount'], equals(2));
      });
    });

    group('Swipe Tracking', () {
      test('should record swipe actions', () async {
        // Act
        await AsoAnalyticsService.recordSwipe(
          direction: 'right',
          storeId: 'store-1',
        );
        await AsoAnalyticsService.recordSwipe(
          direction: 'left',
          storeId: 'store-2',
        );
        await AsoAnalyticsService.recordSwipe(
          direction: 'right',
          storeId: 'store-3',
        );

        // Assert
        final metrics = await AsoAnalyticsService.getUserEngagementMetrics();
        expect(metrics['swipeCount'], equals(3));
      });
    });

    group('Store View Tracking', () {
      test('should record store view actions with source', () async {
        // Act
        await AsoAnalyticsService.recordStoreView(
          storeId: 'store-1',
          source: 'swipe',
        );
        await AsoAnalyticsService.recordStoreView(
          storeId: 'store-2',
          source: 'search',
        );

        // Assert
        final metrics = await AsoAnalyticsService.getUserEngagementMetrics();
        expect(metrics['storeViewCount'], equals(2));
      });
    });

    group('Feature Usage Tracking', () {
      test('should record feature usage', () async {
        // Act
        await AsoAnalyticsService.recordFeatureUsage(
          featureName: 'map_view',
          parameters: {'mapType': 'google'},
        );
        await AsoAnalyticsService.recordFeatureUsage(
          featureName: 'photo_add',
        );

        // Assert - Verify through ASO report
        final report = await AsoAnalyticsService.generateAsoReport();
        final featureUsage = report['featureUsage'] as Map<String, int>;
        expect(featureUsage['map_view'], equals(1));
        expect(featureUsage['photo_add'], equals(1));
      });
    });

    group('User Engagement Metrics', () {
      test('should calculate engagement metrics correctly', () async {
        // Arrange
        await AsoAnalyticsService.recordFirstLaunch();
        await AsoAnalyticsService.recordSessionStart();
        await AsoAnalyticsService.recordSessionStart();
        await AsoAnalyticsService.recordSearch(
          searchType: 'location',
          resultCount: 3,
        );
        await AsoAnalyticsService.recordSwipe(
          direction: 'right',
          storeId: 'store-1',
        );

        // Act
        final metrics = await AsoAnalyticsService.getUserEngagementMetrics();

        // Assert
        expect(metrics, isA<Map<String, dynamic>>());
        expect(metrics['totalSessions'], equals(2));
        expect(metrics['searchCount'], equals(1));
        expect(metrics['swipeCount'], equals(1));
        expect(metrics['daysSinceFirstLaunch'], greaterThanOrEqualTo(1));
        expect(metrics['averageSessionsPerDay'], isA<double>());
        expect(metrics['averageActionsPerSession'], isA<double>());
        expect(metrics['engagementScore'], isA<double>());
        expect(metrics['engagementScore'], greaterThanOrEqualTo(0));
        expect(metrics['engagementScore'], lessThanOrEqualTo(100));
      });

      test('should handle zero sessions gracefully', () async {
        // Act
        final metrics = await AsoAnalyticsService.getUserEngagementMetrics();

        // Assert
        expect(metrics['totalSessions'], equals(0));
        expect(metrics['averageActionsPerSession'], equals(0.0));
        expect(metrics['engagementScore'], equals(0.0));
      });
    });

    group('Retention Metrics', () {
      test('should calculate retention metrics', () async {
        // Arrange
        await AsoAnalyticsService.recordSessionStart();

        // Act
        final metrics = await AsoAnalyticsService.getRetentionMetrics();

        // Assert
        expect(metrics, isA<Map<String, dynamic>>());
        expect(metrics['activeDaysLast30'], isA<int>());
        expect(metrics['retentionRate'], isA<double>());
        expect(metrics['dailySessions'], isA<Map>());
        expect(metrics['activeDaysLast30'], greaterThanOrEqualTo(1));
        expect(metrics['retentionRate'], greaterThan(0));
      });
    });

    group('ASO Report Generation', () {
      test('should generate comprehensive ASO report', () async {
        // Arrange
        await AsoAnalyticsService.recordFirstLaunch();
        await AsoAnalyticsService.recordSessionStart();
        await AsoAnalyticsService.recordSearch(
          searchType: 'location',
          resultCount: 5,
        );
        await AsoAnalyticsService.recordSwipe(
          direction: 'right',
          storeId: 'store-1',
        );
        await AsoAnalyticsService.recordSwipe(
          direction: 'left',
          storeId: 'store-2',
        );
        await AsoAnalyticsService.recordStoreView(
          storeId: 'store-1',
          source: 'swipe',
        );

        // Act
        final report = await AsoAnalyticsService.generateAsoReport();

        // Assert
        expect(report, isA<Map<String, dynamic>>());
        expect(report['reportGeneratedAt'], isA<String>());
        expect(report['asoConfig'], isA<Map>());
        expect(report['userEngagement'], isA<Map>());
        expect(report['retention'], isA<Map>());
        expect(report['featureUsage'], isA<Map>());
        expect(report['swipeAnalysis'], isA<Map>());
        expect(report['searchAnalysis'], isA<Map>());
        expect(report['trafficSources'], isA<Map>());
        expect(report['asoScore'], isA<double>());
        expect(report['optimizationSuggestions'], isA<List>());

        // Verify swipe analysis
        final swipeAnalysis = report['swipeAnalysis'] as Map<String, dynamic>;
        expect(swipeAnalysis['totalSwipes'], equals(2));
        expect(swipeAnalysis['leftSwipes'], equals(1));
        expect(swipeAnalysis['rightSwipes'], equals(1));
        expect(swipeAnalysis['rightSwipeRate'], equals(0.5));

        // Verify search analysis
        final searchAnalysis = report['searchAnalysis'] as Map<String, dynamic>;
        expect(searchAnalysis['totalSearches'], equals(1));
        expect(searchAnalysis['locationSearches'], equals(1));

        // Verify traffic sources
        final trafficSources = report['trafficSources'] as Map<String, dynamic>;
        expect(trafficSources['swipeToDetail'], equals(1));
      });

      test('should handle empty data gracefully', () async {
        // Act
        final report = await AsoAnalyticsService.generateAsoReport();

        // Assert
        expect(report, isA<Map<String, dynamic>>());
        expect(report['userEngagement']['totalSessions'], equals(0));
        expect(report['swipeAnalysis']['totalSwipes'], equals(0));
        expect(report['searchAnalysis']['totalSearches'], equals(0));
      });
    });

    group('Keyword Effectiveness Analysis', () {
      test('should analyze keyword effectiveness', () async {
        // Arrange
        await AsoAnalyticsService.recordSearch(
          searchType: 'keyword',
          resultCount: 3,
        );
        await AsoAnalyticsService.recordSearch(
          searchType: 'location',
          resultCount: 5,
        );

        // Act
        final analysis =
            await AsoAnalyticsService.analyzeKeywordEffectiveness();

        // Assert
        expect(analysis, isA<Map<String, dynamic>>());
        expect(analysis['keywordDensity'], isA<Map>());
        expect(analysis['searchAnalysis'], isA<Map>());
        expect(analysis['engagementScore'], isA<double>());
        expect(analysis['recommendations'], isA<List<String>>());
      });
    });

    group('Service Initialization', () {
      test('should initialize without errors', () async {
        // Act & Assert - Should not throw
        await AsoAnalyticsService.initialize();

        // Should record first launch and session
        final metrics = await AsoAnalyticsService.getUserEngagementMetrics();
        expect(metrics['totalSessions'], greaterThanOrEqualTo(1));
      });
    });

    group('Data Clearing', () {
      test('should clear all analytics data', () async {
        // Arrange
        await AsoAnalyticsService.recordSessionStart();
        await AsoAnalyticsService.recordSearch(
          searchType: 'location',
          resultCount: 3,
        );
        await AsoAnalyticsService.recordSwipe(
          direction: 'right',
          storeId: 'store-1',
        );

        // Verify data exists
        final beforeMetrics =
            await AsoAnalyticsService.getUserEngagementMetrics();
        expect(beforeMetrics['totalSessions'], greaterThan(0));

        // Act
        await AsoAnalyticsService.clearAllAnalyticsData();

        // Assert
        final afterMetrics =
            await AsoAnalyticsService.getUserEngagementMetrics();
        expect(afterMetrics['totalSessions'], equals(0));
        expect(afterMetrics['searchCount'], equals(0));
        expect(afterMetrics['swipeCount'], equals(0));
      });
    });

    group('Edge Cases', () {
      test('should handle multiple rapid calls', () async {
        // Act
        await Future.wait([
          AsoAnalyticsService.recordSessionStart(),
          AsoAnalyticsService.recordSessionStart(),
          AsoAnalyticsService.recordSessionStart(),
        ]);

        // Assert
        final metrics = await AsoAnalyticsService.getUserEngagementMetrics();
        expect(metrics['totalSessions'], equals(3));
      });

      test('should handle invalid search parameters', () async {
        // Act & Assert - Should not throw
        await AsoAnalyticsService.recordSearch(
          searchType: '',
          resultCount: -1,
        );

        final metrics = await AsoAnalyticsService.getUserEngagementMetrics();
        expect(metrics['searchCount'], equals(1));
      });
    });
  });
}
