import '../../core/config/api_config.dart';
import '../../core/config/config_manager.dart';
import '../../core/network/base_api_service.dart';
import '../../core/exceptions/domain_exceptions.dart';
import '../models/hotpepper_store_model.dart';

/// HotPepper API データソース抽象クラス
///
/// HotPepper API制限:
/// - 1日3,000リクエスト
/// - 1秒間5リクエスト
/// - HTTPSでのアクセス必須
/// - APIキー必須
abstract class HotpepperApiDatasource {
  /// 店舗検索を実行
  ///
  /// [lat] 緯度 (-90.0 〜 90.0)
  /// [lng] 経度 (-180.0 〜 180.0)
  /// [address] 住所での検索
  /// [keyword] キーワード検索 (デフォルト: "中華")
  /// [range] 検索範囲 (1:300m, 2:500m, 3:1000m, 4:2000m, 5:3000m)
  /// [count] 取得件数 (1-100)
  /// [start] 検索開始位置 (1以上)
  ///
  /// 戻り値: [HotpepperSearchResponse] 検索結果
  /// 例外: APIキーエラー、レート制限エラー、パラメータエラー等
  Future<HotpepperSearchResponse> searchStores({
    double? lat,
    double? lng,
    String? address,
    String? keyword,
    int range = 3,
    int count = 20,
    int start = 1,
  });
}

class HotpepperApiDatasourceImpl extends BaseApiService
    implements HotpepperApiDatasource {
  HotpepperApiDatasourceImpl(super.httpClient);

  @override
  Future<HotpepperSearchResponse> searchStores({
    double? lat,
    double? lng,
    String? address,
    String? keyword,
    int range = 3,
    int count = 20,
    int start = 1,
  }) async {
    // パラメータ検証
    _validateParameters(lat, lng, range, count, start);

    // APIキー取得と検証
    final apiKey = await _getApiKey();

    // クエリパラメータ構築
    final queryParams = _buildQueryParameters(
      apiKey: apiKey,
      lat: lat,
      lng: lng,
      address: address,
      keyword: keyword,
      range: range,
      count: count,
      start: start,
    );

    try {
      // 新しいHTTPシステムを使用してAPIリクエスト実行
      return await getAndParse<HotpepperSearchResponse>(
        ApiConfig.hotpepperApiUrl,
        (json) =>
            HotpepperSearchResponse.fromJson(json as Map<String, dynamic>),
        queryParameters: queryParams,
        headers: ApiConfig.commonHeaders,
      );
    } on NetworkException catch (e) {
      // 特定のHTTPステータスコードに基づいて適切なエラーメッセージを提供
      throw _handleNetworkException(e);
    } catch (e) {
      throw ApiException('HotPepper API request failed: ${e.toString()}');
    }
  }

  /// パラメータの妥当性を検証
  void _validateParameters(
      double? lat, double? lng, int range, int count, int start) {
    if (lat != null && (lat < -90.0 || lat > 90.0)) {
      throw ValidationException('緯度は-90.0から90.0の範囲で指定してください', fieldName: 'lat');
    }
    if (lng != null && (lng < -180.0 || lng > 180.0)) {
      throw ValidationException('経度は-180.0から180.0の範囲で指定してください',
          fieldName: 'lng');
    }
    if (range < 1 || range > 5) {
      throw ValidationException('検索範囲は1から5の間で指定してください', fieldName: 'range');
    }
    if (count < 1 || count > 100) {
      throw ValidationException('取得件数は1から100の間で指定してください', fieldName: 'count');
    }
    if (start < 1) {
      throw ValidationException('検索開始位置は1以上で指定してください', fieldName: 'start');
    }
  }

  /// APIキーの取得と存在確認
  Future<String> _getApiKey() async {
    if (!ConfigManager.isInitialized) {
      throw ApiException(
        'ConfigManagerが初期化されていません。main()でConfigManager.initialize()を呼び出してください。',
      );
    }

    final apiKey = ConfigManager.hotpepperApiKey;
    final hasValidApiKeys = ConfigManager.hasValidApiKeys;

    if (!hasValidApiKeys || apiKey.isEmpty) {
      throw ApiException(
        'HotPepper APIキーが設定されていません。HOTPEPPER_API_KEY環境変数を設定してください。',
      );
    }

    return apiKey;
  }

  /// クエリパラメータの構築
  Map<String, String> _buildQueryParameters({
    required String apiKey,
    double? lat,
    double? lng,
    String? address,
    String? keyword,
    required int range,
    required int count,
    required int start,
  }) {
    final queryParams = <String, String>{
      'key': apiKey,
      'format': 'json',
      'count': count.toString(),
      'start': start.toString(),
      'range': range.toString(),
    };

    if (lat != null && lng != null) {
      queryParams['lat'] = lat.toString();
      queryParams['lng'] = lng.toString();
    }

    if (address != null && address.isNotEmpty) {
      queryParams['address'] = address;
    }

    // キーワードが指定されていない場合はデフォルトで「中華」を設定
    queryParams['keyword'] =
        (keyword != null && keyword.isNotEmpty) ? keyword : '中華';

    return queryParams;
  }

  /// NetworkExceptionを適切なApiExceptionに変換
  ApiException _handleNetworkException(NetworkException e) {
    final statusCode = e.statusCode;

    if (statusCode == null) {
      return ApiException('Network error: ${e.message}');
    }

    switch (statusCode) {
      case 401:
        return ApiException(
          'Invalid API key - Please check your HotPepper API key configuration',
          statusCode: statusCode,
        );
      case 429:
        return ApiException(
          'API rate limit exceeded - HotPepper API allows max 5 requests/second and 3000 requests/day',
          statusCode: statusCode,
        );
      case 400:
        return ApiException(
          'Invalid request parameters - Please check search criteria',
          statusCode: statusCode,
        );
      case >= 500:
        return ApiException(
          'HotPepper API server error ($statusCode) - Please try again later',
          statusCode: statusCode,
        );
      default:
        return ApiException(
          'API request failed with status $statusCode: ${e.message}',
          statusCode: statusCode,
        );
    }
  }
}

class MockHotpepperApiDatasource implements HotpepperApiDatasource {
  @override
  Future<HotpepperSearchResponse> searchStores({
    double? lat,
    double? lng,
    String? address,
    String? keyword,
    int range = 3,
    int count = 20,
    int start = 1,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final mockStores = [
      HotpepperStoreModel(
        id: 'mock_001',
        name: '町中華 龍華楼',
        address: '東京都新宿区西新宿1-1-1',
        lat: 35.6917,
        lng: 139.7006,
        genre: '中華料理',
        budget: '～1000円',
        access: 'JR新宿駅徒歩5分',
        catch_: '昔ながらの町中華！',
        photo: null,
      ),
      HotpepperStoreModel(
        id: 'mock_002',
        name: '中華料理 福来',
        address: '東京都新宿区西新宿2-2-2',
        lat: 35.6895,
        lng: 139.6917,
        genre: '中華料理',
        budget: '1001～1500円',
        access: 'JR新宿駅徒歩7分',
        catch_: '本格的な中華を気軽に！',
        photo: null,
      ),
    ];

    return HotpepperSearchResponse(
      shops: mockStores,
      resultsAvailable: mockStores.length,
      resultsReturned: mockStores.length,
      resultsStart: start,
    );
  }
}
