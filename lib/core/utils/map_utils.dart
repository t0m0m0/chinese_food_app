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

  /// Google Maps APIキーが有効かどうかを検証する
  /// 
  /// [apiKey] Google Maps APIキー文字列
  /// 
  /// Returns: APIキーが有効な形式の場合true、無効な場合false
  static bool isValidGoogleMapsApiKey(String? apiKey) {
    // null, 空文字, 空白のみをチェック
    if (apiKey == null || apiKey.trim().isEmpty) {
      return false;
    }
    
    final trimmedApiKey = apiKey.trim();
    
    // ダミーキーやプレースホルダーをチェック
    const invalidKeys = [
      'AIzaSyDUMMY_KEY_FOR_CI_ENVIRONMENT',
      'YOUR_API_KEY_HERE',
      'YOUR_GOOGLE_MAPS_API_KEY',
      '\${GOOGLE_MAPS_API_KEY}',
    ];
    
    if (invalidKeys.contains(trimmedApiKey)) {
      return false;
    }
    
    // Google Maps API キーの基本的な形式チェック
    // AIzaSy で始まり、39文字の英数字とハイフン、アンダースコアで構成
    final apiKeyPattern = RegExp(r'^AIzaSy[A-Za-z0-9_-]{33}$');
    
    return apiKeyPattern.hasMatch(trimmedApiKey);
  }
}