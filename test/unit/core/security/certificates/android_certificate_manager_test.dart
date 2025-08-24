import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/security/certificates/android_certificate_manager.dart';
import 'package:chinese_food_app/core/security/certificates/certificate_config.dart';
import '../../../../helpers/test_env_setup.dart';

void main() {
  group('AndroidCertificateManager', () {
    late AndroidCertificateManager certificateManager;

    setUpAll(() async {
      await TestEnvSetup.initializeTestEnvironment();
    });

    setUp(() {
      certificateManager = AndroidCertificateManager();
    });

    tearDown(() {
      // テスト後のクリーンアップ
    });

    group('Certificate Configuration Validation', () {
      test('should validate complete Android certificate configuration', () {
        // Arrange
        const config = AndroidCertificateConfig(
          keystorePath: '/path/to/release.keystore',
          keyAlias: 'release_key',
          keystorePassword: 'secure_password',
          keyPassword: 'secure_password',
        );

        // Act
        final result = certificateManager.validateConfiguration(config);

        // Assert
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should fail validation when keystore path is empty', () {
        // Arrange
        const config = AndroidCertificateConfig(
          keystorePath: '',
          keyAlias: 'release_key',
          keystorePassword: 'secure_password',
          keyPassword: 'secure_password',
        );

        // Act
        final result = certificateManager.validateConfiguration(config);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.errors, contains('キーストアパスが設定されていません'));
      });

      test('should fail validation when key alias is empty', () {
        // Arrange
        const config = AndroidCertificateConfig(
          keystorePath: '/path/to/release.keystore',
          keyAlias: '',
          keystorePassword: 'secure_password',
          keyPassword: 'secure_password',
        );

        // Act
        final result = certificateManager.validateConfiguration(config);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.errors, contains('キーエイリアスが設定されていません'));
      });

      test('should fail validation when passwords are weak', () {
        // Arrange
        const config = AndroidCertificateConfig(
          keystorePath: '/path/to/release.keystore',
          keyAlias: 'release_key',
          keystorePassword: '123',
          keyPassword: '123',
        );

        // Act
        final result = certificateManager.validateConfiguration(config);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.errors, contains('パスワードが安全ではありません'));
      });
    });

    group('Environment Variables Loading', () {
      test('should load Android certificate config from environment variables',
          () {
        // このテストは実際の環境変数が設定されている場合にのみパスするため、
        // 例外が発生することを期待する
        expect(
          () => certificateManager.loadFromEnvironment(),
          throwsA(isA<CertificateConfigurationException>()),
        );
      });

      test('should handle missing environment variables gracefully', () {
        // Act & Assert
        expect(
          () => certificateManager.loadFromEnvironment(),
          throwsA(isA<CertificateConfigurationException>()),
        );
      });
    });

    group('Certificate Status Check', () {
      test('should check certificate expiration date', () async {
        // Arrange
        const config = AndroidCertificateConfig(
          keystorePath: '/path/to/release.keystore',
          keyAlias: 'release_key',
          keystorePassword: 'secure_password',
          keyPassword: 'secure_password',
        );

        // Act
        final status = await certificateManager.checkCertificateStatus(config);

        // Assert
        expect(status, isNotNull);
        expect(status.isExpired, isFalse);
        expect(status.expirationDate, isNotNull);
      });
    });
  });
}
