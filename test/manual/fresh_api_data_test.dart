// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:chinese_food_app/domain/repositories/store_repository.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import '../helpers/test_env_setup.dart';

// モッククラス
class MockStoreRepository extends Mock implements StoreRepository {}

/// モック化されたAPIデータテスト
void main() {
  group('Fresh API Data Test (Mocked)', () {
    late MockStoreRepository mockRepository;

    setUpAll(() async {
      print('=== モック化APIデータテスト開始 ===');

      // テスト環境を初期化
      await TestEnvSetup.initializeTestEnvironment(
        throwOnValidationError: false,
        enableDebugLogging: false,
      );
    });

    setUp(() {
      // 各テストで新しいモックを作成
      mockRepository = MockStoreRepository();
    });

    test('既存データをクリアしてモックAPIデータを取得', () async {
      print('=== データベースクリア & モックAPIデータ取得テスト ===');

      // モックデータを定義
      final mockStores = [
        Store(
          id: 'J000123456',
          name: 'テスト中華料理店1',
          address: '東京都新宿区テスト1-1-1',
          lat: 35.6917,
          lng: 139.7006,
          imageUrl: 'https://example.com/image1.jpg',
          status: StoreStatus.wantToGo,
          memo: '',
          createdAt: DateTime.now(),
        ),
        Store(
          id: 'J000123457',
          name: 'テスト中華料理店2',
          address: '東京都新宿区テスト2-2-2',
          lat: 35.6920,
          lng: 139.7010,
          imageUrl: 'https://example.com/image2.jpg',
          status: StoreStatus.wantToGo,
          memo: '',
          createdAt: DateTime.now(),
        ),
      ];

      // モックの動作を設定
      when(mockRepository.getAllStores()).thenAnswer((_) async => <Store>[]);
      when(mockRepository.searchStoresFromApi(
        lat: 35.6917,
        lng: 139.7006,
        keyword: '中華',
        count: 10,
      )).thenAnswer((_) async => mockStores);

      print('既存データをクリア中...');
      final existingStores = await mockRepository.getAllStores();
      print('削除対象店舗数: ${existingStores.length}');

      print('✅ 既存データをクリアしました');

      print('モックAPIから新宿駅周辺の店舗データを取得中...');
      final apiStores = await mockRepository.searchStoresFromApi(
        lat: 35.6917,
        lng: 139.7006,
        keyword: '中華',
        count: 10,
      );

      print('取得されたモック店舗数: ${apiStores.length}');

      // 検証
      expect(apiStores.length, greaterThan(0));
      expect(apiStores.length, equals(2));
      
      // APIデータの確認（HotPepper IDがJで始まる）
      final hotpepperStores = apiStores
          .where((store) => store.id.startsWith('J'))
          .toList();
      expect(hotpepperStores.length, equals(2));

      print('✅ テスト成功: ${hotpepperStores.length}件のモックAPIデータを取得しました');

      // 店舗詳細の確認
      for (final store in hotpepperStores) {
        print('  - ${store.name} (ID: ${store.id})');
        print('    住所: ${store.address}');
        print('    座標: ${store.lat}, ${store.lng}');
        expect(store.name, isNotEmpty);
        expect(store.address, isNotEmpty);
        expect(store.lat, isNotNull);
        expect(store.lng, isNotNull);
      }
    });

    test('複数地点からのモックAPIデータ取得テスト', () async {
      print('=== 複数地点モックAPIデータ取得テスト ===');

      // 渋谷エリアのモックデータ
      final shibuyaStores = [
        Store(
          id: 'J000234567',
          name: '渋谷中華飯店',
          address: '東京都渋谷区渋谷1-1-1',
          lat: 35.6598,
          lng: 139.7006,
          imageUrl: 'https://example.com/shibuya1.jpg',
          status: StoreStatus.wantToGo,
          memo: '',
          createdAt: DateTime.now(),
        ),
      ];

      // 池袋エリアのモックデータ
      final ikebukuroStores = [
        Store(
          id: 'J000345678',
          name: '池袋中華楼',
          address: '東京都豊島区南池袋1-1-1',
          lat: 35.7295,
          lng: 139.7109,
          imageUrl: 'https://example.com/ikebukuro1.jpg',
          status: StoreStatus.wantToGo,
          memo: '',
          createdAt: DateTime.now(),
        ),
      ];

      // 地域別モック設定
      when(mockRepository.searchStoresFromApi(
        lat: 35.6598, // 渋谷
        lng: 139.7006,
        keyword: '中華',
        count: 10,
      )).thenAnswer((_) async => shibuyaStores);

      when(mockRepository.searchStoresFromApi(
        lat: 35.7295, // 池袋
        lng: 139.7109,
        keyword: '中華',
        count: 10,
      )).thenAnswer((_) async => ikebukuroStores);

      print('渋谷駅周辺からモックデータ取得中...');
      final shibuyaResults = await mockRepository.searchStoresFromApi(
        lat: 35.6598,
        lng: 139.7006,
        keyword: '中華',
        count: 10,
      );

      print('池袋駅周辺からモックデータ取得中...');
      final ikebukuroResults = await mockRepository.searchStoresFromApi(
        lat: 35.7295,
        lng: 139.7109,
        keyword: '中華',
        count: 10,
      );

      final totalStores = [...shibuyaResults, ...ikebukuroResults];
      
      print('最終店舗数: ${totalStores.length}');
      print('地域別分布:');
      print('  - 渋谷エリア: ${shibuyaResults.length}件');
      print('  - 池袋エリア: ${ikebukuroResults.length}件');

      // 検証
      expect(shibuyaResults.length, equals(1));
      expect(ikebukuroResults.length, equals(1));
      expect(totalStores.length, equals(2));

      // 地域別の店舗が正しく取得されていることを確認
      expect(shibuyaResults.first.name, contains('渋谷'));
      expect(ikebukuroResults.first.name, contains('池袋'));

      print('✅ 複数地点からのモックAPIデータ取得が成功しました');
    });

    tearDownAll(() {
      print('=== テスト終了 ===');
      TestEnvSetup.cleanupTestEnvironment();
    });
  });
}