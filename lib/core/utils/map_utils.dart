/// 地図関連のユーティリティクラス
class MapUtils {
  MapUtils._(); // プライベートコンストラクタでインスタンス化防止

  /// 座標値が有効かどうかを検証する
  /// 
  /// [lat] 緯度 (-90.0 ~ 90.0)
  /// [lng] 経度 (-180.0 ~ 180.0)
  /// 
  /// Returns: 座標値が有効な場合true、無効な場合false
  static bool isValidCoordinate(double lat, double lng) {
    // NaN や Infinity をチェック
    if (lat.isNaN || lng.isNaN || lat.isInfinite || lng.isInfinite) {
      return false;
    }
    
    // 緯度は -90.0 ~ 90.0 の範囲
    if (lat < -90.0 || lat > 90.0) {
      return false;
    }
    
    // 経度は -180.0 ~ 180.0 の範囲  
    if (lng < -180.0 || lng > 180.0) {
      return false;
    }
    
    return true;
  }
}