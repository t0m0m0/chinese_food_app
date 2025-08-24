/// 証明書設定の基底クラス
abstract class CertificateConfig {
  const CertificateConfig();

  /// 設定が有効かどうか
  bool get isValid;

  /// バリデーションエラー
  List<String> get validationErrors;
}

/// Android証明書設定クラス
class AndroidCertificateConfig extends CertificateConfig {
  const AndroidCertificateConfig({
    required this.keystorePath,
    required this.keyAlias,
    required this.keystorePassword,
    required this.keyPassword,
  });

  final String keystorePath;
  final String keyAlias;
  final String keystorePassword;
  final String keyPassword;

  @override
  bool get isValid => validationErrors.isEmpty;

  @override
  List<String> get validationErrors {
    final errors = <String>[];

    if (keystorePath.isEmpty) {
      errors.add('キーストアパスが設定されていません');
    }

    if (keyAlias.isEmpty) {
      errors.add('キーエイリアスが設定されていません');
    }

    if (keystorePassword.length < 8) {
      errors.add('パスワードが安全ではありません');
    }

    if (keyPassword.length < 8) {
      errors.add('パスワードが安全ではありません');
    }

    return errors;
  }
}

/// iOS証明書設定クラス
class IosCertificateConfig extends CertificateConfig {
  const IosCertificateConfig({
    required this.teamId,
    required this.bundleId,
    required this.certificateName,
    required this.provisioningProfileName,
  });

  final String teamId;
  final String bundleId;
  final String certificateName;
  final String provisioningProfileName;

  @override
  bool get isValid => validationErrors.isEmpty;

  @override
  List<String> get validationErrors {
    final errors = <String>[];

    if (teamId.isEmpty) {
      errors.add('チームIDが設定されていません');
    }

    if (bundleId.isEmpty) {
      errors.add('バンドルIDが設定されていません');
    } else if (!_isValidBundleId(bundleId)) {
      errors.add('バンドルIDの形式が無効です');
    }

    if (certificateName.isEmpty) {
      errors.add('証明書名が設定されていません');
    }

    if (provisioningProfileName.isEmpty) {
      errors.add('プロビジョニングプロファイル名が設定されていません');
    }

    return errors;
  }

  /// バンドルIDの形式を検証する
  bool _isValidBundleId(String bundleId) {
    final bundleIdPattern =
        RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$');
    return bundleIdPattern.hasMatch(bundleId);
  }
}

/// 証明書設定検証結果
class CertificateValidationResult {
  const CertificateValidationResult({
    required this.isValid,
    required this.errors,
  });

  final bool isValid;
  final List<String> errors;
}

/// 証明書ステータス情報
class CertificateStatus {
  const CertificateStatus({
    required this.isExpired,
    required this.expirationDate,
    this.daysUntilExpiration,
  });

  final bool isExpired;
  final DateTime expirationDate;
  final int? daysUntilExpiration;
}

/// 証明書設定例外
class CertificateConfigurationException implements Exception {
  const CertificateConfigurationException(this.message);

  final String message;

  @override
  String toString() => 'CertificateConfigurationException: $message';
}
