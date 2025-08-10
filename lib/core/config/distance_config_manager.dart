import 'package:shared_preferences/shared_preferences.dart';
import 'search_config.dart';

/// 距離設定管理サービス
///
/// Issue #117: スワイプ画面に距離設定UI追加機能
/// 距離設定の永続化と取得機能を提供する
class DistanceConfigManager {
  static const String _key = 'search_distance_range';

  /// 距離設定を保存
  ///
  /// [range] HotPepper API準拠の距離範囲（1=300m, 2=500m, 3=1000m, 4=2000m, 5=3000m）
  static Future<void> saveDistance(int range) async {
    if (!SearchConfig.isValidRange(range)) {
      throw ArgumentError('Invalid range value: $range');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, range);
  }

  /// 距離設定を取得（デフォルトは1000m）
  ///
  /// 戻り値: HotPepper API準拠の距離範囲（1-5）
  static Future<int> getDistance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key) ?? SearchConfig.defaultRange;
  }

  /// 距離設定をメートル単位で取得
  ///
  /// 戻り値: 距離（メートル）
  static Future<int> getDistanceInMeters() async {
    final range = await getDistance();
    return SearchConfig.rangeToMeter(range) ?? 1000;
  }

  /// 距離設定をクリア
  static Future<void> clearDistance() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
