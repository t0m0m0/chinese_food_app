import '../ui_config.dart';

/// UI設定管理を担当するManager
class UiConfigManager {
  UiConfigManager._(); // private constructor

  /// UI設定の検証を実行
  static List<String> validate() {
    final errors = <String>[];

    if (!UiConfig.isValidPadding(UiConfig.defaultPadding)) {
      errors.add('UIパディング値が無効です: ${UiConfig.defaultPadding}');
    }

    if (!UiConfig.isValidBorderRadius(UiConfig.cardBorderRadius)) {
      errors.add('カード角丸値が無効です: ${UiConfig.cardBorderRadius}');
    }

    if (!UiConfig.isValidMapZoom(UiConfig.defaultMapZoom)) {
      errors.add('マップズーム値が無効です: ${UiConfig.defaultMapZoom}');
    }

    return errors;
  }

  /// UI設定情報を取得
  static Map<String, dynamic> getConfig() {
    return {
      'type': 'ui',
      'padding': UiConfig.defaultPadding,
      'borderRadius': UiConfig.cardBorderRadius,
      'mapZoom': UiConfig.defaultMapZoom,
      'appName': UiConfig.appName,
      'animationDuration': UiConfig.defaultAnimationDuration,
    };
  }

  /// デバッグ情報を取得
  static Map<String, dynamic> get debugInfo {
    return {
      'manager': 'UiConfigManager',
      'config': getConfig(),
      'validationErrors': validate(),
    };
  }
}
