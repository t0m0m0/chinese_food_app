import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/data/datasources/hotpepper_proxy_datasource.dart';
import 'package:chinese_food_app/core/network/app_http_client.dart';
import '../helpers/test_env_setup.dart';

void main() {
  group('HotPepper プロキシサーバー統合テスト', () {
    setUp(() async {
      await TestEnvSetup.initializeTestEnvironment();
    });

    tearDown(() {
      TestEnvSetup.cleanupTestEnvironment();
    });

    test('プロキシサーバー経由でのAPI呼び出しテスト', () async {
      print('🔍 プロキシサーバー経由でのAPI呼び出しテスト開始...');
      
      final datasource = HotpepperProxyDatasourceImpl(
        AppHttpClient(),
        proxyBaseUrl: 'https://chinese-food-app-proxy.aka-tomo06.workers.dev',
      );
      
      try {
        // 東京駅周辺での検索
        final result = await datasource.searchStores(
          lat: 35.6812,
          lng: 139.7671,
          keyword: '中華',
          range: 3,
          count: 3,
        );
        
        print('📋 プロキシ経由検索結果:');
        print('- 利用可能件数: ${result.resultsAvailable}');
        print('- 返却件数: ${result.resultsReturned}');
        print('- 店舗数: ${result.shops.length}');
        
        for (int i = 0; i < result.shops.length; i++) {
          final shop = result.shops[i];
          print('- 店舗${i + 1}: ${shop.name} (${shop.address})');
        }
        
        expect(result.resultsAvailable, greaterThan(0));
        expect(result.shops, isNotEmpty);
        expect(result.shops.length, lessThanOrEqualTo(3));
        
      } catch (e, stackTrace) {
        print('❌ プロキシ経由API呼び出しエラー: $e');
        print('スタックトレース: $stackTrace');
        fail('プロキシ経由API呼び出しが失敗しました: $e');
      }
    });

    test('住所指定でのプロキシAPI呼び出しテスト', () async {
      print('🔍 住所指定でのプロキシAPI呼び出しテスト開始...');
      
      final datasource = HotpepperProxyDatasourceImpl(
        AppHttpClient(),
        proxyBaseUrl: 'https://chinese-food-app-proxy.aka-tomo06.workers.dev',
      );
      
      try {
        final result = await datasource.searchStores(
          address: '東京都千代田区',
          keyword: '中華',
          range: 4,
          count: 2,
        );
        
        print('📋 住所指定プロキシ検索結果:');
        print('- 利用可能件数: ${result.resultsAvailable}');
        print('- 返却件数: ${result.resultsReturned}');
        print('- 店舗数: ${result.shops.length}');
        
        expect(result.resultsAvailable, greaterThan(0));
        expect(result.shops, isNotEmpty);
        
      } catch (e, stackTrace) {
        print('❌ 住所指定プロキシAPI呼び出しエラー: $e');
        print('スタックトレース: $stackTrace');
        fail('住所指定プロキシAPI呼び出しが失敗しました: $e');
      }
    });

    test('プロキシサーバーのエラーハンドリングテスト', () async {
      print('🔍 プロキシサーバーのエラーハンドリングテスト開始...');
      
      final datasource = HotpepperProxyDatasourceImpl(
        AppHttpClient(),
        proxyBaseUrl: 'https://chinese-food-app-proxy.aka-tomo06.workers.dev',
      );
      
      try {
        // 無効なパラメータでテスト（住所も緯度経度も未指定）
        await datasource.searchStores(
          keyword: '中華',
          range: 3,
          count: 1,
          // lat, lng, address を全て未指定
        );
        fail('バリデーションエラーが発生すべき');
        
      } catch (e) {
        print('✅ 期待通りのバリデーションエラー: $e');
        expect(e.toString(), contains('住所または緯度経度'));
      }
    });
  });
}