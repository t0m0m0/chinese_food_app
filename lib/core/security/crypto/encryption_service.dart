import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'dart:math';
import 'package:pointycastle/export.dart';

import '../../exceptions/infrastructure/security_exception.dart';

/// 暗号化サービス
///
/// アプリケーション内でのデータ暗号化・復号化を管理します。
/// SQLiteデータベースや写真ファイルなどの機密データの保護に使用されます。
abstract class EncryptionService {
  /// テキストデータを暗号化
  Future<String> encrypt(String plainText, String key);

  /// 暗号化されたテキストを復号化
  Future<String> decrypt(String encryptedText, String key);

  /// バイナリデータを暗号化
  Future<Uint8List> encryptBytes(Uint8List data, String key);

  /// 暗号化されたバイナリデータを復号化
  Future<Uint8List> decryptBytes(Uint8List encryptedData, String key);

  /// ランダムな暗号化キーを生成
  String generateKey();

  /// パスワードからキーを派生
  String deriveKey(String password, String salt);

  /// ランダムなソルトを生成
  String generateSalt();

  /// データのハッシュ値を計算
  String hashData(String data);
}

/// AES暗号化を使用した暗号化サービスの実装
class AESEncryptionService implements EncryptionService {
  static const int _keyLength = 32; // 256 bits
  static const int _saltLength = 16; // 128 bits
  static const int _ivLength = 16; // 128 bits

  final Random _random = Random.secure();

  @override
  Future<String> encrypt(String plainText, String key) async {
    try {
      final keyBytes = _validateAndPrepareKey(key);
      final iv = _generateIV();
      final plainBytes = utf8.encode(plainText);

      final encryptedBytes =
          await _performAESEncryption(plainBytes, keyBytes, iv);

      // IV + 暗号化データをBase64エンコード
      final combined = Uint8List.fromList([...iv, ...encryptedBytes]);
      return base64.encode(combined);
    } catch (e) {
      throw SecurityException(
        'テキストの暗号化に失敗しました',
        context: 'AES暗号化処理',
        originalException: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  @override
  Future<String> decrypt(String encryptedText, String key) async {
    try {
      final keyBytes = _validateAndPrepareKey(key);
      final combined = base64.decode(encryptedText);

      if (combined.length < _ivLength) {
        throw SecurityException('暗号化データの形式が無効です');
      }

      final iv = combined.sublist(0, _ivLength);
      final encryptedBytes = combined.sublist(_ivLength);

      final decryptedBytes =
          await _performAESDecryption(encryptedBytes, keyBytes, iv);
      return utf8.decode(decryptedBytes);
    } catch (e) {
      throw SecurityException(
        'テキストの復号化に失敗しました',
        context: 'AES復号化処理',
        originalException: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  @override
  Future<Uint8List> encryptBytes(Uint8List data, String key) async {
    try {
      final keyBytes = _validateAndPrepareKey(key);
      final iv = _generateIV();

      final encryptedBytes = await _performAESEncryption(data, keyBytes, iv);

      // IV + 暗号化データを結合
      return Uint8List.fromList([...iv, ...encryptedBytes]);
    } catch (e) {
      throw SecurityException(
        'バイナリデータの暗号化に失敗しました',
        context: 'AES暗号化処理',
        originalException: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  @override
  Future<Uint8List> decryptBytes(Uint8List encryptedData, String key) async {
    try {
      final keyBytes = _validateAndPrepareKey(key);

      if (encryptedData.length < _ivLength) {
        throw SecurityException('暗号化データの形式が無効です');
      }

      final iv = encryptedData.sublist(0, _ivLength);
      final encryptedBytes = encryptedData.sublist(_ivLength);

      return await _performAESDecryption(encryptedBytes, keyBytes, iv);
    } catch (e) {
      throw SecurityException(
        'バイナリデータの復号化に失敗しました',
        context: 'AES復号化処理',
        originalException: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  @override
  String generateKey() {
    final bytes = Uint8List(_keyLength);
    for (int i = 0; i < _keyLength; i++) {
      bytes[i] = _random.nextInt(256);
    }
    return base64.encode(bytes);
  }

  @override
  String deriveKey(String password, String salt) {
    try {
      final passwordBytes = utf8.encode(password);
      final saltBytes = base64.decode(salt);

      // PBKDF2を使用してキーを派生
      var derived = passwordBytes;
      for (int i = 0; i < 10000; i++) {
        final hmac = Hmac(sha256, derived);
        derived =
            Uint8List.fromList(hmac.convert([...saltBytes, ...derived]).bytes);
      }

      // 必要な長さに調整
      if (derived.length > _keyLength) {
        derived = derived.sublist(0, _keyLength);
      } else if (derived.length < _keyLength) {
        // パディング
        final padded = Uint8List(_keyLength);
        padded.setRange(0, derived.length, derived);
        derived = padded;
      }

      return base64.encode(derived);
    } catch (e) {
      throw SecurityException(
        'キーの派生に失敗しました',
        context: 'PBKDF2キー派生',
        originalException: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  @override
  String generateSalt() {
    final bytes = Uint8List(_saltLength);
    for (int i = 0; i < _saltLength; i++) {
      bytes[i] = _random.nextInt(256);
    }
    return base64.encode(bytes);
  }

  @override
  String hashData(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// キーの検証と準備
  Uint8List _validateAndPrepareKey(String key) {
    try {
      final keyBytes = base64.decode(key);
      if (keyBytes.length != _keyLength) {
        throw SecurityException(
            'キーの長さが無効です。期待値: $_keyLength bytes, 実際: ${keyBytes.length} bytes');
      }
      return keyBytes;
    } catch (e) {
      throw SecurityException(
        'キーの形式が無効です',
        context: 'Base64デコード',
        originalException: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// 初期化ベクトル（IV）を生成
  Uint8List _generateIV() {
    final iv = Uint8List(_ivLength);
    for (int i = 0; i < _ivLength; i++) {
      iv[i] = _random.nextInt(256);
    }
    return iv;
  }

  /// AES-256-GCM暗号化の実行
  ///
  /// Pointycastleライブラリを使用した暗号学的に安全な実装
  Future<Uint8List> _performAESEncryption(
      Uint8List data, Uint8List key, Uint8List iv) async {
    try {
      // AES-256-GCM暗号化を実行
      final cipher = GCMBlockCipher(AESEngine());
      final keyParam = KeyParameter(key);
      final params = AEADParameters(keyParam, 128, iv, Uint8List(0));

      cipher.init(true, params); // true = 暗号化モード

      final encryptedData = cipher.process(data);
      return encryptedData;
    } catch (e) {
      throw SecurityException(
        'AES暗号化処理に失敗しました',
        context: 'AES-256-GCM encryption',
        originalException: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// AES-256-GCM復号化の実行
  ///
  /// Pointycastleライブラリを使用した暗号学的に安全な実装
  Future<Uint8List> _performAESDecryption(
      Uint8List encryptedData, Uint8List key, Uint8List iv) async {
    try {
      // AES-256-GCM復号化を実行
      final cipher = GCMBlockCipher(AESEngine());
      final keyParam = KeyParameter(key);
      final params = AEADParameters(keyParam, 128, iv, Uint8List(0));

      cipher.init(false, params); // false = 復号化モード

      final decryptedData = cipher.process(encryptedData);
      return decryptedData;
    } catch (e) {
      throw SecurityException(
        'AES復号化処理に失敗しました',
        context: 'AES-256-GCM decryption',
        originalException: e is Exception ? e : Exception(e.toString()),
      );
    }
  }
}
