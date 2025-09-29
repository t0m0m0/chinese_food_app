import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/config/app_config.dart';
import 'package:chinese_food_app/core/config/api_diagnostics.dart';
import 'package:chinese_food_app/core/config/api_connection_tester.dart';
import 'package:chinese_food_app/data/datasources/hotpepper_api_datasource.dart';
import 'package:chinese_food_app/core/network/app_http_client.dart';
import '../helpers/test_env_setup.dart';

void main() {
  group('実際のAPI接続統合テスト', () {
    setUp(() async {
      await TestEnvSetup.initializeTestEnvironment();
      // 実際のAPIキーを使用（テスト用でない実キー）
      TestEnvSetup.setTestApiKey('HOTPEPPER_API_KEY', 'fd73df944f46ca43');
    });

    tearDown(() {
      TestEnvSetup.cleanupTestEnvironment();
    });

    test('実際のHotPepper APIキーでの接続テスト', () async {
      print('🔍 実際のAPIキーでの接続テストを開始...');
      
      // API診断実行
      final diagnostics = await ApiDiagnostics.getComprehensiveDiagnostics(forceRefresh: true);
      print('📋 診断結果:');
      print(diagnostics.toString());
      
      expect(diagnostics.isConfigValid, isTrue, reason: '設定が有効である必要があります');
      expect(diagnostics.hotpepperApiKeyStatus, equals('available'), 
          reason: 'APIキーが利用可能である必要があります');
    });

    test('実際のAPI呼び出しテスト', () async {
      print('🔍 実際のAPI呼び出しテストを開始...');
      
      // API接続テスト実行
      final result = await ApiConnectionTester.testActualApiCall();
      print('📋 接続テスト結果: ${result.toString()}');
      
      if (!result.isSuccessful) {
        print('❌ エラー詳細: ${result.errorMessage}');
        print('⏱️ 実行時間: ${result.duration.inMilliseconds}ms');
      }
      
      expect(result.isSuccessful, isTrue, 
          reason: '実際のAPI呼び出しが成功する必要があります: ${result.errorMessage}');
    });

    test('HotpepperApiDatasourceImplでの実際のAPI呼び出し', () async {
      print('🔍 HotpepperApiDatasourceImplでの実際のAPI呼び出しテスト...');
      
      final datasource = HotpepperApiDatasourceImpl(AppHttpClient());
      
      try {
        final searchResult = await datasource.searchStores(
          keyword: '中華',
          count: 1,
        );
        
        print('📋 検索結果:');
        print('- 利用可能件数: ${searchResult.resultsAvailable}');
        print('- 返却件数: ${searchResult.resultsReturned}');
        print('- 開始位置: ${searchResult.resultsStart}');
        print('- 店舗数: ${searchResult.shops.length}');
        
        if (searchResult.shops.isNotEmpty) {
          final shop = searchResult.shops.first;
          print('- 最初の店舗: ${shop.name}');
          print('- 住所: ${shop.address}');
          print('- ジャンル: ${shop.genre}');
        }
        
        expect(searchResult.resultsAvailable, greaterThan(0), 
            reason: '検索結果が1件以上ある必要があります');
        expect(searchResult.shops, isNotEmpty, 
            reason: '店舗リストが空でない必要があります');
        
      } catch (e, stackTrace) {
        print('❌ API呼び出しエラー: $e');
        print('スタックトレース: $stackTrace');
        fail('API呼び出しが失敗しました: $e');
      }
    });

    test('位置指定でのAPI呼び出しテスト', () async {
      print('🔍 位置指定でのAPI呼び出しテスト（東京駅周辺）...');
      
      final datasource = HotpepperApiDatasourceImpl(AppHttpClient());
      
      try {
        final searchResult = await datasource.searchStores(
          lat: 35.6812, // 東京駅の緯度
          lng: 139.7671, // 東京駅の経度
          keyword: '中華',
          count: 5,
        );
        
        print('📋 位置指定検索結果:');
        print('- 利用可能件数: ${searchResult.resultsAvailable}');
        print('- 返却件数: ${searchResult.resultsReturned}');
        print('- 店舗数: ${searchResult.shops.length}');
        
        for (int i = 0; i < searchResult.shops.length; i++) {
          final shop = searchResult.shops[i];
          print('- 店舗${i + 1}: ${shop.name} (${shop.address})');
        }
        
        expect(searchResult.resultsAvailable, greaterThan(0), 
            reason: '東京駅周辺で中華料理店が見つかる必要があります');
        
      } catch (e, stackTrace) {
        print('❌ 位置指定API呼び出しエラー: $e');
        print('スタックトレース: $stackTrace');
        fail('位置指定API呼び出しが失敗しました: $e');
      }
    });
  });
}