import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/store.dart';

/// 地図表示とマーカー管理を行うサービス
///
/// Google Maps SDKを使用して店舗位置を地図上に表示する
class MapService {
  /// 店舗リストからマーカーセットを作成
  ///
  /// [stores] 表示する店舗のリスト
  /// 戻り値: Google Maps用のマーカーセット
  static Set<Marker> createMarkersFromStores(List<Store> stores) {
    return stores.map((store) {
      return Marker(
        markerId: MarkerId(store.id),
        position: LatLng(store.lat, store.lng),
        infoWindow: InfoWindow(
          title: store.name,
          snippet: store.address,
        ),
        icon: _getMarkerIcon(store.status ?? StoreStatus.wantToGo),
      );
    }).toSet();
  }

  /// 店舗ステータスに応じたマーカーアイコンを取得
  ///
  /// [status] 店舗のステータス
  /// 戻り値: 対応するマーカーアイコン
  static BitmapDescriptor _getMarkerIcon(StoreStatus status) {
    switch (status) {
      case StoreStatus.wantToGo:
        return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange);
      case StoreStatus.visited:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case StoreStatus.bad:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  /// 店舗リストを含む適切な地図範囲を計算
  ///
  /// [stores] 表示する店舗のリスト
  /// 戻り値: 全店舗を含む地図範囲
  static LatLngBounds? calculateBounds(List<Store> stores) {
    if (stores.isEmpty) return null;

    double minLat = stores.first.lat;
    double maxLat = stores.first.lat;
    double minLng = stores.first.lng;
    double maxLng = stores.first.lng;

    for (final store in stores) {
      minLat = minLat < store.lat ? minLat : store.lat;
      maxLat = maxLat > store.lat ? maxLat : store.lat;
      minLng = minLng < store.lng ? minLng : store.lng;
      maxLng = maxLng > store.lng ? maxLng : store.lng;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  /// デフォルトの地図設定を取得
  ///
  /// 戻り値: 推奨される地図設定
  static MapType get defaultMapType => MapType.normal;

  /// デフォルトのズームレベル
  static const double defaultZoom = 15.0;

  /// 東京駅を中心とした初期カメラ位置
  static const CameraPosition defaultCameraPosition = CameraPosition(
    target: LatLng(35.6812, 139.7671), // 東京駅
    zoom: defaultZoom,
  );
}
