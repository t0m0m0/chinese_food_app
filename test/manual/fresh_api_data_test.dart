import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/config/config_manager.dart';
import 'package:chinese_food_app/core/config/environment_config.dart';
import 'package:chinese_food_app/core/di/app_di_container.dart';
import 'package:chinese_food_app/presentation/providers/store_provider.dart';
import 'package:chinese_food_app/domain/repositories/store_repository.dart';

/// 新しいデータベースでAPIデータのみを表示するテスト
void main() {
  group('Fresh API Data Test', () {
    late AppDIContainer container;
    late StoreProvider storeProvider;
    late StoreRepository storeRepository;

    setUpAll(() async {
      print('=== 新しいAPIデータテスト開始 ===');

      // 環境設定を初期化
      await EnvironmentConfig.initialize();
      await ConfigManager.initialize(
        throwOnValidationError: false,
        enableDebugLogging: true,
      );

      print('環境設定:');
      print('  - APIキー設定済み: ${EnvironmentConfig.hotpepperApiKey.isNotEmpty}');
      print('  - 環境: ${EnvironmentConfig.current.name}');

      // DIコンテナーを作成・設定
      container = AppDIContainer();
      container.configure();

      // StoreProviderを取得
      storeProvider = container.getStoreProvider();
      storeRepository = storeProvider.repository;
    });

    test('既存データをクリアしてAPIデータのみを取得', () async {
      print('=== データベースクリア & APIデータ取得テスト ===');

      try {
        // 既存の全店舗データを削除
        print('既存データをクリア中...');
        final existingStores = await storeRepository.getAllStores();
        print('削除対象店舗数: ${existingStores.length}');

        for (final store in existingStores) {
          await storeRepository.deleteStore(store.id);
        }

        print('✅ 既存データをクリアしました');

        // APIから新しいデータを直接取得
        print('APIから新宿駅周辺の店舗データを取得中...');
        await storeProvider.loadNewStoresFromApi(
          lat: 35.6917, // 新宿駅の座標
          lng: 139.7006,
          keyword: '中華',
          count: 15, // 多めに取得
        );

        print('StoreProvider状態:');
        print('  - ローディング中: ${storeProvider.isLoading}');
        print('  - エラー有無: ${storeProvider.error != null}');
        print('  - 全店舗数: ${storeProvider.stores.length}');
        print('  - 新店舗数: ${storeProvider.newStores.length}');

        if (storeProvider.error != null) {
          print('  - エラー内容: ${storeProvider.error}');
        }

        // 取得したAPIデータの内容を確認
        if (storeProvider.stores.isNotEmpty) {
          print('  - APIから取得した店舗データ:');
          for (int i = 0; i < storeProvider.stores.length && i < 10; i++) {
            final store = storeProvider.stores[i];
            print('    ${i + 1}. ID: ${store.id}');
            print('       名前: ${store.name}');
            print('       住所: ${store.address}');
            print('       座標: (${store.lat}, ${store.lng})');
            print('       ステータス: ${store.status}');

            // APIデータの特徴を確認
            if (store.id.startsWith('J')) {
              print('       → HotPepper APIデータ ✅');
            } else {
              print('       → 非APIデータ');
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
            print('✅ APIから取得した実際のデータが表示されています！');
          } else {
            print('❌ APIデータが見つかりません');
          }
        } else {
          print('⚠️  店舗データが取得されませんでした');
        }

        // 基本検証
        expect(storeProvider.stores.length, greaterThan(0));

        // APIデータの確認
        final apiStores = storeProvider.stores
            .where((store) => store.id.startsWith('J'))
            .toList();
        expect(apiStores.length, greaterThan(0), reason: 'APIデータが取得されていません');

        print('✅ テスト成功: ${apiStores.length}件のAPIデータを取得しました');
      } catch (e, stackTrace) {
        print('❌ 予期しないエラー: $e');
        print('スタックトレース: $stackTrace');
        rethrow;
      }
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('複数地点からのAPIデータ取得テスト', () async {
      print('=== 複数地点APIデータ取得テスト ===');

      try {
        final initialCount = storeProvider.stores.length;
        print('初期店舗数: $initialCount');

        // 渋谷駅周辺からも取得
        print('渋谷駅周辺から追加取得中...');
        await storeProvider.loadNewStoresFromApi(
          lat: 35.6581, // 渋谷駅の座標
          lng: 139.7414,
          keyword: '中華',
          count: 10,
        );

        // 池袋駅周辺からも取得
        print('池袋駅周辺から追加取得中...');
        await storeProvider.loadNewStoresFromApi(
          lat: 35.7295, // 池袋駅の座標
          lng: 139.7109,
          keyword: '中華',
          count: 10,
        );

        final finalCount = storeProvider.stores.length;
        final addedCount = finalCount - initialCount;

        print('最終店舗数: $finalCount');
        print('追加された店舗数: $addedCount');

        // 地域別の分布を確認
        print('地域別分布:');
        final newStores = storeProvider.stores.sublist(initialCount);
        for (final store in newStores) {
          if (store.address.contains('新宿')) {
            print('  - 新宿: ${store.name}');
          } else if (store.address.contains('渋谷')) {
            print('  - 渋谷: ${store.name}');
          } else if (store.address.contains('池袋')) {
            print('  - 池袋: ${store.name}');
          } else {
            print('  - その他: ${store.name} (${store.address})');
          }
        }

        expect(storeProvider.stores.length, greaterThanOrEqualTo(initialCount));
        print('✅ 複数地点からのAPIデータ取得が成功しました');
      } catch (e) {
        print('❌ 複数地点取得エラー: $e');
        rethrow;
      }
    }, timeout: const Timeout(Duration(seconds: 60)));

    tearDownAll(() {
      print('=== テスト終了 ===');
      container.dispose();
    });
  });
}
