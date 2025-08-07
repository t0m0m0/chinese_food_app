import 'dart:math';
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
  static double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // 地球の半径（メートル）

    final double lat1Rad = point1.lat * pi / 180;
    final double lat2Rad = point2.lat * pi / 180;
    final double deltaLatRad = (point2.lat - point1.lat) * pi / 180;
    final double deltaLngRad = (point2.lng - point1.lng) * pi / 180;

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

    final double distance = calculateDistance(
      LatLng(store1.lat, store1.lng),
      LatLng(store2.lat, store2.lng),
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
  /// ApiConstants.duplicateThresholdは緯度経度の差分値（0.001≈110m）なので、
  /// 実際の距離（メートル）に変換する
  static double _getDefaultThresholdInMeters() {
    // 0.001緯度 ≈ 111km * 0.001 = 111m
    // より精密な計算のため、110mを標準値として使用
    return ApiConstants.duplicateThreshold * 111000;
  }
}

/// シンプルな緯度経度座標クラス
class LatLng {
  final double lat;
  final double lng;

  const LatLng(this.lat, this.lng);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LatLng && lat == other.lat && lng == other.lng;

  @override
  int get hashCode => lat.hashCode ^ lng.hashCode;

  @override
  String toString() => 'LatLng($lat, $lng)';
}
