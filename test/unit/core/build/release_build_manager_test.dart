import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/build/release_build_manager.dart';
import 'package:chinese_food_app/core/build/release_build_config.dart';
import '../../../helpers/test_env_setup.dart';

void main() {
  group('ReleaseBuildManager', () {
    late ReleaseBuildManager buildManager;

    setUpAll(() async {
      await TestEnvSetup.initializeTestEnvironment();
    });

    setUp(() {
      buildManager = ReleaseBuildManager();
    });

    tearDown(() {
      // テスト後のクリーンアップ
    });

    group('Android Release Build Management', () {
      test('should validate Android release configuration', () {
        // Arrange
        const androidConfig = AndroidReleaseBuildConfig(
          applicationId: 'com.example.chinese_food_app',
          versionName: '1.0.0',
          versionCode: 1,
          minSdkVersion: 21,
          targetSdkVersion: 33,
          enableProguard: true,
          enableShrinkResources: true,
        );

        // Act
        final result = buildManager.validateAndroidConfiguration(androidConfig);

        // Assert
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should generate Android build gradle configuration', () {
        // Arrange
        const androidConfig = AndroidReleaseBuildConfig(
          applicationId: 'com.example.chinese_food_app',
          versionName: '1.0.0',
          versionCode: 1,
          minSdkVersion: 21,
          targetSdkVersion: 33,
          enableProguard: true,
          enableShrinkResources: true,
        );

        // Act
        final gradleConfig =
            buildManager.generateAndroidGradleConfig(androidConfig);

        // Assert
        expect(gradleConfig, isNotNull);
        expect(gradleConfig,
            contains('applicationId "com.example.chinese_food_app"'));
        expect(gradleConfig, contains('versionName "1.0.0"'));
        expect(gradleConfig, contains('versionCode 1'));
        expect(gradleConfig, contains('minSdkVersion 21'));
        expect(gradleConfig, contains('targetSdkVersion 33'));
      });
    });

    group('iOS Release Build Management', () {
      test('should validate iOS release configuration', () {
        // Arrange
        const iosConfig = IosReleaseBuildConfig(
          bundleId: 'com.example.chinese-food-app',
          version: '1.0.0',
          buildNumber: '1',
          deploymentTarget: '12.0',
          enableBitcode: false,
          enableSwiftOptimization: true,
        );

        // Act
        final result = buildManager.validateIosConfiguration(iosConfig);

        // Assert
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should generate iOS Info.plist configuration', () {
        // Arrange
        const iosConfig = IosReleaseBuildConfig(
          bundleId: 'com.example.chinese-food-app',
          version: '1.0.0',
          buildNumber: '1',
          deploymentTarget: '12.0',
          enableBitcode: false,
          enableSwiftOptimization: true,
        );

        // Act
        final plistConfig = buildManager.generateIosPlistConfig(iosConfig);

        // Assert
        expect(plistConfig, isNotNull);
        expect(plistConfig,
            contains('<string>com.example.chinese-food-app</string>'));
        expect(plistConfig, contains('<string>1.0.0</string>'));
        expect(plistConfig, contains('<string>1</string>'));
      });
    });

    group('Cross-Platform Build Management', () {
      test('should generate comprehensive build report', () {
        // Arrange
        const androidConfig = AndroidReleaseBuildConfig(
          applicationId: 'com.example.chinese_food_app',
          versionName: '1.0.0',
          versionCode: 1,
          minSdkVersion: 21,
          targetSdkVersion: 33,
          enableProguard: true,
          enableShrinkResources: true,
        );

        const iosConfig = IosReleaseBuildConfig(
          bundleId: 'com.example.chinese-food-app',
          version: '1.0.0',
          buildNumber: '1',
          deploymentTarget: '12.0',
          enableBitcode: false,
          enableSwiftOptimization: true,
        );

        // Act
        final buildReport =
            buildManager.generateBuildReport(androidConfig, iosConfig);

        // Assert
        expect(buildReport, isNotNull);
        expect(buildReport.androidValid, isTrue);
        expect(buildReport.iosValid, isTrue);
        expect(buildReport.isReadyForRelease, isTrue);
      });

      test('should handle build environment validation', () {
        // Act
        final environmentValidation = buildManager.validateBuildEnvironment();

        // Assert
        expect(environmentValidation, isNotNull);
        expect(environmentValidation.flutterSDKAvailable, isTrue);
      });
    });
  });
}
