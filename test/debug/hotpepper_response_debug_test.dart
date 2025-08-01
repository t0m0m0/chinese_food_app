import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/config/config_manager.dart';
import 'package:chinese_food_app/core/config/environment_config.dart';
import 'package:chinese_food_app/core/network/app_http_client.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// HotPepper APIの実際のレスポンス構造を確認するためのデバッグテスト
void main() {
  group('HotPepper API Response Debug', () {
    setUpAll(() async {
      // 環境設定を初期化
      await EnvironmentConfig.initialize();
      await ConfigManager.initialize(
        throwOnValidationError: false,
        enableDebugLogging: true,
      );
    });

    test('実際のAPIレスポンス構造を確認', () async {
      final apiKey = EnvironmentConfig.hotpepperApiKey;
      expect(apiKey.isNotEmpty, isTrue);

      // 直接HTTPリクエストを送信してレスポンスを確認
      final uri =
          Uri.parse('https://webservice.recruit.co.jp/hotpepper/gourmet/v1/')
              .replace(
        queryParameters: {
          'key': apiKey,
          'format': 'json',
          'lat': '35.6917',
          'lng': '139.7006',
          'range': '3',
          'keyword': '中華',
          'count': '3',
        },
      );

      print('リクエストURL: $uri');

      final response = await http.get(uri);

      print('レスポンス情報:');
      print('  - ステータスコード: ${response.statusCode}');
      print('  - Content-Type: ${response.headers['content-type']}');
      print('  - レスポンス長: ${response.body.length}文字');

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          print('  - JSON構造:');
          _printJsonStructure(jsonData, indent: '    ');

          // 実際のレスポンス内容を出力（最初の3行のみ）
          final lines = response.body.split('\n');
          print('  - レスポンス本文（最初の部分）:');
          for (int i = 0; i < lines.length && i < 5; i++) {
            print('    ${i + 1}: ${lines[i]}');
          }
        } catch (e) {
          print('  - JSONパースエラー: $e');
          print('  - レスポンス本文（生データ）:');
          print(
              '    ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');
        }
      } else {
        print('  - エラーレスポンス: ${response.body}');
      }

      expect(response.statusCode, 200);
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}

void _printJsonStructure(dynamic data, {String indent = ''}) {
  if (data is Map) {
    print('${indent}Map (${data.length} keys):');
    data.forEach((key, value) {
      print('${indent}  "$key": ${_getValueType(value)}');
      if (value is Map || value is List) {
        _printJsonStructure(value, indent: '$indent    ');
      }
    });
  } else if (data is List) {
    print('${indent}List (${data.length} items):');
    if (data.isNotEmpty) {
      print('${indent}  [0]: ${_getValueType(data[0])}');
      if (data[0] is Map || data[0] is List) {
        _printJsonStructure(data[0], indent: '$indent    ');
      }
    }
  }
}

String _getValueType(dynamic value) {
  if (value == null) return 'null';
  if (value is String)
    return 'String("${value.length > 50 ? "${value.substring(0, 50)}..." : value}")';
  if (value is int) return 'int($value)';
  if (value is double) return 'double($value)';
  if (value is bool) return 'bool($value)';
  if (value is Map) return 'Map(${value.length} keys)';
  if (value is List) return 'List(${value.length} items)';
  return value.runtimeType.toString();
}
