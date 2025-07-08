import 'environment_config.dart';

/// 設定検証クラス
class ConfigValidator {
  /// 設定全体の検証を実行し、エラーリストを返す
  static List<String> validateConfiguration() {
    final errors = <String>[];

    // APIキーの存在確認
    _validateApiKeys(errors);

    // APIキーの形式検証
    _validateApiKeyFormats(errors);

    // 環境固有の検証
    _validateEnvironmentSpecificConfig(errors);

    return errors;
  }

  /// APIキーの存在を検証
  static void _validateApiKeys(List<String> errors) {
    final hotpepperKey = EnvironmentConfig.effectiveHotpepperApiKey;
    final googleMapsKey = EnvironmentConfig.effectiveGoogleMapsApiKey;

    if (hotpepperKey.isEmpty) {
      errors.add(
        'HotPepper API キーが設定されていません (環境: ${EnvironmentConfig.current.name})',
      );
    }

    if (googleMapsKey.isEmpty) {
      errors.add(
        'Google Maps API キーが設定されていません (環境: ${EnvironmentConfig.current.name})',
      );
    }
  }

  /// APIキーの形式を検証
  static void _validateApiKeyFormats(List<String> errors) {
    final hotpepperKey = EnvironmentConfig.effectiveHotpepperApiKey;
    final googleMapsKey = EnvironmentConfig.effectiveGoogleMapsApiKey;

    if (hotpepperKey.isNotEmpty && !_isValidHotpepperApiKey(hotpepperKey)) {
      errors.add(
        'HotPepper API キーの形式が無効です (最低16文字の英数字が必要)',
      );
    }

    if (googleMapsKey.isNotEmpty && !_isValidGoogleMapsApiKey(googleMapsKey)) {
      errors.add(
        'Google Maps API キーの形式が無効です (AIza で始まる39文字のキーが必要)',
      );
    }
  }

  /// 環境固有の設定を検証
  static void _validateEnvironmentSpecificConfig(List<String> errors) {
    final currentEnv = EnvironmentConfig.current;

    switch (currentEnv) {
      case Environment.production:
        _validateProductionConfig(errors);
        break;
      case Environment.staging:
        _validateStagingConfig(errors);
        break;
      case Environment.development:
        _validateDevelopmentConfig(errors);
        break;
    }
  }

  /// 本番環境の設定を検証
  static void _validateProductionConfig(List<String> errors) {
    // 本番環境では厳密な検証を実施
    final hotpepperKey = EnvironmentConfig.hotpepperApiKey;
    final googleMapsKey = EnvironmentConfig.googleMapsApiKey;

    if (hotpepperKey.isEmpty) {
      errors.add('本番環境: PROD_HOTPEPPER_API_KEY が設定されていません');
    }

    if (googleMapsKey.isEmpty) {
      errors.add('本番環境: PROD_GOOGLE_MAPS_API_KEY が設定されていません');
    }

    // 本番環境ではフォールバック使用を警告
    if (hotpepperKey.isEmpty &&
        EnvironmentConfig.fallbackHotpepperApiKey.isNotEmpty) {
      errors.add('警告: 本番環境でフォールバック HotPepper API キーを使用中');
    }

    if (googleMapsKey.isEmpty &&
        EnvironmentConfig.fallbackGoogleMapsApiKey.isNotEmpty) {
      errors.add('警告: 本番環境でフォールバック Google Maps API キーを使用中');
    }
  }

  /// ステージング環境の設定を検証
  static void _validateStagingConfig(List<String> errors) {
    final hotpepperKey = EnvironmentConfig.hotpepperApiKey;
    final googleMapsKey = EnvironmentConfig.googleMapsApiKey;

    if (hotpepperKey.isEmpty) {
      errors.add('ステージング環境: STAGING_HOTPEPPER_API_KEY が設定されていません');
    }

    if (googleMapsKey.isEmpty) {
      errors.add('ステージング環境: STAGING_GOOGLE_MAPS_API_KEY が設定されていません');
    }
  }

  /// 開発環境の設定を検証
  static void _validateDevelopmentConfig(List<String> errors) {
    // 開発環境では警告レベルの検証
    final hotpepperKey = EnvironmentConfig.effectiveHotpepperApiKey;
    final googleMapsKey = EnvironmentConfig.effectiveGoogleMapsApiKey;

    if (hotpepperKey.isEmpty) {
      errors.add('開発環境: HotPepper API キーが設定されていません（機能制限あり）');
    }

    if (googleMapsKey.isEmpty) {
      errors.add('開発環境: Google Maps API キーが設定されていません（地図機能無効）');
    }
  }

  /// HotPepper API キーの形式を検証
  static bool _isValidHotpepperApiKey(String apiKey) {
    // HotPepper API キーの基本的な形式チェック
    // - 最低16文字
    // - 英数字のみ
    if (apiKey.length < 16) return false;
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(apiKey)) return false;

    return true;
  }

  /// Google Maps API キーの形式を検証
  static bool _isValidGoogleMapsApiKey(String apiKey) {
    // Google Maps API キーの基本的な形式チェック
    // - AIza で始まる
    // - 39文字
    if (apiKey.length != 39) return false;
    if (!apiKey.startsWith('AIza')) return false;
    if (!RegExp(r'^AIza[a-zA-Z0-9_-]+$').hasMatch(apiKey)) return false;

    return true;
  }

  /// 設定が有効かどうかを判定
  static bool get isConfigurationValid {
    return validateConfiguration().isEmpty;
  }

  /// 重要なエラー（本番環境やセキュリティ関連）があるかを判定
  static bool get hasCriticalErrors {
    final errors = validateConfiguration();
    return errors.any((error) =>
        error.contains('本番環境') ||
        error.contains('形式が無効') ||
        error.contains('警告: 本番環境'));
  }

  /// 設定の詳細情報を取得（デバッグ用）
  static Map<String, dynamic> get configurationDetails {
    return {
      'environment': EnvironmentConfig.current.name,
      'validationErrors': validateConfiguration(),
      'isValid': isConfigurationValid,
      'hasCriticalErrors': hasCriticalErrors,
      'debugInfo': EnvironmentConfig.debugInfo,
    };
  }
}
