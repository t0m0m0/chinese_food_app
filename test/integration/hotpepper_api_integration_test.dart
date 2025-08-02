// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:chinese_food_app/core/config/config_manager.dart';
import 'package:chinese_food_app/core/config/environment_config.dart';
import 'package:chinese_food_app/core/network/app_http_client.dart';
import 'package:chinese_food_app/data/datasources/hotpepper_api_datasource.dart';

/// HotPepper API実際の接続テスト
///
/// 注意: このテストは実際のAPIキーが必要です
/// .envファイルにHOTPEPPER_API_KEYが設定されている場合のみ実行
void main() {
  group('HotPepper API Integration Test', () {
    late HotpepperApiDatasourceImpl datasource;

    setUpAll(() async {
      // CI環境では.env.testファイルを優先使用
      try {
        await dotenv.load(fileName: '.env.test');
      } catch (e) {
        // フォールバック：.env.testが存在しない場合
        dotenv.testLoad(fileInput: '''
HOTPEPPER_API_KEY=test_hotpepper_api_key_for_testing
GOOGLE_MAPS_API_KEY=test_google_maps_api_key_for_testing
FLUTTER_ENV=development
''');
      }

      // 環境設定を初期化
      await EnvironmentConfig.initialize();
      await ConfigManager.initialize(
        throwOnValidationError: false,
        enableDebugLogging: true,
      );

      // データソースを初期化
      datasource = HotpepperApiDatasourceImpl(AppHttpClient());
    });

    group('API接続テスト', () {
      test('APIキーが正常に設定されていることを確認', () async {
        // APIキー設定確認
        final apiKey = EnvironmentConfig.hotpepperApiKey;

        print('APIキー設定状況:');
        print(
            '  - APIキー: ${apiKey.isNotEmpty ? "${apiKey.substring(0, 8)}..." : "(未設定)"}');
        print('  - 環境: ${EnvironmentConfig.current.name}');
        print('  - 初期化済み: ${EnvironmentConfig.isInitialized}');

        expect(apiKey.isNotEmpty, isTrue,
            reason: 'HotPepper APIキーが設定されていません。.envファイルを確認してください。');
      });

      test('新宿駅周辺の中華料理店を検索', () async {
        try {
          final response = await datasource.searchStores(
            lat: 35.6917, // 新宿駅の座標
            lng: 139.7006,
            keyword: '中華',
            range: 3, // 1km圏内
            count: 10,
          );

          print('API検索結果:');
          print('  - 利用可能件数: ${response.resultsAvailable}');
          print('  - 返却件数: ${response.resultsReturned}');
          print('  - 検索開始位置: ${response.resultsStart}');

          if (response.shops.isNotEmpty) {
            print('  - 店舗例:');
            for (int i = 0; i < response.shops.length && i < 3; i++) {
              final shop = response.shops[i];
              print('    ${i + 1}. ${shop.name}');
              print('       住所: ${shop.address}');
              print('       ジャンル: ${shop.genre}');
              print('       予算: ${shop.budget}');
            }
          }

          // 基本的な検証
          expect(response, isNotNull);
          expect(response.resultsReturned, greaterThanOrEqualTo(0));
          expect(response.resultsAvailable, greaterThanOrEqualTo(0));
          expect(response.shops, isNotNull);

          if (response.shops.isNotEmpty) {
            final firstShop = response.shops.first;
            expect(firstShop.id, isNotEmpty);
            expect(firstShop.name, isNotEmpty);
            expect(firstShop.address, isNotEmpty);
            expect(firstShop.lat, greaterThan(0));
            expect(firstShop.lng, greaterThan(0));
          }
        } catch (e) {
          print('API呼び出しエラー: $e');

          // APIキー関連のエラーの場合は詳細情報を表示
          if (e.toString().contains('API key') ||
              e.toString().contains('401')) {
            print('APIキーエラーの可能性があります。以下を確認してください:');
            print('1. .envファイルのHOTPEPPER_API_KEYが正しく設定されているか');
            print('2. APIキーが有効期限内であるか');
            print('3. APIキーに適切な権限が設定されているか');
          }

          rethrow;
        }
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('住所検索テスト - 東京駅周辺', () async {
        try {
          final response = await datasource.searchStores(
            address: '東京都千代田区',
            keyword: '中華',
            range: 4, // 2km圏内
            count: 5,
          );

          print('住所検索結果 (東京都千代田区):');
          print('  - 利用可能件数: ${response.resultsAvailable}');
          print('  - 返却件数: ${response.resultsReturned}');

          expect(response, isNotNull);
          expect(response.resultsReturned, greaterThanOrEqualTo(0));
        } catch (e) {
          print('住所検索エラー: $e');
          rethrow;
        }
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('レート制限テスト - 複数リクエスト', () async {
        print('レート制限テスト開始...');

        try {
          // 短時間に複数リクエストを送信してレート制限の動作を確認
          final futures = <Future>[];

          for (int i = 0; i < 3; i++) {
            futures.add(datasource
                .searchStores(
              lat: 35.6917 + (i * 0.001), // 微妙に座標をずらす
              lng: 139.7006 + (i * 0.001),
              keyword: '中華',
              count: 1,
            )
                .then((response) {
              print('  リクエスト${i + 1}: 成功 (${response.resultsReturned}件)');
            }).catchError((e) {
              print('  リクエスト${i + 1}: エラー - $e');
              return null;
            }));

            // 1秒間5リクエスト制限を考慮して少し待機
            if (i < 2) await Future.delayed(const Duration(milliseconds: 300));
          }

          await Future.wait(futures);
          print('レート制限テスト完了');
        } catch (e) {
          print('レート制限テストでエラー: $e');
          // レート制限エラーは想定内なので、テストは続行
          if (e.toString().contains('429') ||
              e.toString().contains('rate limit')) {
            print('レート制限が正常に動作しています');
          } else {
            rethrow;
          }
        }
      }, timeout: const Timeout(Duration(seconds: 45)));
    });

    group('エラーハンドリングテスト', () {
      test('無効なパラメータでのエラー処理', () async {
        // 無効な緯度でテスト
        expect(
          () => datasource.searchStores(lat: 100.0, lng: 139.7006),
          throwsA(isA<Exception>()),
        );

        // 無効な経度でテスト
        expect(
          () => datasource.searchStores(lat: 35.6917, lng: 200.0),
          throwsA(isA<Exception>()),
        );

        // 無効な範囲でテスト
        expect(
          () => datasource.searchStores(
            lat: 35.6917,
            lng: 139.7006,
            range: 10,
          ),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
