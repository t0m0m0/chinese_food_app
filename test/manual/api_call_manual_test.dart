import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/config/config_manager.dart';
import 'package:chinese_food_app/core/config/environment_config.dart';
import 'package:chinese_food_app/core/di/app_di_container.dart';
import 'package:chinese_food_app/domain/repositories/store_repository.dart';
import 'package:chinese_food_app/domain/entities/location.dart';

/// アプリのDIコンテナを通じてAPIコールが正常に動作することを確認する手動テスト
void main() {
  group('Manual API Call Test via DI Container', () {
    late AppDIContainer container;
    late StoreRepository storeRepository;

    setUpAll(() async {
      // 環境設定を初期化
      await EnvironmentConfig.initialize();
      await ConfigManager.initialize(
        throwOnValidationError: false,
        enableDebugLogging: true,
      );

      // DIコンテナーを作成・設定
      container = AppDIContainer();
      container.configure();

      // StoreRepositoryを取得
      storeRepository = container.getStoreRepository();
    });

    test('DIコンテナ経由でのAPI検索テスト', () async {
      print('=== DIコンテナ経由での店舗検索テスト ===');

      // 新宿駅の位置情報
      final location =
          Location(latitude: 35.6917, longitude: 139.7006, address: '東京都新宿区');

      try {
        final stores = await storeRepository.searchStores(
          location: location,
          keyword: '中華',
          radius: 1000, // 1km圏内
        );

        print('検索結果:');
        print('  - 取得件数: ${stores.length}件');

        if (stores.isNotEmpty) {
          print('  - 店舗一覧:');
          for (int i = 0; i < stores.length && i < 5; i++) {
            final store = stores[i];
            print('    ${i + 1}. ${store.name}');
            print('       住所: ${store.address}');
            print(
                '       座標: (${store.location?.latitude}, ${store.location?.longitude})');

            if (store.genre != null) {
              print('       ジャンル: ${store.genre}');
            }
            if (store.budget != null) {
              print('       予算: ${store.budget}');
            }
            print('');
          }
        }

        // 基本検証
        expect(stores, isNotNull);
        expect(stores, isA<List>());

        if (stores.isNotEmpty) {
          final firstStore = stores.first;
          expect(firstStore.id, isNotEmpty);
          expect(firstStore.name, isNotEmpty);
          expect(firstStore.address, isNotEmpty);
        }

        print('✅ APIコール成功: 正常にデータを取得できました');
      } catch (e, stackTrace) {
        print('❌ APIコールエラー: $e');
        print('スタックトレース: $stackTrace');
        rethrow;
      }
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('キーワード検索テスト', () async {
      print('=== キーワード検索テスト ===');

      try {
        final stores = await storeRepository.searchStoresByKeyword(
          keyword: '中華 ラーメン',
          location: Location(
              latitude: 35.6917, longitude: 139.7006, address: '東京都新宿区'),
        );

        print('キーワード検索結果:');
        print('  - 検索語: "中華 ラーメン"');
        print('  - 取得件数: ${stores.length}件');

        expect(stores, isNotNull);
        expect(stores, isA<List>());

        print('✅ キーワード検索成功');
      } catch (e) {
        print('❌ キーワード検索エラー: $e');
        rethrow;
      }
    }, timeout: const Timeout(Duration(seconds: 30)));

    tearDownAll(() {
      container.dispose();
    });
  });
}
