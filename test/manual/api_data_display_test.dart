// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/di/app_di_container.dart';
import 'package:chinese_food_app/presentation/providers/store_provider.dart';
import '../helpers/test_env_setup.dart';

/// APIから取得したデータが正常に表示されるかを確認するテスト
void main() {
  group('API Data Display Test', () {
    late AppDIContainer container;
    late StoreProvider storeProvider;

    setUpAll(() async {
      print('=== APIデータ表示テスト開始 ===');

      // テスト環境を初期化
      await TestEnvSetup.initializeTestEnvironment(
        throwOnValidationError: false,
        enableDebugLogging: true,
      );

      print('環境設定:');
      print('  - テスト環境初期化完了');

      // DIコンテナーを作成・設定
      container = AppDIContainer();
      container.configure();

      // StoreProviderを取得
      storeProvider = container.getStoreProvider();
    });

    test('修正後のStoreProvider動作確認', () async {
      print('=== 修正後のStoreProvider動作確認 ===');

      try {
        // 店舗データ読み込み（新しいロジックでAPIから取得）
        print('店舗データを読み込み中...');
        await storeProvider.loadStores();

        print('StoreProvider状態:');
        print('  - ローディング中: ${storeProvider.isLoading}');
        print('  - エラー有無: ${storeProvider.error != null}');
        print('  - 全店舗数: ${storeProvider.stores.length}');
        print('  - 新店舗数: ${storeProvider.newStores.length}');

        if (storeProvider.error != null) {
          print('  - エラー内容: ${storeProvider.error}');
        }

        // 実際のAPIデータかどうかを確認
        if (storeProvider.stores.isNotEmpty) {
          print('  - 取得した店舗データ（最初の5件）:');
          for (int i = 0; i < storeProvider.stores.length && i < 5; i++) {
            final store = storeProvider.stores[i];
            print('    ${i + 1}. ID: ${store.id}');
            print('       名前: ${store.name}');
            print('       住所: ${store.address}');
            print('       座標: (${store.lat}, ${store.lng})');
            print('       ステータス: ${store.status}');

            // APIデータの特徴を確認
            if (store.id.startsWith('J')) {
              print('       → HotPepper APIデータ（IDがJで始まる）✅');
            } else {
              print('       → ローカルデータまたは手動データ');
            }
            print('');
          }

          // APIデータの割合を確認
          final apiStoreCount = storeProvider.stores
              .where((store) => store.id.startsWith('J'))
              .length;
          print(
              '  - APIデータ店舗数: $apiStoreCount / ${storeProvider.stores.length}');

          if (apiStoreCount > 0) {
            print('✅ APIから取得したデータが正常に表示されています');
          } else {
            print('⚠️  APIデータが見つかりません。ダミーデータが使用されている可能性があります');
          }
        }

        // 基本検証
        expect(storeProvider.isLoading, isFalse);
        expect(storeProvider.stores, isNotNull);
        expect(storeProvider.stores.length, greaterThan(0));
      } catch (e, stackTrace) {
        print('❌ 予期しないエラー: $e');
        print('スタックトレース: $stackTrace');
        rethrow;
      }
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('新しい店舗検索テスト', () async {
      print('=== 新しい店舗検索テスト ===');

      try {
        final initialCount = storeProvider.stores.length;
        print('検索前の店舗数: $initialCount');

        // 渋谷駅周辺で新しい店舗を検索
        await storeProvider.loadNewStoresFromApi(
          lat: 35.6581, // 渋谷駅の座標
          lng: 139.7414,
          keyword: '中華',
          count: 5,
        );

        final finalCount = storeProvider.stores.length;
        final addedCount = finalCount - initialCount;

        print('検索後の店舗数: $finalCount');
        print('追加された店舗数: $addedCount');

        if (addedCount > 0) {
          print('✅ 新しい店舗の検索・追加が成功しました');

          // 最後に追加された店舗を確認
          final lastStores = storeProvider.stores.sublist(initialCount);
          print('新しく追加された店舗:');
          for (int i = 0; i < lastStores.length && i < 3; i++) {
            final store = lastStores[i];
            print('  ${i + 1}. ${store.name} (${store.address})');
          }
        } else {
          print('⚠️  新しい店舗は追加されませんでした（重複または検索結果なし）');
        }

        expect(storeProvider.stores.length, greaterThanOrEqualTo(initialCount));
      } catch (e) {
        print('❌ 新しい店舗検索エラー: $e');
        rethrow;
      }
    }, timeout: const Timeout(Duration(seconds: 30)));

    tearDownAll(() {
      print('=== テスト終了 ===');
      container.dispose();
      TestEnvSetup.cleanupTestEnvironment();
    });
  });
}
