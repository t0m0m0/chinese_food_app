import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/config/app_config.dart';
import 'package:chinese_food_app/core/config/api_config.dart';
import 'package:chinese_food_app/core/config/ui_config.dart';
import 'package:chinese_food_app/core/config/database_config.dart';

void main() {
  group('AppConfig', () {
    group('initialization', () {
      test('should initialize successfully with default configuration',
          () async {
        // Red: まず失敗するテストを書く
        await AppConfig.initialize();

        expect(AppConfig.isInitialized, isTrue);
      });

      test('should not allow multiple initialization without force flag',
          () async {
        await AppConfig.initialize();

        // 2回目の初期化は何もしない（例外は投げない）
        await AppConfig.initialize();
        expect(AppConfig.isInitialized, isTrue);
      });

      test('should allow force reinitialization', () async {
        await AppConfig.initialize();
        await AppConfig.initialize(force: true);

        expect(AppConfig.isInitialized, isTrue);
      });
    });

    group('API configuration access', () {
      setUp(() async {
        await AppConfig.initialize(force: true);
      });

      test('should provide unified access to HotPepper API key', () {
        final apiKey = AppConfig.api.hotpepperApiKey;

        expect(apiKey, isNotNull);
        expect(apiKey, isA<String>());
      });

      test('should provide unified access to HotPepper API URL', () {
        final apiUrl = AppConfig.api.hotpepperApiUrl;

        expect(apiUrl, equals(ApiConfig.hotpepperApiUrl));
      });

      test('should provide unified access to API timeout settings', () {
        final timeout = AppConfig.api.hotpepperApiTimeout;

        expect(timeout, equals(ApiConfig.hotpepperApiTimeout));
        expect(timeout, greaterThan(0));
      });
    });

    group('UI configuration access', () {
      setUp(() async {
        await AppConfig.initialize(force: true);
      });

      test('should provide unified access to app name', () {
        final appName = AppConfig.ui.appName;

        expect(appName, equals(UiConfig.appName));
        expect(appName, isNotEmpty);
      });

      test('should provide unified access to padding values', () {
        final defaultPadding = AppConfig.ui.defaultPadding;

        expect(defaultPadding, equals(UiConfig.defaultPadding));
        expect(defaultPadding, greaterThan(0));
      });
    });

    group('database configuration access', () {
      setUp(() async {
        await AppConfig.initialize(force: true);
      });

      test('should provide unified access to database name', () {
        final dbName = AppConfig.database.databaseName;

        expect(dbName, equals(DatabaseConfig.databaseName));
        expect(dbName, isNotEmpty);
      });

      test('should provide unified access to database version', () {
        final dbVersion = AppConfig.database.databaseVersion;

        expect(dbVersion, equals(DatabaseConfig.databaseVersion));
        expect(dbVersion, greaterThan(0));
      });
    });

    group('location configuration access', () {
      setUp(() async {
        await AppConfig.initialize(force: true);
      });

      test('should provide unified access to location accuracy', () {
        final accuracy = AppConfig.location.locationAccuracy;

        expect(accuracy, isNotNull);
      });

      test('should provide unified access to timeout settings', () {
        final timeout = AppConfig.location.locationTimeout;

        expect(timeout, greaterThan(0));
      });
    });

    group('search configuration access', () {
      setUp(() async {
        await AppConfig.initialize(force: true);
      });

      test('should provide unified access to default search range', () {
        final range = AppConfig.search.defaultSearchRange;

        expect(range, greaterThan(0));
      });

      test('should provide unified access to max results', () {
        final maxResults = AppConfig.search.maxResults;

        expect(maxResults, greaterThan(0));
      });
    });

    group('validation', () {
      setUp(() async {
        await AppConfig.initialize(force: true);
      });

      test('should validate all configurations', () {
        final isValid = AppConfig.isValid;

        expect(isValid, isA<bool>());
      });

      test('should detect configuration errors', () {
        final errors = AppConfig.validationErrors;

        expect(errors, isA<List<String>>());
      });

      test('should provide comprehensive validation results', () {
        final validationResults = AppConfig.validateAll();

        expect(validationResults, isA<Map<String, List<String>>>());
        expect(validationResults.keys, contains('api'));
        expect(validationResults.keys, contains('ui'));
        expect(validationResults.keys, contains('database'));
        expect(validationResults.keys, contains('location'));
        expect(validationResults.keys, contains('search'));
      });
    });

    group('debug information', () {
      setUp(() async {
        await AppConfig.initialize(force: true);
      });

      test('should provide debug information', () {
        final debugInfo = AppConfig.debugInfo;

        expect(debugInfo, isA<Map<String, dynamic>>());
        expect(debugInfo.keys, contains('initialized'));
        expect(debugInfo.keys, contains('api'));
        expect(debugInfo.keys, contains('ui'));
        expect(debugInfo.keys, contains('database'));
        expect(debugInfo.keys, contains('location'));
        expect(debugInfo.keys, contains('search'));
      });
    });
  });
}
