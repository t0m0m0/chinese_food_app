import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/security/security_audit_manager.dart';
import 'package:chinese_food_app/core/security/certificates/certificate_config.dart';
import 'package:chinese_food_app/core/build/release_build_config.dart';
import '../../../helpers/test_env_setup.dart';

void main() {
  group('SecurityAuditManager', () {
    late SecurityAuditManager auditManager;

    setUpAll(() async {
      await TestEnvSetup.initializeTestEnvironment();
    });

    setUp(() {
      auditManager = SecurityAuditManager();
    });

    tearDown(() {
      // テスト後のクリーンアップ
    });

    group('Release Security Audit', () {
      test('should perform comprehensive security audit for release build', () {
        // Arrange
        const androidCertConfig = AndroidCertificateConfig(
          keystorePath: '/path/to/release.keystore',
          keyAlias: 'release_key',
          keystorePassword: 'secure_password123',
          keyPassword: 'secure_password123',
        );

        const iosCertConfig = IosCertificateConfig(
          teamId: 'ABC123DEF4',
          bundleId: 'com.example.chinese_food_app',
          certificateName: 'iPhone Distribution',
          provisioningProfileName: 'App Store Profile',
        );

        const androidBuildConfig = AndroidReleaseBuildConfig(
          applicationId: 'com.example.chinese_food_app',
          versionName: '1.0.0',
          versionCode: 1,
          minSdkVersion: 21,
          targetSdkVersion: 33,
          enableProguard: true,
          enableShrinkResources: true,
        );

        const iosBuildConfig = IosReleaseBuildConfig(
          bundleId: 'com.example.chinese-food-app',
          version: '1.0.0',
          buildNumber: '1',
          deploymentTarget: '12.0',
          enableBitcode: false,
          enableSwiftOptimization: true,
        );

        // Act
        final auditResult = auditManager.performSecurityAudit(
          androidCertConfig: androidCertConfig,
          iosCertConfig: iosCertConfig,
          androidBuildConfig: androidBuildConfig,
          iosBuildConfig: iosBuildConfig,
        );

        // Assert
        expect(auditResult, isNotNull);
        expect(auditResult.overallSecurityScore, greaterThan(80));
        expect(auditResult.criticalIssues, isEmpty);
      });

      test(
          'should identify security vulnerabilities in certificate configuration',
          () {
        // Arrange
        const weakAndroidCertConfig = AndroidCertificateConfig(
          keystorePath: '/path/to/release.keystore',
          keyAlias: 'release_key',
          keystorePassword: '123', // 弱いパスワード
          keyPassword: '123', // 弱いパスワード
        );

        // Act
        final auditResult = auditManager.auditCertificateSecurity(
          androidConfig: weakAndroidCertConfig,
        );

        // Assert
        expect(auditResult.securityIssues, isNotEmpty);
        expect(auditResult.securityIssues,
            anyElement(contains('パスワードが安全ではありません')));
        expect(auditResult.securityLevel, equals(SecurityLevel.highRisk));
      });
    });

    group('Environment Security Validation', () {
      test('should validate production environment security settings', () {
        // Arrange
        const securityPolicy = ProductionSecurityPolicy(
          requireStrongPasswords: true,
          enforceEncryption: true,
          enableLogging: false, // 本番環境では無効化
          requireCodeObfuscation: true,
          allowDebugging: false, // 本番環境では禁止
        );

        // Act
        final validation =
            auditManager.validateProductionSecurity(securityPolicy);

        // Assert
        expect(validation.isSecure, isTrue);
        expect(validation.securityViolations, isEmpty);
      });

      test('should detect insecure production environment settings', () {
        // Arrange
        const insecurePolicy = ProductionSecurityPolicy(
          requireStrongPasswords: false,
          enforceEncryption: false,
          enableLogging: true, // 本番環境では危険
          requireCodeObfuscation: false,
          allowDebugging: true, // 本番環境では危険
        );

        // Act
        final validation =
            auditManager.validateProductionSecurity(insecurePolicy);

        // Assert
        expect(validation.isSecure, isFalse);
        expect(validation.securityViolations, isNotEmpty);
        expect(validation.securityViolations, contains('本番環境でデバッグが有効になっています'));
        expect(validation.securityViolations, contains('本番環境でロギングが有効になっています'));
      });
    });

    group('Code Security Analysis', () {
      test('should analyze code security practices', () {
        // Act
        final codeAnalysis = auditManager.analyzeCodeSecurity();

        // Assert
        expect(codeAnalysis, isNotNull);
        expect(codeAnalysis.hasSecureApiHandling, isTrue);
        expect(codeAnalysis.hasProperErrorHandling, isTrue);
        expect(codeAnalysis.hasSecureDataStorage, isTrue);
      });

      test('should generate security recommendations', () {
        // Act
        final recommendations = auditManager.generateSecurityRecommendations();

        // Assert
        expect(recommendations, isNotEmpty);
        expect(recommendations, anyElement(contains('証明書')));
        expect(recommendations, anyElement(contains('パスワード')));
      });
    });
  });
}
