import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/build/release_build_config.dart';
import '../../../helpers/test_env_setup.dart';

void main() {
  group('ReleaseBuildConfig', () {
    setUpAll(() async {
      await TestEnvSetup.initializeTestEnvironment();
    });

    group('Android Release Build Configuration', () {
      test('should create valid Android release configuration', () {
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

        // Act & Assert
        expect(androidConfig.isValid, isTrue);
        expect(androidConfig.validationErrors, isEmpty);
      });

      test('should fail validation when application ID is invalid', () {
        // Arrange
        const androidConfig = AndroidReleaseBuildConfig(
          applicationId: 'invalid_app_id',
          versionName: '1.0.0',
          versionCode: 1,
          minSdkVersion: 21,
          targetSdkVersion: 33,
          enableProguard: true,
          enableShrinkResources: true,
        );

        // Act & Assert
        expect(androidConfig.isValid, isFalse);
        expect(androidConfig.validationErrors, contains('アプリケーションIDの形式が無効です'));
      });

      test('should fail validation when version code is invalid', () {
        // Arrange
        const androidConfig = AndroidReleaseBuildConfig(
          applicationId: 'com.example.chinese_food_app',
          versionName: '1.0.0',
          versionCode: 0,
          minSdkVersion: 21,
          targetSdkVersion: 33,
          enableProguard: true,
          enableShrinkResources: true,
        );

        // Act & Assert
        expect(androidConfig.isValid, isFalse);
        expect(
            androidConfig.validationErrors, contains('バージョンコードは1以上である必要があります'));
      });
    });

    group('iOS Release Build Configuration', () {
      test('should create valid iOS release configuration', () {
        // Arrange
        const iosConfig = IosReleaseBuildConfig(
          bundleId: 'com.example.chinese-food-app',
          version: '1.0.0',
          buildNumber: '1',
          deploymentTarget: '12.0',
          enableBitcode: false,
          enableSwiftOptimization: true,
        );

        // Act & Assert
        expect(iosConfig.isValid, isTrue);
        expect(iosConfig.validationErrors, isEmpty);
      });

      test('should fail validation when bundle ID is invalid', () {
        // Arrange
        const iosConfig = IosReleaseBuildConfig(
          bundleId: 'invalid_bundle',
          version: '1.0.0',
          buildNumber: '1',
          deploymentTarget: '12.0',
          enableBitcode: false,
          enableSwiftOptimization: true,
        );

        // Act & Assert
        expect(iosConfig.isValid, isFalse);
        expect(iosConfig.validationErrors, contains('バンドルIDの形式が無効です'));
      });

      test('should fail validation when deployment target is too old', () {
        // Arrange
        const iosConfig = IosReleaseBuildConfig(
          bundleId: 'com.example.chinese-food-app',
          version: '1.0.0',
          buildNumber: '1',
          deploymentTarget: '9.0',
          enableBitcode: false,
          enableSwiftOptimization: true,
        );

        // Act & Assert
        expect(iosConfig.isValid, isFalse);
        expect(iosConfig.validationErrors,
            contains('デプロイメントターゲットは10.0以上である必要があります'));
      });
    });
  });
}
