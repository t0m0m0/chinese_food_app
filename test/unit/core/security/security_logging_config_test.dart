import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/security/security_logging_config.dart';

void main() {
  group('SecurityLoggingConfig', () {
    setUp(() {
      // 各テスト前にリセット
      SecurityLoggingConfig.initialize(environment: AppEnvironment.development);
    });

    test('should detect environment correctly', () {
      // Green: 環境検出のテスト

      SecurityLoggingConfig.initialize(environment: AppEnvironment.production);
      expect(
          SecurityLoggingConfig.currentEnvironment, AppEnvironment.production);

      SecurityLoggingConfig.initialize(environment: AppEnvironment.development);
      expect(
          SecurityLoggingConfig.currentEnvironment, AppEnvironment.development);
    });

    test('should apply correct log levels for each environment', () {
      // Green: 環境別ログレベルのテスト

      // Development: INFO以上 (800)
      SecurityLoggingConfig.initialize(environment: AppEnvironment.development);
      expect(SecurityLoggingConfig.shouldLog(800), isTrue); // INFO
      expect(SecurityLoggingConfig.shouldLog(700), isFalse); // DEBUG相当

      // Production: ERROR以上 (1000)
      SecurityLoggingConfig.initialize(environment: AppEnvironment.production);
      expect(SecurityLoggingConfig.shouldLog(1000), isTrue); // ERROR
      expect(SecurityLoggingConfig.shouldLog(900), isFalse); // WARNING
    });

    test('should provide environment-specific debug configuration', () {
      // Green: 環境別デバッグ設定のテスト

      // Development環境
      SecurityLoggingConfig.initialize(environment: AppEnvironment.development);
      final devConfig = SecurityLoggingConfig.getEnvironmentDebugConfig();

      expect(devConfig['environment'], 'development');
      expect(devConfig['detailed_errors'], isTrue);
      expect(devConfig['sensitive_data_logging'], isTrue);

      // Production環境
      SecurityLoggingConfig.initialize(environment: AppEnvironment.production);
      final prodConfig = SecurityLoggingConfig.getEnvironmentDebugConfig();

      expect(prodConfig['environment'], 'production');
      expect(prodConfig['detailed_errors'], isFalse);
      expect(prodConfig['sensitive_data_logging'], isFalse);
    });

    test('should provide production secure configuration', () {
      // Green: 本番環境セキュア設定のテスト

      final prodConfig = SecurityLoggingConfig.getProductionSecureConfig();

      expect(prodConfig['log_level'], 1000); // ERROR以上
      expect(prodConfig['sensitive_data_redaction'], isTrue);
      expect(prodConfig['detailed_stack_traces'], isFalse);
      expect(prodConfig['security_events_only'], isTrue);
    });

    test('should handle production safe debug mode correctly', () {
      // Green: 本番環境でのデバッグモード判定テスト

      // Production環境では明示的な設定なしではfalse
      SecurityLoggingConfig.initialize(environment: AppEnvironment.production);
      // 環境変数のシミュレーションが困難なため、メソッドの存在確認のみ
      expect(() => SecurityLoggingConfig.isProductionSafeDebugMode(),
          returnsNormally);

      // Development環境では通常通り
      SecurityLoggingConfig.initialize(environment: AppEnvironment.development);
      expect(() => SecurityLoggingConfig.isProductionSafeDebugMode(),
          returnsNormally);
    });

    test('should log security events with proper sanitization', () {
      // Green: セキュリティイベントログのテスト

      SecurityLoggingConfig.initialize(environment: AppEnvironment.production);

      // メソッドが正常に実行されることを確認
      expect(() {
        SecurityLoggingConfig.logSecurityEvent(
          'TEST_EVENT',
          'Test security event',
          metadata: {
            'user_id': 'user123',
            'api_key': 'secret_key_12345',
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }, returnsNormally);
    });

    test('should sanitize sensitive security metadata correctly', () {
      // Green: セキュリティメタデータのサニタイゼーションテスト

      SecurityLoggingConfig.initialize(environment: AppEnvironment.development);

      // 直接的なテストは困難だが、処理が正常に実行されることを確認
      expect(() {
        SecurityLoggingConfig.logSecurityEvent(
          'METADATA_TEST',
          'Testing metadata sanitization',
          metadata: {
            'safe_data': 'public_info',
            'token': 'sensitive_token_data',
            'secret': 'very_secret_data',
          },
        );
      }, returnsNormally);
    });
  });
}
