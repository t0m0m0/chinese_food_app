import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/constants/string_constants.dart';

void main() {
  group('StringConstants', () {
    test('should provide default search keyword', () {
      expect(StringConstants.defaultSearchKeyword, equals('中華'));
    });

    test('should provide search genre name', () {
      expect(StringConstants.searchGenreName, equals('中華料理'));
    });

    test('should provide town chinese keyword', () {
      expect(StringConstants.townChineseKeyword, equals('町中華'));
    });

    test('should provide app names', () {
      expect(StringConstants.appShortName, equals('マチアプ'));
      expect(StringConstants.appFullName, equals('町中華探索アプリ「マチアプ」'));
      expect(StringConstants.appDescription, equals('中華料理店を発見・記録するグルメアプリ'));
    });

    test('should provide UI labels', () {
      expect(StringConstants.searchButtonLabel, equals('中華料理店を検索'));
      expect(StringConstants.noResultsMessage, equals('検索ボタンを押して中華料理店を探しましょう'));
    });

    test('should provide store-related constants', () {
      expect(StringConstants.testStoreName, equals('テスト中華料理店'));
      expect(StringConstants.sampleStorePrefix, equals('町中華'));
    });

    test('should provide API keyword parameter', () {
      expect(StringConstants.apiKeywordParameter, equals('中華'));
    });

    test('should provide search keywords list', () {
      expect(StringConstants.searchKeywords, isA<List<String>>());
      expect(StringConstants.searchKeywords, contains('中華'));
      expect(StringConstants.searchKeywords, contains('中華料理'));
      expect(StringConstants.searchKeywords, contains('町中華'));
    });

    test('should provide allowed keywords list', () {
      expect(StringConstants.allowedKeywords, isA<List<String>>());
      expect(StringConstants.allowedKeywords, contains('中華'));
      expect(StringConstants.allowedKeywords, contains('中華料理'));
      expect(StringConstants.allowedKeywords, contains('町中華'));
    });

    test('should provide genre mapping', () {
      expect(StringConstants.genreMapping, isA<Map<String, String>>());
      expect(StringConstants.genreMapping['chinese'], equals('中華料理'));
      expect(StringConstants.genreMapping['townChinese'], equals('町中華'));
    });

    test('should provide search filters', () {
      expect(StringConstants.searchFilters, isA<Map<String, String>>());
      expect(StringConstants.searchFilters['cuisine_type'], equals('中華料理'));
      expect(
          StringConstants.searchFilters['establishment_type'], equals('町中華'));
    });

    test('should provide debug store name template', () {
      expect(StringConstants.debugStoreNameTemplate, equals('テスト中華料理店'));
    });

    test('should have consistent keyword usage', () {
      // デフォルト検索キーワードは許可されたキーワードリストに含まれるべき
      expect(StringConstants.allowedKeywords,
          contains(StringConstants.defaultSearchKeyword));

      // APIキーワードは検索キーワードリストに含まれるべき
      expect(StringConstants.searchKeywords,
          contains(StringConstants.apiKeywordParameter));
    });

    test('should provide review-related messages', () {
      expect(StringConstants.reviewPromptMessage, equals('あなたの町中華探索はいかがですか？'));
      expect(
          StringConstants.reviewThanksMessage, equals('これからも町中華探索をお楽しみください。'));
    });
  });
}
