import 'dart:convert';

/// 設定値の暗号化ヘルパークラス
///
/// 本番環境での設定値の暗号化をサポートします。
/// 注意: これは基本的な暗号化実装です。本番環境では
/// より高度な暗号化ライブラリの使用を検討してください。
class ConfigEncryption {
  /// 暗号化キー（本番環境では環境変数から取得）
  static String get _encryptionKey =>
      const String.fromEnvironment('CONFIG_ENCRYPTION_KEY',
          defaultValue: 'default_key_change_in_production');

  /// 文字列を暗号化
  static String encrypt(String plaintext) {
    if (plaintext.isEmpty) return plaintext;

    try {
      final keyBytes = utf8.encode(_encryptionKey);
      final plaintextBytes = utf8.encode(plaintext);
      final encrypted = <int>[];

      for (int i = 0; i < plaintextBytes.length; i++) {
        encrypted.add(plaintextBytes[i] ^ keyBytes[i % keyBytes.length]);
      }

      return base64Encode(encrypted);
    } catch (e) {
      // 暗号化に失敗した場合は元の値を返す（フォールバック）
      return plaintext;
    }
  }

  /// 文字列を復号化
  static String decrypt(String encryptedText) {
    if (encryptedText.isEmpty) return encryptedText;

    try {
      final keyBytes = utf8.encode(_encryptionKey);
      final encryptedBytes = base64Decode(encryptedText);
      final decrypted = <int>[];

      for (int i = 0; i < encryptedBytes.length; i++) {
        decrypted.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
      }

      return utf8.decode(decrypted);
    } catch (e) {
      // 復号化に失敗した場合は元の値を返す（フォールバック）
      return encryptedText;
    }
  }

  /// 暗号化が有効かどうかを判定
  static bool get isEncryptionEnabled =>
      const bool.fromEnvironment('ENABLE_CONFIG_ENCRYPTION',
          defaultValue: false);

  /// APIキーを安全に暗号化（本番環境でのみ有効）
  static String encryptApiKey(String apiKey) {
    if (!isEncryptionEnabled || apiKey.isEmpty) {
      return apiKey;
    }

    return encrypt(apiKey);
  }

  /// 暗号化されたAPIキーを復号化
  static String decryptApiKey(String encryptedApiKey) {
    if (!isEncryptionEnabled || encryptedApiKey.isEmpty) {
      return encryptedApiKey;
    }

    return decrypt(encryptedApiKey);
  }

  /// 暗号化キーの強度を検証
  static bool validateEncryptionKey() {
    final key = _encryptionKey;

    // 最低要件: 16文字以上、英数字記号混在
    if (key.length < 16) return false;
    if (key == 'default_key_change_in_production') return false;

    bool hasLower = false,
        hasUpper = false,
        hasDigit = false,
        hasSymbol = false;

    for (final char in key.runes) {
      if (char >= 97 && char <= 122) {
        hasLower = true;
      } else if (char >= 65 && char <= 90) {
        hasUpper = true;
      } else if (char >= 48 && char <= 57) {
        hasDigit = true;
      } else {
        hasSymbol = true;
      }
    }

    return hasLower && hasUpper && hasDigit && hasSymbol;
  }

  /// 暗号化のデバッグ情報を取得
  static Map<String, dynamic> get debugInfo => {
        'encryptionEnabled': isEncryptionEnabled,
        'keyLength': _encryptionKey.length,
        'keyIsDefault': _encryptionKey == 'default_key_change_in_production',
        'keyStrength': validateEncryptionKey() ? 'strong' : 'weak',
      };
}
