import '../api_config.dart';

/// API設定管理を担当するManager
class ApiConfigManager {
  ApiConfigManager._(); // private constructor

  /// API設定の検証を実行
  static List<String> validate() {
    final errors = <String>[];

    if (!ApiConfig.isValidTimeout(ApiConfig.hotpepperApiTimeout)) {
      errors.add('HotPepper APIタイムアウト値が無効です: ${ApiConfig.hotpepperApiTimeout}');
    }

    if (!ApiConfig.isValidRetryCount(ApiConfig.hotpepperApiRetryCount)) {
      errors
          .add('HotPepper APIリトライ回数が無効です: ${ApiConfig.hotpepperApiRetryCount}');
    }

    if (!ApiConfig.isValidMaxResults(ApiConfig.hotpepperMaxResults)) {
      errors.add('HotPepper API最大結果数が無効です: ${ApiConfig.hotpepperMaxResults}');
    }

    return errors;
  }

  /// API設定情報を取得
  static Map<String, dynamic> getConfig() {
    return {
      'type': 'api',
      'timeout': ApiConfig.hotpepperApiTimeout,
      'retryCount': ApiConfig.hotpepperApiRetryCount,
      'maxResults': ApiConfig.hotpepperMaxResults,
      'baseUrl': ApiConfig.hotpepperApiUrl,
    };
  }

  /// デバッグ情報を取得
  static Map<String, dynamic> get debugInfo {
    return {
      'manager': 'ApiConfigManager',
      'config': getConfig(),
      'validationErrors': validate(),
    };
  }
}
