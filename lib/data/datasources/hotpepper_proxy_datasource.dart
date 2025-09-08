import '../../core/config/api_config.dart';
import '../../core/exceptions/domain_exceptions.dart';
import '../../core/network/base_api_service.dart';
import '../models/hotpepper_store_model.dart';
import 'hotpepper_proxy_constants.dart';

/// HotPepper プロキシサーバー経由のデータソース
///
/// セキュリティ向上のため、APIキーをサーバーサイドで管理し、
/// プロキシサーバー経由でHotPepper APIにアクセスします。
///
/// ## 利点
/// - APIキーの完全保護（フロントエンドに露出なし）
/// - Cloudflare Workersによる高速・高可用性
/// - CORS対応済み
/// - レート制限の一元管理
///
/// ## 使用例
/// ```dart
/// final datasource = HotpepperProxyDatasourceImpl(
///   AppHttpClient(),
///   proxyBaseUrl: 'https://chinese-food-app-proxy.example.workers.dev',
/// );
///
/// final result = await datasource.searchStores(
///   lat: 35.6917, lng: 139.7006,
///   keyword: '中華', range: 3, count: 20
/// );
/// ```
///
/// ## プロキシサーバー設定
/// Cloudflare Workersでの環境変数:
/// ```
/// HOTPEPPER_API_KEY=your_hotpepper_api_key_here
/// ```
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
    this.proxyBaseUrl = HotpepperProxyConstants.defaultProxyUrl,
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
        '$proxyBaseUrl${HotpepperProxyConstants.searchEndpoint}',
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
    // 緯度の検証
    if (lat != null &&
        (lat < HotpepperProxyConstants.minLatitude ||
            lat > HotpepperProxyConstants.maxLatitude)) {
      throw ValidationException(
          '緯度は${HotpepperProxyConstants.minLatitude}から${HotpepperProxyConstants.maxLatitude}の範囲で指定してください\n'
          'Latitude must be between ${HotpepperProxyConstants.minLatitude} and ${HotpepperProxyConstants.maxLatitude}',
          fieldName: 'lat');
    }

    // 経度の検証
    if (lng != null &&
        (lng < HotpepperProxyConstants.minLongitude ||
            lng > HotpepperProxyConstants.maxLongitude)) {
      throw ValidationException(
          '経度は${HotpepperProxyConstants.minLongitude}から${HotpepperProxyConstants.maxLongitude}の範囲で指定してください\n'
          'Longitude must be between ${HotpepperProxyConstants.minLongitude} and ${HotpepperProxyConstants.maxLongitude}',
          fieldName: 'lng');
    }

    // 検索範囲の検証
    if (range < HotpepperProxyConstants.minSearchRange ||
        range > HotpepperProxyConstants.maxSearchRange) {
      throw ValidationException(
          '検索範囲は${HotpepperProxyConstants.minSearchRange}から${HotpepperProxyConstants.maxSearchRange}の間で指定してください\n'
          'Search range must be between ${HotpepperProxyConstants.minSearchRange} and ${HotpepperProxyConstants.maxSearchRange}',
          fieldName: 'range');
    }

    // 取得件数の検証
    if (count < HotpepperProxyConstants.minResultCount ||
        count > HotpepperProxyConstants.maxResultCount) {
      throw ValidationException(
          '取得件数は${HotpepperProxyConstants.minResultCount}から${HotpepperProxyConstants.maxResultCount}の間で指定してください\n'
          'Result count must be between ${HotpepperProxyConstants.minResultCount} and ${HotpepperProxyConstants.maxResultCount}',
          fieldName: 'count');
    }

    // 検索開始位置の検証
    if (start < HotpepperProxyConstants.minStartPosition) {
      throw ValidationException(
          '検索開始位置は${HotpepperProxyConstants.minStartPosition}以上で指定してください\n'
          'Start position must be ${HotpepperProxyConstants.minStartPosition} or greater',
          fieldName: 'start');
    }

    // 住所または緯度経度のいずれかが必要
    final hasAddress = address != null && address.isNotEmpty;
    final hasLatLng = lat != null && lng != null;
    if (!hasAddress && !hasLatLng) {
      throw ValidationException('住所または緯度経度を指定してください\n'
          'Either address or latitude/longitude must be specified');
    }
  }

  /// リクエストヘッダーを構築
  Map<String, String> _buildHeaders() {
    return {
      'Content-Type': HotpepperProxyConstants.contentTypeJson,
      'Accept': HotpepperProxyConstants.acceptJson,
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
          '不正なリクエストパラメータ - 検索条件を確認してください\n'
          'Invalid request parameters - Please check search criteria',
          statusCode: statusCode,
        );
      case 403:
        return ApiException(
          'アクセス拒否 - オリジンが許可されていません\n'
          'Unauthorized access - Origin not allowed',
          statusCode: statusCode,
        );
      case 429:
        return ApiException(
          'レート制限エラー - プロキシサーバーへのリクエストが多すぎます\n'
          'Rate limit exceeded - Too many requests to proxy server',
          statusCode: statusCode,
        );
      case 500:
        return ApiException(
          'プロキシサーバー内部エラー - しばらく待ってから再試行してください\n'
          'Proxy server internal error - Please try again later',
          statusCode: statusCode,
        );
      case 502:
      case 503:
      case 504:
        return ApiException(
          'プロキシサーバーまたは上位APIが一時的に利用できません\n'
          'Proxy server or upstream API temporarily unavailable',
          statusCode: statusCode,
        );
      default:
        return ApiException(
          'プロキシサーバーリクエストが失敗しました（ステータス: $statusCode）\n'
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
