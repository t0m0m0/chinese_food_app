import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// 広域検索のためのグリッドポイント生成クラス
///
/// HotPepper APIのrange制限（最大3km）を超える検索範囲に対応するため、
/// 複数の検索ポイントをグリッド状に生成する。
class GridSearchGenerator {
  GridSearchGenerator._(); // ユーティリティクラスのためインスタンス化を防止

  /// HotPepper APIの最大検索半径（メートル）
  static const double maxApiRadiusMeters = 3000.0;

  /// デフォルトのグリッド間隔（メートル）
  /// API検索半径の2倍未満に設定し、検索範囲の重複を確保
  static const double defaultGridSpacingMeters = 5000.0;

  /// 広域検索かどうかを判定
  ///
  /// [radiusMeters] 検索半径（メートル）
  /// 返り値: 3km超の場合true
  static bool isWideAreaSearch(double radiusMeters) {
    return radiusMeters > maxApiRadiusMeters;
  }

  /// 検索ポイントを生成
  ///
  /// [center] 検索の中心座標
  /// [radiusMeters] 検索半径（メートル）
  /// [gridSpacingMeters] グリッド間隔（メートル）。デフォルトは5km
  ///
  /// 返り値: 検索に使用する座標のリスト
  static List<LatLng> generateSearchPoints({
    required LatLng center,
    required double radiusMeters,
    double gridSpacingMeters = defaultGridSpacingMeters,
  }) {
    // 3km以下なら中心点のみを返す
    if (!isWideAreaSearch(radiusMeters)) {
      return [center];
    }

    final List<LatLng> points = [];

    // グリッドのステップ数を計算
    final int steps = (radiusMeters / gridSpacingMeters).ceil();

    // 緯度・経度1度あたりのメートル数（概算）
    // 緯度: 1度 ≈ 111,320m
    // 経度: 1度 ≈ 111,320m * cos(緯度) ※日本付近（35度）では約91km
    const double metersPerDegreeLat = 111320.0;
    final double metersPerDegreeLng =
        111320.0 * cos(center.latitude * pi / 180);

    // グリッド間隔を度数に変換
    final double latStep = gridSpacingMeters / metersPerDegreeLat;
    final double lngStep = gridSpacingMeters / metersPerDegreeLng;

    // グリッド状にポイントを生成
    for (int i = -steps; i <= steps; i++) {
      for (int j = -steps; j <= steps; j++) {
        final double lat = center.latitude + (i * latStep);
        final double lng = center.longitude + (j * lngStep);

        final LatLng point = LatLng(lat, lng);

        // 中心からの距離が指定半径内の場合のみ追加
        final double distance = calculateDistance(center, point);
        if (distance <= radiusMeters) {
          points.add(point);
        }
      }
    }

    // ポイントが空の場合は少なくとも中心点を返す
    if (points.isEmpty) {
      points.add(center);
    }

    return points;
  }

  /// 2つの座標間の距離を計算（メートル）
  ///
  /// Haversine公式を使用
  static double calculateDistance(LatLng point1, LatLng point2) {
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

  /// 広域検索に必要なAPI呼び出し回数を推定
  ///
  /// [center] 検索の中心座標
  /// [radiusMeters] 検索半径（メートル）
  /// [gridSpacingMeters] グリッド間隔（メートル）
  ///
  /// 返り値: 推定API呼び出し回数
  static int estimateApiCalls({
    required LatLng center,
    required double radiusMeters,
    double gridSpacingMeters = defaultGridSpacingMeters,
  }) {
    return generateSearchPoints(
      center: center,
      radiusMeters: radiusMeters,
      gridSpacingMeters: gridSpacingMeters,
    ).length;
  }

  /// メートルをHotPepper APIのrangeパラメータに変換
  ///
  /// 広域検索の場合は常に最大range（5 = 3000m）を返す
  static int metersToApiRange(double meters) {
    if (meters <= 300) return 1;
    if (meters <= 500) return 2;
    if (meters <= 1000) return 3;
    if (meters <= 2000) return 4;
    return 5; // 3000m or more
  }
}
