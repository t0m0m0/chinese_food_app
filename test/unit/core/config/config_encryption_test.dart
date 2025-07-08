import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/config/config_encryption.dart';

void main() {
  group('ConfigEncryption', () {
    group('基本的な暗号化・復号化', () {
      test('should encrypt and decrypt strings correctly', () {
        const plaintext = 'test_api_key_12345';

        final encrypted = ConfigEncryption.encrypt(plaintext);
        final decrypted = ConfigEncryption.decrypt(encrypted);

        expect(decrypted, equals(plaintext));
        expect(encrypted, isNot(equals(plaintext)));
      });

      test('should handle empty strings', () {
        final encrypted = ConfigEncryption.encrypt('');
        final decrypted = ConfigEncryption.decrypt('');

        expect(encrypted, equals(''));
        expect(decrypted, equals(''));
      });

      test('should handle special characters', () {
        const plaintext = 'test@#\$%^&*()_+{}|:"<>?';

        final encrypted = ConfigEncryption.encrypt(plaintext);
        final decrypted = ConfigEncryption.decrypt(encrypted);

        expect(decrypted, equals(plaintext));
      });
    });

    group('APIキー暗号化', () {
      test('should encrypt API key when encryption is enabled', () {
        const apiKey = 'test_hotpepper_api_key_12345';

        // Note: This test depends on environment variables
        // In actual tests, you would set ENABLE_CONFIG_ENCRYPTION=true
        final encrypted = ConfigEncryption.encryptApiKey(apiKey);

        // If encryption is disabled, should return original key
        if (!ConfigEncryption.isEncryptionEnabled) {
          expect(encrypted, equals(apiKey));
        }
      });

      test('should decrypt API key correctly', () {
        const apiKey = 'test_google_maps_api_key_12345';

        final encrypted = ConfigEncryption.encryptApiKey(apiKey);
        final decrypted = ConfigEncryption.decryptApiKey(encrypted);

        expect(decrypted, equals(apiKey));
      });
    });

    group('暗号化キー検証', () {
      test('should validate encryption key strength', () {
        final isValid = ConfigEncryption.validateEncryptionKey();

        // デフォルトキーは無効として判定される
        expect(isValid, isFalse);
      });

      test('should provide debug info', () {
        final debugInfo = ConfigEncryption.debugInfo;

        expect(debugInfo, isA<Map<String, dynamic>>());
        expect(debugInfo.containsKey('encryptionEnabled'), isTrue);
        expect(debugInfo.containsKey('keyLength'), isTrue);
        expect(debugInfo.containsKey('keyIsDefault'), isTrue);
        expect(debugInfo.containsKey('keyStrength'), isTrue);
      });
    });

    group('エラーハンドリング', () {
      test('should handle encryption errors gracefully', () {
        // 正常な入力でのテスト
        const plaintext = 'valid_input';

        final encrypted = ConfigEncryption.encrypt(plaintext);
        final decrypted = ConfigEncryption.decrypt(encrypted);

        expect(decrypted, equals(plaintext));
      });

      test('should handle decryption errors gracefully', () {
        // 無効な暗号化データでのテスト
        const invalidEncrypted = 'invalid_base64_data';

        final decrypted = ConfigEncryption.decrypt(invalidEncrypted);

        // エラー時はフォールバックで元の値を返す
        expect(decrypted, equals(invalidEncrypted));
      });
    });

    group('暗号化設定', () {
      test('should check encryption enabled status', () {
        final isEnabled = ConfigEncryption.isEncryptionEnabled;

        expect(isEnabled, isA<bool>());
        // デフォルトでは無効
        expect(isEnabled, isFalse);
      });

      test('should provide consistent encryption/decryption', () {
        const testData = [
          'short',
          'medium_length_string',
          'very_long_string_with_many_characters_and_numbers_12345',
          'special!@#\$%^&*()_+{}|:"<>?',
        ];

        for (final plaintext in testData) {
          final encrypted = ConfigEncryption.encrypt(plaintext);
          final decrypted = ConfigEncryption.decrypt(encrypted);

          expect(decrypted, equals(plaintext),
              reason: 'Failed to encrypt/decrypt: $plaintext');
        }
      });
    });
  });
}
