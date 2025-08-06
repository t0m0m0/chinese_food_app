import '../location_config.dart';

/// 位置情報設定管理を担当するManager
class LocationConfigManager {
  LocationConfigManager._(); // private constructor

  /// 位置情報設定の検証を実行
  static List<String> validate() {
    final errors = <String>[];

    if (!LocationConfig.isValidTimeout(LocationConfig.defaultTimeoutSeconds)) {
      errors.add('位置情報タイムアウト値が無効です: ${LocationConfig.defaultTimeoutSeconds}');
    }

    if (!LocationConfig.isValidRadius(LocationConfig.defaultLocationRadius)) {
      errors.add('位置情報検索半径が無効です: ${LocationConfig.defaultLocationRadius}');
    }

    if (!LocationConfig.isValidUpdateInterval(
        LocationConfig.locationUpdateInterval)) {
      errors.add('位置情報更新間隔が無効です: ${LocationConfig.locationUpdateInterval}');
    }

    return errors;
  }

  /// 位置情報設定情報を取得
  static Map<String, dynamic> getConfig() {
    return {
      'type': 'location',
      'timeout': LocationConfig.defaultTimeoutSeconds,
      'radius': LocationConfig.defaultLocationRadius,
      'updateInterval': LocationConfig.locationUpdateInterval,
      'accuracy': LocationConfig.defaultAccuracy.name,
      'fallbackAccuracy': LocationConfig.fallbackAccuracy.name,
    };
  }

  /// デバッグ情報を取得
  static Map<String, dynamic> get debugInfo {
    return {
      'manager': 'LocationConfigManager',
      'config': getConfig(),
      'validationErrors': validate(),
    };
  }
}
