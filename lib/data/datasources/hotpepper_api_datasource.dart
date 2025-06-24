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
    final apiKey = AppConfig.hotpepperApiKey;
    if (!AppConfig.hasHotpepperApiKey) {
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
