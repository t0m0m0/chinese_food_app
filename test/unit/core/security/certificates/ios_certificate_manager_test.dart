import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/security/certificates/ios_certificate_manager.dart';
import 'package:chinese_food_app/core/security/certificates/certificate_config.dart';
import '../../../../helpers/test_env_setup.dart';

void main() {
  group('IosCertificateManager', () {
    late IosCertificateManager certificateManager;

    setUpAll(() async {
      await TestEnvSetup.initializeTestEnvironment();
    });

    setUp(() {
      certificateManager = IosCertificateManager();
    });

    tearDown(() {
      // テスト後のクリーンアップ
    });

    group('Certificate Configuration Validation', () {
      test('should validate complete iOS certificate configuration', () {
        // Arrange
        const config = IosCertificateConfig(
          teamId: 'ABC123DEF4',
          bundleId: 'com.example.chinese_food_app',
          certificateName: 'iPhone Distribution',
          provisioningProfileName: 'App Store Profile',
        );

        // Act
        final result = certificateManager.validateConfiguration(config);

        // Assert
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should fail validation when team ID is empty', () {
        // Arrange
        const config = IosCertificateConfig(
          teamId: '',
          bundleId: 'com.example.chinese_food_app',
          certificateName: 'iPhone Distribution',
          provisioningProfileName: 'App Store Profile',
        );

        // Act
        final result = certificateManager.validateConfiguration(config);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.errors, contains('チームIDが設定されていません'));
      });

      test('should fail validation when bundle ID is invalid', () {
        // Arrange
        const config = IosCertificateConfig(
          teamId: 'ABC123DEF4',
          bundleId: 'invalid_bundle_id',
          certificateName: 'iPhone Distribution',
          provisioningProfileName: 'App Store Profile',
        );

        // Act
        final result = certificateManager.validateConfiguration(config);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.errors, contains('バンドルIDの形式が無効です'));
      });
    });

    group('Environment Variables Loading', () {
      test('should handle missing iOS environment variables gracefully', () {
        // Act & Assert
        expect(
          () => certificateManager.loadFromEnvironment(),
          throwsA(isA<CertificateConfigurationException>()),
        );
      });
    });

    group('Certificate Status Check', () {
      test('should check iOS certificate expiration date', () async {
        // Arrange
        const config = IosCertificateConfig(
          teamId: 'ABC123DEF4',
          bundleId: 'com.example.chinese_food_app',
          certificateName: 'iPhone Distribution',
          provisioningProfileName: 'App Store Profile',
        );

        // Act
        final status = await certificateManager.checkCertificateStatus(config);

        // Assert
        expect(status, isNotNull);
        expect(status.isExpired, isFalse);
        expect(status.expirationDate, isNotNull);
      });
    });

    group('Provisioning Profile Management', () {
      test('should validate provisioning profile configuration', () {
        // Arrange
        const config = IosCertificateConfig(
          teamId: 'ABC123DEF4',
          bundleId: 'com.example.chinese_food_app',
          certificateName: 'iPhone Distribution',
          provisioningProfileName: 'App Store Profile',
        );

        // Act
        final isValid = certificateManager.validateProvisioningProfile(config);

        // Assert
        expect(isValid, isTrue);
      });
    });
  });
}
