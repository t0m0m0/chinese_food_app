import 'package:geolocator/geolocator.dart';

/// 位置情報関連の設定を管理するクラス
class LocationConfig {
  /// 位置情報取得のタイムアウト時間（秒）
  static const int defaultTimeoutSeconds = 10;
  static const int maxTimeoutSeconds = 60;
  static const int minTimeoutSeconds = 1;

  /// 位置情報の精度設定
  static const LocationAccuracy defaultAccuracy = LocationAccuracy.high;
  static const LocationAccuracy fallbackAccuracy = LocationAccuracy.medium;

  /// 位置情報の権限設定
  static const List<LocationPermission> acceptablePermissions = [
    LocationPermission.whileInUse,
    LocationPermission.always,
  ];

  /// 位置情報の距離設定
  static const double defaultLocationRadius = 1000.0; // メートル
  static const double minLocationRadius = 100.0; // メートル
  static const double maxLocationRadius = 10000.0; // メートル

  /// 位置情報の精度設定
  static const double minAcceptableAccuracy = 100.0; // メートル
  static const double maxAcceptableAccuracy = 1000.0; // メートル

  /// 位置情報の再取得間隔（秒）
  static const int locationUpdateInterval = 30;
  static const int minUpdateInterval = 5;
  static const int maxUpdateInterval = 300;

  /// 位置情報の設定値検証
  static bool isValidTimeout(int timeout) {
    return timeout >= minTimeoutSeconds && timeout <= maxTimeoutSeconds;
  }

  /// 位置情報の設定値検証
  static bool isValidRadius(double radius) {
    return radius >= minLocationRadius && radius <= maxLocationRadius;
  }

  /// 位置情報の設定値検証
  static bool isValidAccuracy(double accuracy) {
    return accuracy >= minAcceptableAccuracy &&
        accuracy <= maxAcceptableAccuracy;
  }

  /// 位置情報の設定値検証
  static bool isValidUpdateInterval(int interval) {
    return interval >= minUpdateInterval && interval <= maxUpdateInterval;
  }

  /// 権限が許可されているかどうかを判定
  static bool isPermissionAcceptable(LocationPermission permission) {
    return acceptablePermissions.contains(permission);
  }

  /// 位置情報の精度レベルを取得
  static LocationAccuracy getAccuracyLevel(String accuracyName) {
    switch (accuracyName.toLowerCase()) {
      case 'lowest':
        return LocationAccuracy.lowest;
      case 'low':
        return LocationAccuracy.low;
      case 'medium':
        return LocationAccuracy.medium;
      case 'high':
        return LocationAccuracy.high;
      case 'best':
        return LocationAccuracy.best;
      case 'bestfornavigation':
        return LocationAccuracy.bestForNavigation;
      default:
        return defaultAccuracy;
    }
  }

  /// デバッグ情報を取得
  static Map<String, dynamic> get debugInfo {
    return {
      'defaultTimeoutSeconds': defaultTimeoutSeconds,
      'maxTimeoutSeconds': maxTimeoutSeconds,
      'minTimeoutSeconds': minTimeoutSeconds,
      'defaultAccuracy': defaultAccuracy.name,
      'fallbackAccuracy': fallbackAccuracy.name,
      'acceptablePermissions':
          acceptablePermissions.map((p) => p.name).toList(),
      'defaultLocationRadius': defaultLocationRadius,
      'minLocationRadius': minLocationRadius,
      'maxLocationRadius': maxLocationRadius,
      'minAcceptableAccuracy': minAcceptableAccuracy,
      'maxAcceptableAccuracy': maxAcceptableAccuracy,
      'locationUpdateInterval': locationUpdateInterval,
      'minUpdateInterval': minUpdateInterval,
      'maxUpdateInterval': maxUpdateInterval,
    };
  }
}
