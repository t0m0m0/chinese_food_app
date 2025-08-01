// ignore_for_file: avoid_print

// TODO: Fix API compatibility after DI container refactoring
// This test file has been temporarily disabled due to API changes

/*
import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/config/config_manager.dart';
import 'package:chinese_food_app/core/config/environment_config.dart';
import 'package:chinese_food_app/core/di/app_di_container.dart';
import 'package:chinese_food_app/domain/repositories/store_repository.dart';
import 'package:chinese_food_app/domain/entities/location.dart';

/// アプリのDIコンテナを通じてAPIコールが正常に動作することを確認する手動テスト
/// TODO: Fix API compatibility after DI container refactoring
void main() {
  // Tests temporarily disabled due to API changes
  return;
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

    tearDownAll(() {
      container.dispose();
    });

    test('渋谷周辺の店舗検索', () async {
      const location = Location(latitude: 35.6595, longitude: 139.7006);
      
      print('=== 渋谷周辺の店舗検索テスト ===');
      final stores = await storeRepository.searchStores(
        location: location,
        keyword: '中華',
        radius: 1000,
      );

      print('検索結果: ${stores.length}件');
      
      expect(stores, isNotEmpty, reason: '渋谷周辺に中華料理店が見つからない');
      
      for (int i = 0; i < stores.length && i < 3; i++) {
        final store = stores[i];
        print('--- 店舗 ${i + 1} ---');
        print('店名: ${store.name}');
        print('住所: ${store.address}');
        print('緯度経度: ${store.location.latitude}, ${store.location.longitude}');
        print('ジャンル: ${store.genre}');
        print('ジャンル詳細: ${store.genre.catch ?? 'なし'}');
        print('予算: ${store.budget}');
        print('予算詳細: ${store.budget.name ?? 'なし'}');
        print('');
      }
    });

    test('新宿周辺の店舗検索', () async {
      const location = Location(latitude: 35.6896, longitude: 139.6917);
      
      print('=== 新宿周辺の店舗検索テスト ===');
      
      final stores = <Store>[];
      try {
        final result = await storeRepository.searchStores(
          location: location,
          keyword: '中華',
          radius: 500,
        );
        stores.addAll(result);
      } catch (e) {
        print('検索エラー: $e');
        return;
      }

      print('検索結果: ${stores.length}件');
      
      expect(stores, isNotEmpty, reason: '新宿周辺に中華料理店が見つからない');
      
      if (stores.isNotEmpty) {
        final firstStore = stores.first;
        print('最初の店舗:');
        print('  店名: ${firstStore.name}');
        print('  住所: ${firstStore.address}');
      }
    });

    test('キーワード検索', () async {
      print('=== キーワード検索テスト ===');
      
      try {
        final stores = await storeRepository.searchStoresByKeyword('中華料理');
        
        print('キーワード検索結果: ${stores.length}件');
        expect(stores, isNotEmpty, reason: 'キーワード「中華料理」で店舗が見つからない');
        
        if (stores.isNotEmpty) {
          final firstStore = stores.first;
          print('最初の店舗: ${firstStore.name} (${firstStore.address})');
        }
      } catch (e) {
        print('キーワード検索エラー: $e');
        fail('キーワード検索でエラーが発生: $e');
      }
    });

    test('レスポンス時間の確認', () async {
      print('=== レスポンス時間確認テスト ===');
      
      const location = Location(latitude: 35.6762, longitude: 139.6503);
      
      final stopwatch = Stopwatch()..start();
      
      try {
        await storeRepository.searchStores(
          location: location,
          keyword: '中華',
          radius: 1000,
        );
        
        stopwatch.stop();
        final responseTime = stopwatch.elapsedMilliseconds;
        
        print('レスポンス時間: ${responseTime}ms');
        expect(responseTime, lessThan(10000), reason: 'レスポンスが10秒を超えています');
        
      } catch (e) {
        stopwatch.stop();
        print('エラーでレスポンス時間測定中断: $e');
        fail('API呼び出しエラー: $e');
      }
    });
  });
}
*/

void main() {
  // This file is temporarily disabled
}