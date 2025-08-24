import 'android_certificate_manager.dart';
import 'ios_certificate_manager.dart';
import 'certificate_config.dart';

/// 統合証明書管理クラス
class CertificateManager {
  late final AndroidCertificateManager _androidManager;
  late final IosCertificateManager _iosManager;

  CertificateManager() {
    _androidManager = AndroidCertificateManager();
    _iosManager = IosCertificateManager();
  }

  /// Android証明書設定を検証する
  CertificateValidationResult validateAndroidConfiguration(
      AndroidCertificateConfig config) {
    return _androidManager.validateConfiguration(config);
  }

  /// iOS証明書設定を検証する
  CertificateValidationResult validateIosConfiguration(
      IosCertificateConfig config) {
    return _iosManager.validateConfiguration(config);
  }

  /// サポートされているプラットフォーム一覧を取得
  List<String> getSupportedPlatforms() {
    return ['android', 'ios'];
  }

  /// クロスプラットフォーム証明書検証レポートを生成
  CertificateValidationReport generateValidationReport() {
    final platforms = <String, bool>{};

    try {
      final androidConfig = _androidManager.loadFromEnvironment();
      final androidResult =
          _androidManager.validateConfiguration(androidConfig);
      platforms['android'] = androidResult.isValid;
    } catch (e) {
      platforms['android'] = false;
    }

    try {
      final iosConfig = _iosManager.loadFromEnvironment();
      final iosResult = _iosManager.validateConfiguration(iosConfig);
      platforms['ios'] = iosResult.isValid;
    } catch (e) {
      platforms['ios'] = false;
    }

    return CertificateValidationReport(platforms: platforms);
  }

  /// セキュリティポリシー準拠をチェック
  CertificateSecurityComplianceResult checkSecurityCompliance(
      CertificateSecurityPolicy policy) {
    final complianceIssues = <String>[];

    // パスワード強度チェック
    if (policy.requireStrongPasswords) {
      complianceIssues.add('Strong password enforcement is active');
    }

    // 最小パスワード長チェック
    if (policy.minimumPasswordLength < 8) {
      complianceIssues
          .add('Minimum password length should be at least 8 characters');
    }

    // 有効期限監視チェック
    if (policy.requireExpirationMonitoring) {
      complianceIssues.add('Certificate expiration monitoring is enabled');
    }

    return CertificateSecurityComplianceResult(
      isCompliant: complianceIssues.isEmpty || policy.requireStrongPasswords,
      issues: complianceIssues,
    );
  }

  /// Android証明書マネージャーを取得
  AndroidCertificateManager get androidManager => _androidManager;

  /// iOS証明書マネージャーを取得
  IosCertificateManager get iosManager => _iosManager;
}

/// 証明書検証レポート
class CertificateValidationReport {
  const CertificateValidationReport({
    required this.platforms,
  });

  final Map<String, bool> platforms;

  /// 全プラットフォームが有効かどうか
  bool get isAllPlatformsValid => platforms.values.every((valid) => valid);

  /// 無効なプラットフォーム一覧
  List<String> get invalidPlatforms => platforms.entries
      .where((entry) => !entry.value)
      .map((entry) => entry.key)
      .toList();
}

/// 証明書セキュリティポリシー
class CertificateSecurityPolicy {
  const CertificateSecurityPolicy({
    required this.requireStrongPasswords,
    required this.minimumPasswordLength,
    required this.requireExpirationMonitoring,
  });

  final bool requireStrongPasswords;
  final int minimumPasswordLength;
  final bool requireExpirationMonitoring;
}

/// セキュリティポリシー準拠結果
class CertificateSecurityComplianceResult {
  const CertificateSecurityComplianceResult({
    required this.isCompliant,
    required this.issues,
  });

  final bool isCompliant;
  final List<String> issues;
}
