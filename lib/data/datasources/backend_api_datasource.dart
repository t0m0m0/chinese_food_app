import '../../core/config/api_config.dart';
import '../../core/exceptions/domain_exceptions.dart';
import '../../core/network/base_api_service.dart';
import '../models/hotpepper_store_model.dart';

/// バックエンドAPI経由のデータソース抽象クラス
///
/// セキュリティ向上のため、自前のバックエンドAPI経由で
/// 各種外部API（HotPepper等）にアクセスします。
///
/// 利点:
/// - APIキーの完全保護
/// - レート制限とコスト制御
/// - セキュリティ監査・監視
/// - ビジネスロジックの中央管理
abstract class BackendApiDatasource {
  /// 店舗検索を実行（バックエンドAPI経由）
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
  /// 例外: 認証エラー、レート制限エラー、パラメータエラー等
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

/// バックエンドAPI実装クラス
///
/// セキュアなバックエンドAPI経由で店舗検索を実行
class BackendApiDatasourceImpl extends BaseApiService
    implements BackendApiDatasource {
  /// バックエンドAPIのベースURL
  final String baseUrl;

  /// APIアクセストークン（JWT等）
  final String apiToken;

  BackendApiDatasourceImpl(
    super.httpClient, {
    required this.baseUrl,
    required this.apiToken,
  });

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
    _validateParameters(lat, lng, address, range, count, start);

    // APIトークン検証
    _validateApiToken();

    // リクエストボディ構築
    final requestBody = _buildRequestBody(
      lat: lat,
      lng: lng,
      address: address,
      keyword: keyword,
      range: range,
      count: count,
      start: start,
    );

    try {
      // バックエンドAPI経由でリクエスト実行
      return await postAndParse<HotpepperSearchResponse>(
        '$baseUrl/api/stores/search',
        (json) => _parseBackendResponse(json as Map<String, dynamic>, start),
        body: requestBody,
        headers: _buildHeaders(),
      );
    } on NetworkException catch (e) {
      // バックエンドAPIのエラーレスポンスを適切なエラーに変換
      throw _handleBackendException(e);
    } catch (e) {
      throw ApiException('Backend API request failed: ${e.toString()}');
    }
  }

  /// パラメータの妥当性を検証
  void _validateParameters(double? lat, double? lng, String? address, int range,
      int count, int start) {
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

    // 住所または緯度経度のいずれかが必要
    final hasAddress = address != null && address.isNotEmpty;
    final hasLatLng = lat != null && lng != null;
    if (!hasAddress && !hasLatLng) {
      throw ValidationException('住所または緯度経度を指定してください');
    }
  }

  /// APIトークンの検証
  void _validateApiToken() {
    if (apiToken.isEmpty) {
      throw ApiException('APIトークンが設定されていません。認証情報を確認してください。');
    }
  }

  /// リクエストボディの構築
  Map<String, dynamic> _buildRequestBody({
    double? lat,
    double? lng,
    String? address,
    String? keyword,
    required int range,
    required int count,
    required int start,
  }) {
    final requestBody = <String, dynamic>{
      'range': range,
      'count': count,
      'start': start,
      'keyword': keyword ?? '中華',
    };

    if (lat != null && lng != null) {
      requestBody['lat'] = lat;
      requestBody['lng'] = lng;
    }

    if (address != null && address.isNotEmpty) {
      requestBody['address'] = address;
    }

    return requestBody;
  }

  /// リクエストヘッダーを構築
  Map<String, String> _buildHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $apiToken',
      ...ApiConfig.commonHeaders,
    };
  }

  /// バックエンドAPIレスポンスを解析
  HotpepperSearchResponse _parseBackendResponse(
      Map<String, dynamic> json, int start) {
    if (json['success'] != true) {
      throw ApiException(
          'Backend API returned error: ${json['error'] ?? 'Unknown error'}');
    }

    final data = json['data'] as Map<String, dynamic>;
    final storesData = data['stores'] as List<dynamic>;
    final pagination = data['pagination'] as Map<String, dynamic>;

    final stores = storesData
        .map((storeJson) => _convertBackendStoreToHotpepperModel(
            storeJson as Map<String, dynamic>))
        .toList();

    return HotpepperSearchResponse(
      shops: stores,
      resultsAvailable: pagination['totalCount'] as int,
      resultsReturned: stores.length,
      resultsStart: start,
    );
  }

  /// バックエンドAPIの店舗データをHotpepperModelに変換
  HotpepperStoreModel _convertBackendStoreToHotpepperModel(
      Map<String, dynamic> json) {
    return HotpepperStoreModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      genre: json['genre']?['name'] as String?,
      budget: json['budget']?['average'] as String?,
      access: json['access'] as String?,
      catch_: json['catch'] as String?,
      photo: json['photo']?['pc']?['l'] as String?,
    );
  }

  /// バックエンドAPIのエラーレスポンスを適切なApiExceptionに変換
  ApiException _handleBackendException(NetworkException e) {
    final statusCode = e.statusCode;

    if (statusCode == null) {
      return ApiException('Backend API network error: ${e.message}');
    }

    switch (statusCode) {
      case 400:
        return ApiException(
          'Invalid request parameters - Please check search criteria',
          statusCode: statusCode,
        );
      case 401:
      case 403:
        return ApiException(
          '認証エラー - APIトークンを確認してください',
          statusCode: statusCode,
        );
      case 429:
        return ApiException(
          'Rate limit exceeded - Too many requests to backend API',
          statusCode: statusCode,
        );
      case 500:
        return ApiException(
          'Backend API internal error - Please try again later',
          statusCode: statusCode,
        );
      case 502:
      case 503:
      case 504:
        return ApiException(
          'Backend API or upstream service temporarily unavailable',
          statusCode: statusCode,
        );
      default:
        return ApiException(
          'Backend API request failed with status $statusCode: ${e.message}',
          statusCode: statusCode,
        );
    }
  }
}

/// テスト用モック実装
class MockBackendApiDatasource implements BackendApiDatasource {
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
    // ネットワーク遅延をシミュレート
    await Future.delayed(const Duration(milliseconds: 200));

    final mockStores = [
      const HotpepperStoreModel(
        id: 'backend_mock_001',
        name: '町中華 龍華楼（バックエンドAPI経由）',
        address: '東京都新宿区西新宿1-1-1',
        lat: 35.6917,
        lng: 139.7006,
        genre: '中華料理',
        budget: '～1000円',
        access: 'JR新宿駅徒歩5分',
        catch_: 'セキュアなバックエンドAPI経由！',
        photo: null,
      ),
      const HotpepperStoreModel(
        id: 'backend_mock_002',
        name: '中華料理 福来（バックエンドAPI経由）',
        address: '東京都新宿区西新宿2-2-2',
        lat: 35.6895,
        lng: 139.6917,
        genre: '中華料理',
        budget: '1001～1500円',
        access: 'JR新宿駅徒歩7分',
        catch_: 'APIキー完全保護・レート制限対応！',
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
