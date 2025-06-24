import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/hotpepper_store_model.dart';

/// ホットペッパーAPI通信のDataSource
class HotpepperApiDatasource {
  final http.Client _client;
  static const String _baseUrl = 'https://webservice.recruit.co.jp/hotpepper/gourmet/v1/';
  
  // 注意: 実際のAPIキーは環境変数から取得すべき
  // TODO: 環境変数またはSecure StorageからAPIキーを取得
  static const String _apiKey = 'YOUR_API_KEY_HERE';

  HotpepperApiDatasource({http.Client? client}) : _client = client ?? http.Client();

  /// 位置情報で店舗を検索
  /// 
  /// [lat] 緯度
  /// [lng] 経度
  /// [range] 検索範囲（1:300m, 2:500m, 3:1000m, 4:2000m, 5:3000m）
  /// [count] 取得件数（デフォルト20件、最大100件）
  /// [start] 検索開始位置（デフォルト1）
  Future<HotpepperSearchResponse> searchByLocation({
    required double lat,
    required double lng,
    int range = 3, // デフォルト1km
    int count = 20,
    int start = 1,
  }) async {
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'key': _apiKey,
        'lat': lat.toString(),
        'lng': lng.toString(),
        'range': range.toString(),
        'count': count.toString(),
        'start': start.toString(),
        'format': 'json',
        'keyword': '中華', // 町中華を検索するキーワード
      });

      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return HotpepperSearchResponse.fromJson(jsonData);
      } else {
        throw Exception('API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to search stores by location: $e');
    }
  }

  /// 住所で店舗を検索
  /// 
  /// [address] 住所文字列
  /// [count] 取得件数（デフォルト20件、最大100件）
  /// [start] 検索開始位置（デフォルト1）
  Future<HotpepperSearchResponse> searchByAddress({
    required String address,
    int count = 20,
    int start = 1,
  }) async {
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'key': _apiKey,
        'address': address,
        'count': count.toString(),
        'start': start.toString(),
        'format': 'json',
        'keyword': '中華', // 町中華を検索するキーワード
      });

      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return HotpepperSearchResponse.fromJson(jsonData);
      } else {
        throw Exception('API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to search stores by address: $e');
    }
  }

  /// 店舗IDで詳細情報を取得
  /// 
  /// [id] 店舗ID
  Future<HotpepperStoreModel?> getStoreDetail(String id) async {
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'key': _apiKey,
        'id': id,
        'format': 'json',
      });

      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        final searchResponse = HotpepperSearchResponse.fromJson(jsonData);
        
        return searchResponse.results.isNotEmpty 
            ? searchResponse.results.first 
            : null;
      } else {
        throw Exception('API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get store detail: $e');
    }
  }

  /// APIキーが設定されているかチェック
  bool get hasValidApiKey => _apiKey != 'YOUR_API_KEY_HERE' && _apiKey.isNotEmpty;

  /// リソース解放
  void dispose() {
    _client.close();
  }
}