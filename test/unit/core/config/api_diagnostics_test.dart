import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/config/api_diagnostics.dart';
import '../../../helpers/test_env_setup.dart';

void main() {
  group('ApiDiagnostics', () {
    setUp(() async {
      await TestEnvSetup.initializeTestEnvironment();
    });

    tearDown(() {
      TestEnvSetup.cleanupTestEnvironment();
    });

    test('should provide comprehensive API configuration status', () async {
      // Arrange
      TestEnvSetup.setTestApiKey('HOTPEPPER_API_KEY', 'test_key_123');
      ApiDiagnostics.clearCache(); // キャッシュをクリア

      // Act
      final diagnostics = await ApiDiagnostics.getComprehensiveDiagnostics();

      // Assert
      expect(diagnostics.isConfigValid, isTrue);
      expect(diagnostics.hotpepperApiKeyStatus, equals('available'));
      expect(diagnostics.initializationStatus, equals('initialized'));
      expect(diagnostics.securityMode, equals('legacy'));
    });

    test('should detect missing API key', () async {
      // Arrange
      TestEnvSetup.clearTestApiKey('HOTPEPPER_API_KEY');
      ApiDiagnostics.clearCache(); // キャッシュをクリアして確実に新しい診断を実行

      // Act
      final diagnostics = await ApiDiagnostics.getComprehensiveDiagnostics();

      // Assert
      expect(diagnostics.isConfigValid, isFalse);
      expect(diagnostics.hotpepperApiKeyStatus, equals('missing'));
      expect(diagnostics.issues, contains('HotPepper APIキーが設定されていません'));
    });

    test('should provide detailed configuration info', () async {
      // Arrange
      TestEnvSetup.setTestApiKey('HOTPEPPER_API_KEY', 'valid_key');
      ApiDiagnostics.clearCache(); // キャッシュをクリア

      // Act
      final diagnostics = await ApiDiagnostics.getComprehensiveDiagnostics();

      // Assert
      expect(diagnostics.environment, isNotEmpty);
      expect(diagnostics.timestamp, isNotNull);
      expect(diagnostics.suggestions, isNotEmpty);
    });

    test('should use cached results when available', () async {
      // Arrange
      TestEnvSetup.setTestApiKey('HOTPEPPER_API_KEY', 'test_cache_key');
      ApiDiagnostics.clearCache(); // 確実にキャッシュをクリア

      // Act - 初回実行
      final firstResult = await ApiDiagnostics.getComprehensiveDiagnostics();
      final firstTimestamp = firstResult.timestamp;

      // わずかに待機してタイムスタンプの差を作る
      await Future.delayed(const Duration(milliseconds: 10));

      // Act - 2回目実行（キャッシュから取得されるべき）
      final secondResult = await ApiDiagnostics.getComprehensiveDiagnostics();
      final secondTimestamp = secondResult.timestamp;

      // Assert
      expect(firstTimestamp, equals(secondTimestamp), reason: 'キャッシュが使用されるべき');
      expect(firstResult.isConfigValid, equals(secondResult.isConfigValid));
    });

    test('should refresh cache when forceRefresh is true', () async {
      // Arrange
      TestEnvSetup.setTestApiKey('HOTPEPPER_API_KEY', 'test_refresh_key');
      ApiDiagnostics.clearCache();

      // Act - 初回実行
      final firstResult = await ApiDiagnostics.getComprehensiveDiagnostics();
      final firstTimestamp = firstResult.timestamp;

      await Future.delayed(const Duration(milliseconds: 10));

      // Act - 強制リフレッシュ
      final refreshedResult = await ApiDiagnostics.getComprehensiveDiagnostics(
        forceRefresh: true,
      );
      final refreshedTimestamp = refreshedResult.timestamp;

      // Assert
      expect(firstTimestamp, isNot(equals(refreshedTimestamp)),
          reason: '強制リフレッシュで新しい結果が取得されるべき');
    });

    test('should clear cache properly', () async {
      // Arrange
      TestEnvSetup.setTestApiKey('HOTPEPPER_API_KEY', 'test_clear_key');

      // キャッシュを作成
      await ApiDiagnostics.getComprehensiveDiagnostics();

      // Act
      ApiDiagnostics.clearCache();

      // 新しい診断実行
      final result = await ApiDiagnostics.getComprehensiveDiagnostics();

      // Assert - エラーが発生しないことを確認
      expect(result.isConfigValid, isTrue);
    });
  });
}
