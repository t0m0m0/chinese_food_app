/// バックエンドAPI関連の定数定義
///
/// BackendApiDatasourceで使用される各種制限値や設定値を一元管理
class BackendApiConstants {
  BackendApiConstants._(); // プライベートコンストラクタで instantiation を防ぐ

  /// 検索範囲の制限値
  static const int minSearchRange = 1; // 300m
  static const int maxSearchRange = 5; // 3000m

  /// 取得件数の制限値
  static const int minResultCount = 1;
  static const int maxResultCount = 100;

  /// 検索開始位置の制限値
  static const int minStartPosition = 1;

  /// 緯度の有効範囲
  static const double minLatitude = -90.0;
  static const double maxLatitude = 90.0;

  /// 経度の有効範囲
  static const double minLongitude = -180.0;
  static const double maxLongitude = 180.0;

  /// デフォルト検索キーワード
  static const String defaultKeyword = '中華';

  /// APIトークン関連
  static const int minApiTokenLength = 16;
  static const String apiTokenPattern = r'^[A-Za-z0-9._-]+$';

  /// APIエンドポイント
  static const String searchEndpoint = '/api/stores/search';

  /// HTTPヘッダー関連
  static const String contentTypeJson = 'application/json';
  static const String acceptJson = 'application/json';
  static const String authorizationPrefix = 'Bearer';

  /// レスポンス構造のキー名
  static const String responseSuccessKey = 'success';
  static const String responseDataKey = 'data';
  static const String responseStoresKey = 'stores';
  static const String responsePaginationKey = 'pagination';
  static const String responseTotalCountKey = 'totalCount';
  static const String responseErrorKey = 'error';
}
