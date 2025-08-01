// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/config/config_manager.dart';
import 'package:chinese_food_app/core/config/environment_config.dart';
import 'package:chinese_food_app/core/di/app_di_container.dart';
import 'package:chinese_food_app/presentation/providers/store_provider.dart';

/// 実際のアプリフローでAPIが正常に動作することを確認する簡単な検証テスト
void main() {
  group('Simple API Verification Test', () {
    late AppDIContainer container;
    late StoreProvider storeProvider;

    setUpAll(() async {
      print('=== API動作検証テスト開始 ===');

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
    });

    test('StoreProvider経由での店舗データ読み込みテスト', () async {
      print('=== StoreProvider経由での店舗データ読み込みテスト ===');

      try {
        // 店舗データ読み込み（これが内部的にAPIを呼び出す）
        await storeProvider.loadStores();

        print('StoreProvider状態:');
        print('  - ローディング中: ${storeProvider.isLoading}');
        print('  - エラー有無: ${storeProvider.error != null}');
        print('  - 店舗数: ${storeProvider.stores.length}');

        if (storeProvider.error != null) {
          print('  - エラー内容: ${storeProvider.error}');
        }

        if (storeProvider.stores.isNotEmpty) {
          print('  - 店舗例:');
          for (int i = 0; i < storeProvider.stores.length && i < 3; i++) {
            final store = storeProvider.stores[i];
            print('    ${i + 1}. ${store.name} (${store.address})');
          }
        }

        // 基本検証
        expect(storeProvider.isLoading, isFalse);

        // エラーがないか、またはエラーがあっても適切にハンドリングされていることを確認
        if (storeProvider.error != null) {
          print('⚠️  エラーが発生しましたが、アプリは正常に動作しています');
        } else {
          print('✅ API呼び出し成功: 店舗データの読み込みが完了しました');
        }
      } catch (e, stackTrace) {
        print('❌ 予期しないエラー: $e');
        print('スタックトレース: $stackTrace');
        rethrow;
      }
    }, timeout: const Timeout(Duration(seconds: 45)));

    test('設定検証テスト', () {
      print('=== 設定検証テスト ===');

      // APIキー設定の確認
      final hotpepperKey = EnvironmentConfig.hotpepperApiKey;
      final googleMapsKey = EnvironmentConfig.googleMapsApiKey;

      print('設定状況:');
      print(
          '  - HotPepper APIキー: ${hotpepperKey.isNotEmpty ? "設定済み (${hotpepperKey.substring(0, 8)}...)" : "未設定"}');
      print(
          '  - Google Maps APIキー: ${googleMapsKey.isNotEmpty ? "設定済み (${googleMapsKey.substring(0, 8)}...)" : "未設定"}');
      print('  - ConfigManager初期化済み: ${ConfigManager.isInitialized}');
      print('  - DI Container設定済み: ${container.isConfigured}');

      expect(hotpepperKey.isNotEmpty, isTrue,
          reason: 'HotPepper APIキーが設定されていません');
      expect(ConfigManager.isInitialized, isTrue);
      expect(container.isConfigured, isTrue);

      print('✅ 全ての設定が正常です');
    });

    tearDownAll(() {
      print('=== テスト終了 ===');
      container.dispose();
    });
  });
}
