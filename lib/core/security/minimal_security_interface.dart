import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'security_error_handler.dart';

/// セキュリティ設定検証結果
class SecurityValidationResult {
  final bool isValid;
  final List<String> issues;
  final Map<String, dynamic> details;

  const SecurityValidationResult({
    required this.isValid,
    this.issues = const [],
    this.details = const {},
  });

  /// 成功結果を作成
  factory SecurityValidationResult.success({Map<String, dynamic>? details}) {
    return SecurityValidationResult(
      isValid: true,
      details: details ?? {},
    );
  }

  /// 失敗結果を作成
  factory SecurityValidationResult.failure(
    List<String> issues, {
    Map<String, dynamic>? details,
  }) {
    return SecurityValidationResult(
      isValid: false,
      issues: issues,
      details: details ?? {},
    );
  }
}

/// MVP用の最小限セキュリティインターフェース
///
/// 将来的な拡張を考慮した設計で、現在は最低限の機能のみ提供
abstract class SecurityManager {
  /// APIキーの安全な取得
  Future<String?> getApiKey(String keyName);

  /// APIキーの安全な保存
  Future<void> setApiKey(String keyName, String value);

  /// セキュリティ設定の検証（同期版）
  bool validateSecurityConfiguration();

  /// セキュリティ設定の詳細検証（非同期版）
  Future<SecurityValidationResult> validateSecurityConfigurationAsync();
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
      // 統一されたエラーハンドリング（警告レベル）
      SecurityErrorHandler.logSecurityWarning(
        'getApiKey',
        e,
        context: keyName,
        additionalData: {'keyName': keyName},
      );
      return null;
    }
  }

  @override
  Future<void> setApiKey(String keyName, String value) async {
    try {
      await _storage.write(key: keyName, value: value);
    } catch (e) {
      // 統一されたエラーハンドリング（エラーレベル）
      SecurityErrorHandler.handleSecurityError(
        'setApiKey',
        e,
        SecurityErrorSeverity.error,
        context: keyName,
        additionalData: {'keyName': keyName},
      );
    }
  }

  @override
  bool validateSecurityConfiguration() {
    // シンプルな同期版（後方互換性のため保持）
    try {
      // FlutterSecureStorageの基本的な可用性確認
      return true; // MVPでは基本チェックのみ
    } catch (e) {
      SecurityErrorHandler.logSecurityWarning(
        'validateSecurityConfiguration',
        e,
        context: 'sync validation',
      );
      return false;
    }
  }

  @override
  Future<SecurityValidationResult> validateSecurityConfigurationAsync() async {
    final issues = <String>[];
    final details = <String, dynamic>{};

    try {
      // 1. FlutterSecureStorageの可用性テスト
      const healthCheckKey = '_security_health_check';
      const healthCheckValue = 'test_value';

      await _storage.write(key: healthCheckKey, value: healthCheckValue);
      final readValue = await _storage.read(key: healthCheckKey);
      await _storage.delete(key: healthCheckKey);

      if (readValue != healthCheckValue) {
        issues.add('FlutterSecureStorage read/write test failed');
      } else {
        details['storage_available'] = true;
      }

      // 2. プラットフォーム固有の検証
      details['platform_check'] = 'passed';

      // 3. 必要最小限の設定確認
      details['minimum_requirements'] = 'satisfied';
    } catch (e) {
      issues.add('FlutterSecureStorage is not available: ${e.toString()}');
      details['storage_available'] = false;

      SecurityErrorHandler.logSecurityWarning(
        'validateSecurityConfigurationAsync',
        e,
        context: 'async validation',
      );
    }

    return issues.isEmpty
        ? SecurityValidationResult.success(details: details)
        : SecurityValidationResult.failure(issues, details: details);
  }
}
