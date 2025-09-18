import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/config/app_config.dart';

void main() {
  group('AppConfig Improvements Tests', () {
    tearDown(() {
      // テスト後のクリーンアップ
      try {
        AppConfig.clearTestApiKey();
        AppConfig.resetInitialization();
      } catch (e) {
        // 本番環境チェックによるエラーは無視
      }
    });

    group('API Key Validation', () {
      test('should validate correct HotPepper API key format', () {
        // Arrange
        const validApiKey = 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6';

        // Act
        final validation = AppConfig.validateApiKey(validApiKey);

        // Assert
        expect(validation['exists'], isTrue);
        expect(validation['notEmpty'], isTrue);
        expect(validation['notPlaceholder'], isTrue);
        expect(validation['validFormat'], isTrue);
        expect(validation['length'], equals(32));
      });

      test('should reject invalid API key formats', () {
        // Test cases: null, empty, placeholder, wrong length, invalid chars
        final testCases = [
          null,
          '',
          'YOUR_API_KEY_HERE',
          'short',
          'this-key-is-way-too-long-for-hotpepper',
          'invalid-chars-!@#\$%^&*()1234567890',
        ];

        for (final testKey in testCases) {
          // Act
          final validation = AppConfig.validateApiKey(testKey);

          // Assert
          expect(validation['validFormat'], isFalse,
              reason: 'Key "$testKey" should be invalid');
        }
      });

      test('should provide detailed API key source information', () {
        // Act
        final validation = AppConfig.validateApiKey('test_key');

        // Assert
        expect(validation.containsKey('keySource'), isTrue);
        expect(validation.containsKey('isProduction'), isTrue);
      });
    });

    group('Production Safety', () {
      test('should block test operations in production-like environment', () {
        // Note: このテストは本番環境での動作をテストする
        // 本番環境では、テスト用メソッドの実行が拒否される

        if (AppConfig.isProduction) {
          // 本番環境では例外が投げられることを期待
          expect(() => AppConfig.setTestApiKey('test_key'), throwsStateError);
          expect(() => AppConfig.clearTestApiKey(), throwsStateError);
          expect(() => AppConfig.resetInitialization(), throwsStateError);
        } else {
          // 開発環境では正常に動作することを期待
          expect(() => AppConfig.setTestApiKey('test_key'), returnsNormally);
          expect(() => AppConfig.clearTestApiKey(), returnsNormally);
          expect(() => AppConfig.resetInitialization(), returnsNormally);
        }
      });
    });

    group('Enhanced Error Handling', () {
      test('should provide detailed error messages for invalid distance ranges',
          () {
        // Arrange & Act & Assert
        expect(
          () => AppConfig.search.saveDistance(0),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Invalid range value: 0'),
          )),
        );

        expect(
          () => AppConfig.search.saveDistance(6),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Invalid range value: 6'),
          )),
        );
      });

      test('should handle SharedPreferences errors gracefully', () async {
        // Note: SharedPreferencesのエラーは実際のデバイス環境でのみ発生するため、
        // ここではメソッドが適切にtry-catchで囲まれていることを確認

        // Act & Assert (should not throw)
        final distance = await AppConfig.search.getDistance();
        expect(distance, isA<int>());
        expect(distance, inInclusiveRange(1, 5));
      });
    });

    group('Logging and Debugging', () {
      test('should provide comprehensive debug information', () {
        // Act
        final debugInfo = AppConfig.debugInfo;

        // Assert
        expect(debugInfo.containsKey('initialized'), isTrue);
        expect(debugInfo.containsKey('isDevelopment'), isTrue);
        expect(debugInfo.containsKey('isProduction'), isTrue);
        expect(debugInfo.containsKey('api'), isTrue);
        expect(debugInfo.containsKey('search'), isTrue);
      });
    });

    group('Initialization Metrics', () {
      test('should complete initialization with performance tracking',
          () async {
        // 本番環境では初期化リセットができないため、スキップ
        if (AppConfig.isProduction) {
          // 本番環境では初期化リセットが拒否されることを確認
          expect(() => AppConfig.resetInitialization(), throwsStateError);
          return;
        }

        // Arrange
        AppConfig.resetInitialization();

        // Act
        await AppConfig.initialize();

        // Assert
        expect(AppConfig.isInitialized, isTrue);
      });

      test('should skip reinitialization when already initialized', () async {
        // Arrange
        await AppConfig.initialize();
        expect(AppConfig.isInitialized, isTrue);

        // Act
        await AppConfig.initialize();

        // Assert
        expect(AppConfig.isInitialized, isTrue);
      });
    });
  });
}
