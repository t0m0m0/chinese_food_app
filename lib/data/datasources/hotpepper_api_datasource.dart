import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../../core/config/app_config.dart';
import '../models/hotpepper_store_model.dart';

abstract class HotpepperApiDatasource {
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

class HotpepperApiDatasourceImpl implements HotpepperApiDatasource {
  final http.Client client;

  HotpepperApiDatasourceImpl({
    required this.client,
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
    if (lat != null && (lat < -90.0 || lat > 90.0)) {
      throw ArgumentError('緯度は-90.0から90.0の範囲で指定してください');
    }
    if (lng != null && (lng < -180.0 || lng > 180.0)) {
      throw ArgumentError('経度は-180.0から180.0の範囲で指定してください');
    }
    if (range < 1 || range > 5) {
      throw ArgumentError('検索範囲は1から5の間で指定してください');
    }
    if (count < 1 || count > 100) {
      throw ArgumentError('取得件数は1から100の間で指定してください');
    }
    if (start < 1) {
      throw ArgumentError('検索開始位置は1以上で指定してください');
    }

    // APIキー取得（本番環境では非同期版を使用）
    final apiKey = AppConfig.isProduction 
        ? await AppConfig.hotpepperApiKey 
        : AppConfig.hotpepperApiKeySync;
        
    final hasApiKey = AppConfig.isProduction 
        ? await AppConfig.hasHotpepperApiKeyAsync 
        : AppConfig.hasHotpepperApiKey;
        
    if (!hasApiKey) {
      throw Exception(
          'HotPepper API key is not configured. Please set HOTPEPPER_API_KEY environment variable.');
    }

    final queryParams = <String, String>{
      'key': apiKey!,
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

    if (keyword != null && keyword.isNotEmpty) {
      queryParams['keyword'] = keyword;
    } else {
      queryParams['keyword'] = '中華';
    }

    final uri = Uri.parse(AppConstants.hotpepperApiUrl).replace(
      queryParameters: queryParams,
    );

    try {
      final response = await client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'MachiApp/1.0.0',
        },
      );

      if (response.statusCode == 200) {
        return HotpepperSearchResponse.fromJsonString(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key');
      } else if (response.statusCode == 429) {
        throw Exception('API rate limit exceeded');
      } else {
        throw Exception('API request failed: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: $e');
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
