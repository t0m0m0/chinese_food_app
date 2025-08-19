import '../../core/config/api_config.dart';
import '../../core/exceptions/domain_exceptions.dart';
import '../../core/network/base_api_service.dart';
import '../models/hotpepper_store_model.dart';

/// HotPepper プロキシサーバー経由のデータソース
///
/// セキュリティ向上のため、APIキーをサーバーサイドで管理し、
/// プロキシサーバー経由でHotPepper APIにアクセスします。
abstract class HotpepperProxyDatasource {
  /// 店舗検索を実行（プロキシサーバー経由）
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
  /// 例外: プロキシサーバーエラー、レート制限エラー、パラメータエラー等
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

class HotpepperProxyDatasourceImpl extends BaseApiService
    implements HotpepperProxyDatasource {
  /// プロキシサーバーのベースURL
  final String proxyBaseUrl;

  HotpepperProxyDatasourceImpl(
    super.httpClient, {
    this.proxyBaseUrl =
        'https://chinese-food-app-proxy.your-account.workers.dev',
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

    // プロキシサーバーへのリクエストボディ構築
    final requestBody = {
      'lat': lat,
      'lng': lng,
      'address': address,
      'keyword': keyword,
      'range': range,
      'count': count,
      'start': start,
    };

    try {
      // プロキシサーバー経由でAPIリクエスト実行
      return await postAndParse<HotpepperSearchResponse>(
        '$proxyBaseUrl/api/hotpepper/search',
        (json) =>
            HotpepperSearchResponse.fromJson(json as Map<String, dynamic>),
        body: requestBody,
        headers: _buildHeaders(),
      );
    } on NetworkException catch (e) {
      // プロキシサーバーのエラーレスポンスを適切なエラーに変換
      throw _handleProxyException(e);
    } catch (e) {
      throw ApiException('Proxy server request failed: ${e.toString()}');
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

  /// リクエストヘッダーを構築
  Map<String, String> _buildHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...ApiConfig.commonHeaders,
    };
  }

  /// プロキシサーバーのエラーレスポンスを適切なApiExceptionに変換
  ApiException _handleProxyException(NetworkException e) {
    final statusCode = e.statusCode;

    if (statusCode == null) {
      return ApiException('Proxy server network error: ${e.message}');
    }

    switch (statusCode) {
      case 400:
        return ApiException(
          'Invalid request parameters - Please check search criteria',
          statusCode: statusCode,
        );
      case 403:
        return ApiException(
          'Unauthorized access - Origin not allowed',
          statusCode: statusCode,
        );
      case 429:
        return ApiException(
          'Rate limit exceeded - Too many requests to proxy server',
          statusCode: statusCode,
        );
      case 500:
        return ApiException(
          'Proxy server internal error - Please try again later',
          statusCode: statusCode,
        );
      case 502:
      case 503:
      case 504:
        return ApiException(
          'Proxy server or upstream API temporarily unavailable',
          statusCode: statusCode,
        );
      default:
        return ApiException(
          'Proxy server request failed with status $statusCode: ${e.message}',
          statusCode: statusCode,
        );
    }
  }
}

/// テスト用モック実装
class MockHotpepperProxyDatasource implements HotpepperProxyDatasource {
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
    await Future.delayed(const Duration(milliseconds: 300));

    final mockStores = [
      const HotpepperStoreModel(
        id: 'proxy_mock_001',
        name: '町中華 龍華楼（プロキシ経由）',
        address: '東京都新宿区西新宿1-1-1',
        lat: 35.6917,
        lng: 139.7006,
        genre: '中華料理',
        budget: '～1000円',
        access: 'JR新宿駅徒歩5分',
        catch_: 'セキュアなAPI経由でアクセス！',
        photo: null,
      ),
      const HotpepperStoreModel(
        id: 'proxy_mock_002',
        name: '中華料理 福来（プロキシ経由）',
        address: '東京都新宿区西新宿2-2-2',
        lat: 35.6895,
        lng: 139.6917,
        genre: '中華料理',
        budget: '1001～1500円',
        access: 'JR新宿駅徒歩7分',
        catch_: 'APIキー不要でセキュア！',
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
