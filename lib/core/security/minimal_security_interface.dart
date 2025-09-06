import 'dart:developer' as developer;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// MVP用の最小限セキュリティインターフェース
///
/// 将来的な拡張を考慮した設計で、現在は最低限の機能のみ提供
abstract class SecurityManager {
  /// APIキーの安全な取得
  Future<String?> getApiKey(String keyName);

  /// APIキーの安全な保存
  Future<void> setApiKey(String keyName, String value);

  /// セキュリティ設定の検証
  bool validateSecurityConfiguration();
}

/// MVP用の基本セキュリティ実装
class BasicSecurityManager implements SecurityManager {
  static BasicSecurityManager? _instance;
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  factory BasicSecurityManager() {
    return _instance ??= BasicSecurityManager._internal();
  }

  BasicSecurityManager._internal();

  @override
  Future<String?> getApiKey(String keyName) async {
    try {
      return await _storage.read(key: keyName);
    } catch (e) {
      // 基本的なログ出力のみ（開発時のみ）
      developer.log('Error reading API key $keyName: $e', name: 'Security');
      return null;
    }
  }

  @override
  Future<void> setApiKey(String keyName, String value) async {
    try {
      await _storage.write(key: keyName, value: value);
    } catch (e) {
      developer.log('Error storing API key $keyName: $e', name: 'Security');
      rethrow;
    }
  }

  @override
  bool validateSecurityConfiguration() {
    // MVP段階では基本的な検証のみ
    return true;
  }
}
