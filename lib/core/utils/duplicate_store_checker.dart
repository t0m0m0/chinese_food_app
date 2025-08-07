import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/core/constants/api_constants.dart';

/// 店舗重複チェック処理の統一化クラス
///
/// 重複判定閾値や距離計算ロジックを一元化し、
/// 複数箇所に散在していた重複チェック処理を統一管理する。
class DuplicateStoreChecker {
  DuplicateStoreChecker._(); // プライベートコンストラクタでインスタンス化を防ぐ

  /// 2つの座標点間の距離を計算（メートル単位）
  ///
  /// Haversine公式を使用して、緯度経度から実際の距離を算出
  static double calculateDistance(gmaps.LatLng point1, gmaps.LatLng point2) {
    const double earthRadius = 6371000; // 地球の半径（メートル）

    final double lat1Rad = point1.latitude * pi / 180;
    final double lat2Rad = point2.latitude * pi / 180;
    final double deltaLatRad = (point2.latitude - point1.latitude) * pi / 180;
    final double deltaLngRad = (point2.longitude - point1.longitude) * pi / 180;

    final double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) *
            cos(lat2Rad) *
            sin(deltaLngRad / 2) *
            sin(deltaLngRad / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// 2つの店舗が重複しているかを判定
  ///
  /// [store1] 比較対象店舗1
  /// [store2] 比較対象店舗2
  /// [threshold] 重複判定距離閾値（メートル）。未指定時はデフォルト値使用
  ///
  /// 返り値: 重複している場合true、そうでなければfalse
  static bool isDuplicate(Store store1, Store store2, {double? threshold}) {
    final double effectiveThreshold =
        threshold ?? _getDefaultThresholdInMeters();

    // 段階的フィルタリング: 高速な粗いチェック → 精密な距離計算
    if (!_isWithinRoughDistance(store1, store2, effectiveThreshold * 1.5)) {
      return false; // 明らかに遠い場合は距離計算をスキップ
    }

    // 粗いチェックをパスした場合のみ精密な距離計算を実行
    final double distance = calculateDistance(
      gmaps.LatLng(store1.lat, store1.lng),
      gmaps.LatLng(store2.lat, store2.lng),
    );

    return distance <= effectiveThreshold;
  }

  /// 店舗リストから重複を除去して返す
  ///
  /// [stores] 重複を除去する店舗リスト
  /// [threshold] 重複判定距離閾値（メートル）。未指定時はデフォルト値使用
  ///
  /// 返り値: 重複を除去した店舗リスト（最初に出現した店舗を保持）
  static List<Store> removeDuplicates(List<Store> stores, {double? threshold}) {
    if (stores.isEmpty) return [];

    final List<Store> uniqueStores = [];

    for (final store in stores) {
      final bool isDuplicateFound = uniqueStores.any(
        (existingStore) =>
            isDuplicate(existingStore, store, threshold: threshold),
      );

      if (!isDuplicateFound) {
        uniqueStores.add(store);
      }
    }

    return uniqueStores;
  }

  /// デフォルトの閾値をメートル単位で取得
  ///
  /// ApiConstants.duplicateThresholdは緯度経度の差分値（0.001）を
  /// 実際の距離（メートル）に変換する
  static double _getDefaultThresholdInMeters() {
    // 緯度1度 ≈ 111,320m（地球の円周/360度）
    // 0.001度 ≈ 111.32m（赤道付近）
    // 日本付近（北緯35度）では経度が若干短くなるが、
    // 安全マージンを考慮して111mを使用
    return ApiConstants.duplicateThreshold * 111320;
  }

  /// 高速な事前フィルタリング用の粗い距離チェック
  ///
  /// Haversine計算前に明らかに遠い店舗を除外してパフォーマンス向上
  /// [store1] 比較対象店舗1
  /// [store2] 比較対象店舗2
  /// [threshold] 閾値（メートル）
  /// 返り値: 粗いチェックで重複可能性がある場合true
  static bool _isWithinRoughDistance(
      Store store1, Store store2, double threshold) {
    // 緯度経度差分から概算距離をチェック（高速）
    final double latDiff = (store1.lat - store2.lat).abs();
    final double lngDiff = (store1.lng - store2.lng).abs();

    // 閾値を緯度経度差分に変換（概算）
    final double thresholdDegrees = threshold / 111320; // 1度≈111.32km

    // 矩形範囲での粗いチェック（距離計算より高速）
    return latDiff <= thresholdDegrees && lngDiff <= thresholdDegrees;
  }
}
