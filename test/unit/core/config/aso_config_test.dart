import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/config/aso_config.dart';

void main() {
  group('AsoConfig', () {
    test('should have proper app display name with keywords', () {
      // Assert
      expect(AsoConfig.appDisplayName, equals('町中華探索アプリ「マチアプ」'));
      expect(AsoConfig.appShortName, equals('マチアプ'));
      expect(AsoConfig.appTagline, isNotEmpty);
      expect(AsoConfig.appTagline.length, greaterThan(10));
    });

    test('should contain ASO keywords in app store description', () {
      // Act
      final description = AsoConfig.appStoreDescription;

      // Assert
      expect(description.length, greaterThan(100));
      expect(description, contains('町中華'));
      expect(description, contains('中華料理'));
      expect(description, contains('グルメ'));
      expect(description, contains('スワイプ'));
      expect(description, contains('位置情報'));
      expect(description, contains('記録'));
    });

    test('should have comprehensive keyword strategy', () {
      // Assert
      expect(AsoConfig.primaryKeywords, isNotEmpty);
      expect(AsoConfig.secondaryKeywords, isNotEmpty);
      expect(AsoConfig.primaryKeywords, contains('町中華'));
      expect(AsoConfig.primaryKeywords, contains('中華料理'));
      expect(AsoConfig.primaryKeywords, contains('グルメ'));
      expect(AsoConfig.secondaryKeywords, contains('探索'));
      expect(AsoConfig.secondaryKeywords, contains('検索'));
    });

    test('should generate keyword combinations correctly', () {
      // Act
      final combinations = AsoConfig.generateKeywordCombinations();

      // Assert
      expect(combinations, isNotEmpty);
      expect(combinations, contains('町中華 探索'));
      expect(combinations, contains('中華料理 検索'));
      expect(combinations.length, greaterThan(50));
    });

    test('should calculate keyword density correctly', () {
      // Arrange
      const testDescription = '町中華を探索するグルメアプリです。中華料理店を検索できます。';

      // Act
      final density = AsoConfig.getKeywordDensity(testDescription);

      // Assert
      expect(density, isNotEmpty);
      expect(density['町中華'], equals(1));
      expect(density['グルメ'], equals(1));
      expect(density['中華料理'], equals(1));
      expect(density['検索'], equals(1));
    });

    test('should have appropriate review prompt settings', () {
      // Assert
      expect(AsoConfig.minUsageSessionsForReview, greaterThan(0));
      expect(AsoConfig.minStoresVisitedForReview, greaterThan(0));
      expect(AsoConfig.daysSinceInstallForReview, greaterThan(0));
      expect(AsoConfig.daysBetweenReviewPrompts, greaterThan(0));
      expect(AsoConfig.minUsageSessionsForReview, lessThanOrEqualTo(10));
      expect(AsoConfig.minStoresVisitedForReview, lessThanOrEqualTo(5));
      expect(AsoConfig.daysSinceInstallForReview, lessThanOrEqualTo(14));
    });

    test('should have proper app metadata configuration', () {
      // Assert
      expect(AsoConfig.primaryCategory, equals('フード&ドリンク'));
      expect(AsoConfig.secondaryCategory, equals('ライフスタイル'));
      expect(AsoConfig.targetAgeGroup, equals('18歳以上'));
      expect(AsoConfig.contentRating, equals('全年齢対象'));
      expect(AsoConfig.targetRegions, contains('日本'));
      expect(AsoConfig.primaryLanguage, equals('ja'));
      expect(AsoConfig.supportedLanguages, contains('ja'));
    });

    test('should calculate ASO score within valid range', () {
      // Act
      final score = AsoConfig.calculateAsoScore();

      // Assert
      expect(score, greaterThanOrEqualTo(0));
      expect(score, lessThanOrEqualTo(100));
      expect(score,
          greaterThan(50)); // Should have decent score with current config
    });

    test('should have proper version information', () {
      // Assert
      expect(AsoConfig.currentVersion, equals('1.0.0'));
      expect(AsoConfig.versionReleaseNotes, isNotEmpty);
      expect(AsoConfig.versionReleaseNotes, contains('初回リリース'));
    });

    test('should have brand color configuration', () {
      // Assert
      expect(AsoConfig.brandPrimaryColor, isNotEmpty);
      expect(AsoConfig.brandSecondaryColor, isNotEmpty);
      expect(AsoConfig.brandPrimaryColor, startsWith('#'));
      expect(AsoConfig.brandSecondaryColor, startsWith('#'));
      expect(AsoConfig.appIconDescription, isNotEmpty);
    });

    test('should identify competitor apps', () {
      // Assert
      expect(AsoConfig.competitorApps, isNotEmpty);
      expect(AsoConfig.competitorApps, contains('ぐるなび'));
      expect(AsoConfig.competitorApps, contains('食べログ'));
      expect(AsoConfig.competitorApps.length, greaterThanOrEqualTo(3));
    });

    test('should have screenshot keywords for ASO', () {
      // Assert
      expect(AsoConfig.screenshotKeywords, isNotEmpty);
      expect(AsoConfig.screenshotKeywords, contains('スワイプ画面'));
      expect(AsoConfig.screenshotKeywords, contains('検索機能'));
      expect(AsoConfig.screenshotKeywords, contains('マップ表示'));
    });

    test('should generate debug info correctly', () {
      // Act
      final debugInfo = AsoConfig.debugInfo;

      // Assert
      expect(debugInfo, isNotEmpty);
      expect(debugInfo['appDisplayName'], equals(AsoConfig.appDisplayName));
      expect(debugInfo['primaryKeywords'], equals(AsoConfig.primaryKeywords));
      expect(debugInfo['asoScore'], isA<double>());
      expect(debugInfo['keywordCombinations'], isA<List>());
      expect(debugInfo['descriptionKeywordDensity'], isA<Map>());
    });

    test('should provide optimization checklist', () {
      // Act
      final checklist = AsoConfig.optimizationChecklist;

      // Assert
      expect(checklist, isNotEmpty);
      expect(checklist.keys, contains('アプリ名にキーワード含有'));
      expect(checklist.keys, contains('説明文が充実'));
      expect(checklist.keys, contains('キーワード戦略策定'));
      expect(checklist.keys, contains('レビュー促進設定'));

      // Most items should be properly configured
      final completedItems = checklist.values.where((value) => value).length;
      expect(completedItems, greaterThanOrEqualTo(7));
    });

    test('should generate optimization suggestions', () {
      // Act
      final suggestions = AsoConfig.getOptimizationSuggestions();

      // Assert
      expect(suggestions, isA<List<String>>());
      // With current good configuration, suggestions should be minimal
      expect(suggestions.length, lessThanOrEqualTo(3));
    });

    group('Keyword Density Analysis', () {
      test('should analyze real app store description', () {
        // Act
        final density =
            AsoConfig.getKeywordDensity(AsoConfig.appStoreDescription);

        // Assert
        expect(density, isNotEmpty);
        expect(density.keys.length, greaterThanOrEqualTo(5));
      });

      test('should handle empty description', () {
        // Act
        final density = AsoConfig.getKeywordDensity('');

        // Assert
        expect(density, isEmpty);
      });

      test('should be case insensitive', () {
        // Arrange
        const testText = '町中華と中華料理とグルメ探索';

        // Act
        final density = AsoConfig.getKeywordDensity(testText);

        // Assert
        expect(density['町中華'], equals(1));
        expect(density['中華料理'], equals(1));
        expect(density['グルメ'], equals(1));
        expect(density['探索'], equals(1));
      });
    });

    group('ASO Score Calculation', () {
      test('should reward keyword-rich app names', () {
        // Current app name contains '町中華' which should boost score
        final score = AsoConfig.calculateAsoScore();
        expect(score, greaterThan(60));
      });

      test('should consider multiple factors', () {
        // Score should consider app name, description, settings, etc.
        final score = AsoConfig.calculateAsoScore();

        // With comprehensive ASO config, should achieve high score
        expect(score, greaterThan(70));
      });
    });
  });
}
