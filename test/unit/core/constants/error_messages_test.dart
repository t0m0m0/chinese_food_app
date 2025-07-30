import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/constants/error_messages.dart';

void main() {
  group('ErrorMessages Internationalization Tests - QA改善', () {
    test('should return Japanese messages by default', () {
      // 日本語メッセージが正しく取得できることを確認
      expect(
        ErrorMessages.getSecurityMessage('sql_injection_detected'),
        equals('セキュリティ上の理由により、この検索は実行できません'),
      );

      expect(
        ErrorMessages.getDatabaseMessage('store_not_found'),
        equals('店舗が見つかりません'),
      );

      expect(
        ErrorMessages.getGeneralMessage('network_error'),
        equals('ネットワークエラーが発生しました。接続を確認してください'),
      );
    });

    test('should handle undefined message keys gracefully', () {
      // 未定義キーに対する適切なエラーハンドリング
      final result = ErrorMessages.getSecurityMessage('non_existent_key');
      expect(result, contains('Error message not found'));
      expect(result, contains('non_existent_key'));
    });

    test('should provide comprehensive security message coverage', () {
      // セキュリティ関連メッセージの網羅性確認
      final securityKeys = [
        'sql_injection_detected',
        'invalid_input_format',
        'api_key_missing',
        'unauthorized_access',
        'rate_limit_exceeded',
      ];

      for (final key in securityKeys) {
        final message = ErrorMessages.getSecurityMessage(key);
        expect(message.isNotEmpty, isTrue,
            reason: 'Security message for $key should not be empty');
        expect(message, isNot(contains('Error message not found')),
            reason: 'Security message for $key should be properly defined');
      }
    });

    test('should provide comprehensive database message coverage', () {
      // データベース関連メッセージの網羅性確認
      final databaseKeys = [
        'store_not_found',
        'transaction_failed',
        'duplicate_store',
        'database_connection_error',
      ];

      for (final key in databaseKeys) {
        final message = ErrorMessages.getDatabaseMessage(key);
        expect(message.isNotEmpty, isTrue,
            reason: 'Database message for $key should not be empty');
        expect(message, isNot(contains('Error message not found')),
            reason: 'Database message for $key should be properly defined');
      }
    });

    test('should support bilingual messaging structure', () {
      // 将来的な英語対応の構造確認
      expect(ErrorMessages.supportedLanguages, contains('ja'));
      expect(ErrorMessages.supportedLanguages, contains('en'));
      expect(ErrorMessages.currentLanguage, equals('ja'));
    });

    test('should provide debug functionality for message keys', () {
      // デバッグ機能：全メッセージキーの取得
      final allKeys = ErrorMessages.getAllMessageKeys();

      expect(allKeys.isNotEmpty, isTrue,
          reason: 'Should have at least some message keys');

      // 重要なセキュリティキーが含まれていることを確認
      expect(allKeys, contains('sql_injection_detected'));
      expect(allKeys, contains('api_key_missing'));
      expect(allKeys, contains('store_not_found'));
      expect(allKeys, contains('network_error'));
    });

    test('should ensure user-friendly security messages', () {
      // セキュリティメッセージがユーザーフレンドリーであることを確認
      final sqlInjectionMessage =
          ErrorMessages.getSecurityMessage('sql_injection_detected');

      // 技術的な詳細を含まず、ユーザーが理解しやすい内容であることを確認
      expect(sqlInjectionMessage, isNot(contains('SQL')));
      expect(sqlInjectionMessage, isNot(contains('injection')));
      expect(sqlInjectionMessage, contains('セキュリティ'));

      final apiKeyMessage = ErrorMessages.getSecurityMessage('api_key_missing');
      expect(apiKeyMessage, isNot(contains('API key')));
      expect(apiKeyMessage, contains('API設定'));
    });

    test('should maintain consistent message formatting', () {
      // メッセージフォーマットの一貫性確認
      final messages = [
        ErrorMessages.getSecurityMessage('sql_injection_detected'),
        ErrorMessages.getDatabaseMessage('store_not_found'),
        ErrorMessages.getGeneralMessage('network_error'),
      ];

      for (final message in messages) {
        // 適切な長さのメッセージであることを確認
        expect(message.length, greaterThan(5),
            reason: 'Message should be descriptive enough');
        expect(message.length, lessThan(200),
            reason: 'Message should not be too verbose');

        // 日本語文字が含まれていることを確認（現在の言語設定）
        expect(
            RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]')
                .hasMatch(message),
            isTrue,
            reason: 'Japanese message should contain Japanese characters');
      }
    });

    test('should support future internationalization expansion', () {
      // 将来的な国際化拡張のテスト

      // 現在のメッセージ取得が正常動作することを確認
      final currentMessage =
          ErrorMessages.getSecurityMessage('sql_injection_detected');
      expect(currentMessage, equals('セキュリティ上の理由により、この検索は実行できません'));

      // 言語設定の構造が拡張可能であることを確認
      expect(ErrorMessages.supportedLanguages.length, greaterThanOrEqualTo(2));
      expect(ErrorMessages.currentLanguage,
          isIn(ErrorMessages.supportedLanguages));
    });
  });
}
