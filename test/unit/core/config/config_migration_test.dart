import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/config/app_config.dart';
import 'package:chinese_food_app/core/config/config_manager.dart';

void main() {
  group('ConfigManager to AppConfig Migration Tests', () {
    setUp(() {
      AppConfig.resetInitialization();
      AppConfig.clearTestApiKey();
    });

    tearDown(() {
      AppConfig.resetInitialization();
      AppConfig.clearTestApiKey();
    });

    group('Initialization migration', () {
      test(
          'AppConfig.isInitialized should work like ConfigManager.isInitialized',
          () async {
        // 初期化前は両方ともfalse
        expect(AppConfig.isInitialized, isFalse);
        expect(ConfigManager.isInitialized, isFalse);

        // AppConfig初期化後は両方ともtrue
        await AppConfig.initialize();
        expect(AppConfig.isInitialized, isTrue);
        expect(ConfigManager.isInitialized, isTrue);
      });

      test('AppConfig.initialize should work like ConfigManager.initialize',
          () async {
        await AppConfig.initialize();

        // 両方初期化されている状態
        expect(AppConfig.isInitialized, isTrue);
        expect(ConfigManager.isInitialized, isTrue);
      });
    });

    group('API key access migration', () {
      test(
          'AppConfig.api.hotpepperApiKey should work like ConfigManager.hotpepperApiKey',
          () async {
        await AppConfig.initialize();

        final appConfigKey = AppConfig.api.hotpepperApiKey;
        final configManagerKey = ConfigManager.hotpepperApiKey;

        // 両方とも同じ値を返すべき（ConfigManagerのデフォルトキーまたは設定値）
        expect(appConfigKey, equals(configManagerKey));
      });
    });

    group('Validation migration', () {
      test(
          'AppConfig.validateAll should provide similar structure to ConfigManager.validateAllConfigs',
          () async {
        await AppConfig.initialize();

        final appConfigResults = AppConfig.validateAll();
        final configManagerResults = ConfigManager.validateAllConfigs();

        // 両方とも同じキーを持つべき
        expect(appConfigResults.keys, contains('api'));
        expect(configManagerResults.keys, contains('api'));

        // データ構造は同じ（Map<String, List<String>>）
        expect(appConfigResults, isA<Map<String, List<String>>>());
        expect(configManagerResults, isA<Map<String, List<String>>>());
      });

      test('AppConfig.isValid should reflect validation state', () async {
        await AppConfig.initialize();

        final isValid = AppConfig.isValid;
        final errors = AppConfig.validationErrors;

        // 有効な場合はエラーが空
        if (isValid) {
          expect(errors, isEmpty);
        } else {
          expect(errors, isNotEmpty);
        }
      });
    });

    group('Debug information migration', () {
      test('AppConfig.debugInfo should provide comprehensive information',
          () async {
        await AppConfig.initialize();

        final appConfigDebug = AppConfig.debugInfo;
        final configManagerDebug = ConfigManager.debugString;

        expect(appConfigDebug, isA<Map<String, dynamic>>());
        expect(appConfigDebug.keys, contains('initialized'));
        expect(appConfigDebug.keys, contains('api'));
        expect(appConfigDebug.keys, contains('ui'));
        expect(appConfigDebug.keys, contains('database'));
        expect(appConfigDebug.keys, contains('location'));
        expect(appConfigDebug.keys, contains('search'));

        // ConfigManagerのdebugStringは文字列なので、AppConfigのより構造化されている
        expect(configManagerDebug, isA<String>());
      });
    });

    group('Backward compatibility', () {
      test(
          'Old ConfigManager methods should still work after AppConfig initialization',
          () async {
        await AppConfig.initialize();

        // ConfigManagerの古いメソッドも動作すべき
        expect(ConfigManager.isInitialized, isTrue);
        expect(ConfigManager.hotpepperApiKey, isA<String>());
        expect(ConfigManager.isDevelopment, isA<bool>());
        expect(ConfigManager.isProduction, isA<bool>());
      });

      test('Both systems should provide consistent environment detection',
          () async {
        await AppConfig.initialize();

        expect(AppConfig.isDevelopment, equals(ConfigManager.isDevelopment));
        expect(AppConfig.isProduction, equals(ConfigManager.isProduction));
      });
    });
  });
}
