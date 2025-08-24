/// リリースビルド設定の基底クラス
abstract class ReleaseBuildConfig {
  const ReleaseBuildConfig();

  /// 設定が有効かどうか
  bool get isValid;

  /// バリデーションエラー
  List<String> get validationErrors;
}

/// Android リリースビルド設定クラス
class AndroidReleaseBuildConfig extends ReleaseBuildConfig {
  const AndroidReleaseBuildConfig({
    required this.applicationId,
    required this.versionName,
    required this.versionCode,
    required this.minSdkVersion,
    required this.targetSdkVersion,
    required this.enableProguard,
    required this.enableShrinkResources,
  });

  final String applicationId;
  final String versionName;
  final int versionCode;
  final int minSdkVersion;
  final int targetSdkVersion;
  final bool enableProguard;
  final bool enableShrinkResources;

  @override
  bool get isValid => validationErrors.isEmpty;

  @override
  List<String> get validationErrors {
    final errors = <String>[];

    // アプリケーションID検証
    if (!_isValidApplicationId(applicationId)) {
      errors.add('アプリケーションIDの形式が無効です');
    }

    // バージョンコード検証
    if (versionCode < 1) {
      errors.add('バージョンコードは1以上である必要があります');
    }

    // バージョン名検証
    if (versionName.isEmpty || !_isValidVersionName(versionName)) {
      errors.add('バージョン名の形式が無効です');
    }

    // SDK バージョン検証
    if (minSdkVersion < 16) {
      errors.add('最小SDKバージョンは16以上である必要があります');
    }

    if (targetSdkVersion < minSdkVersion) {
      errors.add('ターゲットSDKバージョンは最小SDKバージョン以上である必要があります');
    }

    return errors;
  }

  /// アプリケーションIDの形式を検証する
  bool _isValidApplicationId(String applicationId) {
    final applicationIdPattern =
        RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$');
    return applicationIdPattern.hasMatch(applicationId);
  }

  /// バージョン名の形式を検証する
  bool _isValidVersionName(String versionName) {
    final versionPattern = RegExp(r'^\d+\.\d+\.\d+(-[a-zA-Z0-9]+)?$');
    return versionPattern.hasMatch(versionName);
  }
}

/// iOS リリースビルド設定クラス
class IosReleaseBuildConfig extends ReleaseBuildConfig {
  const IosReleaseBuildConfig({
    required this.bundleId,
    required this.version,
    required this.buildNumber,
    required this.deploymentTarget,
    required this.enableBitcode,
    required this.enableSwiftOptimization,
  });

  final String bundleId;
  final String version;
  final String buildNumber;
  final String deploymentTarget;
  final bool enableBitcode;
  final bool enableSwiftOptimization;

  @override
  bool get isValid => validationErrors.isEmpty;

  @override
  List<String> get validationErrors {
    final errors = <String>[];

    // バンドルID検証
    if (!_isValidBundleId(bundleId)) {
      errors.add('バンドルIDの形式が無効です');
    }

    // バージョン検証
    if (version.isEmpty || !_isValidVersion(version)) {
      errors.add('バージョンの形式が無効です');
    }

    // ビルド番号検証
    if (buildNumber.isEmpty) {
      errors.add('ビルド番号が設定されていません');
    }

    // デプロイメントターゲット検証
    if (!_isValidDeploymentTarget(deploymentTarget)) {
      errors.add('デプロイメントターゲットは10.0以上である必要があります');
    }

    return errors;
  }

  /// バンドルIDの形式を検証する
  bool _isValidBundleId(String bundleId) {
    final bundleIdPattern =
        RegExp(r'^[a-zA-Z][a-zA-Z0-9_-]*(\.[a-zA-Z][a-zA-Z0-9_-]*)+$');
    return bundleIdPattern.hasMatch(bundleId);
  }

  /// バージョンの形式を検証する
  bool _isValidVersion(String version) {
    final versionPattern = RegExp(r'^\d+\.\d+\.\d+(-[a-zA-Z0-9]+)?$');
    return versionPattern.hasMatch(version);
  }

  /// デプロイメントターゲットの検証
  bool _isValidDeploymentTarget(String target) {
    try {
      final version = double.parse(target);
      return version >= 10.0;
    } catch (e) {
      return false;
    }
  }
}

/// リリースビルド設定検証結果
class ReleaseBuildValidationResult {
  const ReleaseBuildValidationResult({
    required this.isValid,
    required this.errors,
  });

  final bool isValid;
  final List<String> errors;
}

/// リリースビルド設定例外
class ReleaseBuildConfigurationException implements Exception {
  const ReleaseBuildConfigurationException(this.message);

  final String message;

  @override
  String toString() => 'ReleaseBuildConfigurationException: $message';
}
