import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/config/search_config.dart';

void main() {
  group('SearchConfig Tests', () {
    test('should have correct default values', () {
      expect(SearchConfig.defaultKeyword, '中華');
      expect(SearchConfig.defaultRange, 3);
      expect(SearchConfig.defaultCount, 20);
      expect(SearchConfig.defaultStart, 1);
      expect(SearchConfig.minCount, 1);
      expect(SearchConfig.maxCount, 100);
      expect(SearchConfig.defaultPageSize, 20);
      expect(SearchConfig.minStart, 1);
      expect(SearchConfig.maxStart, 1000);
    });

    test('should validate range values correctly', () {
      expect(SearchConfig.isValidRange(1), true);
      expect(SearchConfig.isValidRange(3), true);
      expect(SearchConfig.isValidRange(5), true);
      expect(SearchConfig.isValidRange(0), false);
      expect(SearchConfig.isValidRange(6), false);
      expect(SearchConfig.isValidRange(-1), false);
    });

    test('should validate count values correctly', () {
      expect(SearchConfig.isValidCount(1), true);
      expect(SearchConfig.isValidCount(50), true);
      expect(SearchConfig.isValidCount(100), true);
      expect(SearchConfig.isValidCount(0), false);
      expect(SearchConfig.isValidCount(-1), false);
      expect(SearchConfig.isValidCount(101), false);
    });

    test('should validate start values correctly', () {
      expect(SearchConfig.isValidStart(1), true);
      expect(SearchConfig.isValidStart(500), true);
      expect(SearchConfig.isValidStart(1000), true);
      expect(SearchConfig.isValidStart(0), false);
      expect(SearchConfig.isValidStart(-1), false);
      expect(SearchConfig.isValidStart(1001), false);
    });

    test('should validate keyword values correctly', () {
      expect(SearchConfig.isValidKeyword('中華'), true);
      expect(SearchConfig.isValidKeyword('ラーメン'), true);
      expect(SearchConfig.isValidKeyword(''), false);
      expect(SearchConfig.isValidKeyword('a' * 101), false);
      expect(SearchConfig.isValidKeyword('a' * 100), true);
    });

    test('should validate allowed keywords correctly', () {
      expect(SearchConfig.isAllowedKeyword('中華'), true);
      expect(SearchConfig.isAllowedKeyword('中華料理'), true);
      expect(SearchConfig.isAllowedKeyword('町中華'), true);
      expect(SearchConfig.isAllowedKeyword('餃子'), true);
      expect(SearchConfig.isAllowedKeyword('ラーメン'), true);
      expect(SearchConfig.isAllowedKeyword('炒飯'), true);
      expect(SearchConfig.isAllowedKeyword('炒め物'), true);
      expect(SearchConfig.isAllowedKeyword('麺類'), true);
      expect(SearchConfig.isAllowedKeyword('定食'), true);
      expect(SearchConfig.isAllowedKeyword('イタリアン'), false);
      expect(SearchConfig.isAllowedKeyword('フレンチ'), false);
    });

    test('should convert range to meters correctly', () {
      expect(SearchConfig.rangeToMeter(1), 300);
      expect(SearchConfig.rangeToMeter(2), 500);
      expect(SearchConfig.rangeToMeter(3), 1000);
      expect(SearchConfig.rangeToMeter(4), 2000);
      expect(SearchConfig.rangeToMeter(5), 3000);
      expect(SearchConfig.rangeToMeter(6), null);
      expect(SearchConfig.rangeToMeter(0), null);
    });

    test('should convert meter to range correctly', () {
      expect(SearchConfig.meterToRange(300), 1);
      expect(SearchConfig.meterToRange(500), 2);
      expect(SearchConfig.meterToRange(1000), 3);
      expect(SearchConfig.meterToRange(2000), 4);
      expect(SearchConfig.meterToRange(3000), 5);
      expect(SearchConfig.meterToRange(1500), null);
      expect(SearchConfig.meterToRange(100), null);
    });

    test('should validate budget range correctly', () {
      expect(SearchConfig.isValidBudgetRange('～500円'), true);
      expect(SearchConfig.isValidBudgetRange('501～1000円'), true);
      expect(SearchConfig.isValidBudgetRange('1001～1500円'), true);
      expect(SearchConfig.isValidBudgetRange('1501～2000円'), true);
      expect(SearchConfig.isValidBudgetRange('2001～3000円'), true);
      expect(SearchConfig.isValidBudgetRange('3001～4000円'), true);
      expect(SearchConfig.isValidBudgetRange('4001～5000円'), true);
      expect(SearchConfig.isValidBudgetRange('5001円～'), true);
      expect(SearchConfig.isValidBudgetRange('無効な範囲'), false);
    });

    test('should validate sort option correctly', () {
      expect(SearchConfig.isValidSortOption('distance'), true);
      expect(SearchConfig.isValidSortOption('rating'), true);
      expect(SearchConfig.isValidSortOption('budget'), true);
      expect(SearchConfig.isValidSortOption('name'), true);
      expect(SearchConfig.isValidSortOption('invalid'), false);
    });

    test('should provide comprehensive debug info', () {
      final debugInfo = SearchConfig.debugInfo;

      expect(debugInfo, isA<Map<String, dynamic>>());
      expect(debugInfo['defaultKeyword'], isA<String>());
      expect(debugInfo['defaultRange'], isA<int>());
      expect(debugInfo['defaultCount'], isA<int>());
      expect(debugInfo['defaultStart'], isA<int>());
      expect(debugInfo['rangeToMeters'], isA<Map>());
      expect(debugInfo['allowedKeywords'], isA<List>());
      expect(debugInfo['budgetRanges'], isA<List>());
      expect(debugInfo['sortOptions'], isA<List>());
    });

    test('should have correct range to meters mapping', () {
      final rangeToMeters = SearchConfig.rangeToMeters;

      expect(rangeToMeters[1], 300);
      expect(rangeToMeters[2], 500);
      expect(rangeToMeters[3], 1000);
      expect(rangeToMeters[4], 2000);
      expect(rangeToMeters[5], 3000);
      expect(rangeToMeters.length, 5);
    });

    test('should have correct allowed keywords list', () {
      final allowedKeywords = SearchConfig.allowedKeywords;

      expect(allowedKeywords, contains('中華'));
      expect(allowedKeywords, contains('中華料理'));
      expect(allowedKeywords, contains('町中華'));
      expect(allowedKeywords, contains('餃子'));
      expect(allowedKeywords, contains('ラーメン'));
      expect(allowedKeywords, contains('炒飯'));
      expect(allowedKeywords, contains('炒め物'));
      expect(allowedKeywords, contains('麺類'));
      expect(allowedKeywords, contains('定食'));
    });

    test('should have correct budget ranges list', () {
      final budgetRanges = SearchConfig.budgetRanges;

      expect(budgetRanges, contains('～500円'));
      expect(budgetRanges, contains('501～1000円'));
      expect(budgetRanges, contains('1001～1500円'));
      expect(budgetRanges, contains('1501～2000円'));
      expect(budgetRanges, contains('2001～3000円'));
      expect(budgetRanges, contains('3001～4000円'));
      expect(budgetRanges, contains('4001～5000円'));
      expect(budgetRanges, contains('5001円～'));
    });

    test('should have correct sort options list', () {
      final sortOptions = SearchConfig.sortOptions;

      expect(sortOptions, contains('distance'));
      expect(sortOptions, contains('rating'));
      expect(sortOptions, contains('budget'));
      expect(sortOptions, contains('name'));
    });
  });
}
