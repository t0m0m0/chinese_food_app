import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/core/security/logging/secure_logger.dart';
import '../helpers/test_env_setup.dart';

/// シンプルなモック化されたAPIデータテスト
///
/// 実際のAPI呼び出しではなく、モックデータを使用して
/// データ構造と処理ロジックのテストを行います。
void main() {
  group('Fresh API Data Test (Simple Mock)', () {
    setUpAll(() async {
      SecureLogger.info('=== シンプルモック化APIデータテスト開始 ===', name: 'FreshApiDataTest');

      // テスト環境を初期化
      await TestEnvSetup.initializeTestEnvironment(
        throwOnValidationError: false,
        enableDebugLogging: false,
      );
    });

    test('モックAPIデータの構造確認', () async {
      SecureLogger.info('=== モックAPIデータ構造テスト ===', name: 'FreshApiDataTest');

      // モックデータを作成（実際のHotPepper APIレスポンスを模擬）
      final mockStores = _createMockStores();

      SecureLogger.info('取得されたモック店舗数: ${mockStores.length}', name: 'FreshApiDataTest');

      // 基本検証
      expect(mockStores.length, greaterThan(0));
      expect(mockStores.length, equals(3));

      // APIデータの確認（HotPepper IDがJで始まる）
      final hotpepperStores =
          mockStores.where((store) => store.id.startsWith('J')).toList();
      expect(hotpepperStores.length, equals(3));

      SecureLogger.info('✅ テスト成功: ${hotpepperStores.length}件のモックAPIデータを検証しました', name: 'FreshApiDataTest');

      // 店舗詳細の確認
      for (final store in hotpepperStores) {
        SecureLogger.info('  - ${store.name} (ID: ${store.id})', name: 'FreshApiDataTest');
        SecureLogger.info('    住所: ${store.address}', name: 'FreshApiDataTest');
        SecureLogger.info('    座標: ${store.lat}, ${store.lng}', name: 'FreshApiDataTest');

        // データ整合性チェック
        expect(store.name, isNotEmpty);
        expect(store.address, isNotEmpty);
        expect(store.lat, isNotNull);
        expect(store.lng, isNotNull);
        expect(store.id, startsWith('J'));
        expect(store.status, equals(StoreStatus.wantToGo));
      }
    });

    test('複数地点のモックデータ統合テスト', () async {
      SecureLogger.info('=== 複数地点モックデータ統合テスト ===', name: 'FreshApiDataTest');

      // 新宿エリアのモックデータ
      final shinjukuStores = _createShinjukuMockStores();

      // 渋谷エリアのモックデータ
      final shibuyaStores = _createShibuyaMockStores();

      // 池袋エリアのモックデータ
      final ikebukuroStores = _createIkebukuroMockStores();

      // 全エリアのデータを統合
      final allStores = [
        ...shinjukuStores,
        ...shibuyaStores,
        ...ikebukuroStores,
      ];

      SecureLogger.info('最終店舗数: ${allStores.length}', name: 'FreshApiDataTest');
      SecureLogger.info('地域別分布:', name: 'FreshApiDataTest');
      SecureLogger.info('  - 新宿エリア: ${shinjukuStores.length}件', name: 'FreshApiDataTest');
      SecureLogger.info('  - 渋谷エリア: ${shibuyaStores.length}件', name: 'FreshApiDataTest');
      SecureLogger.info('  - 池袋エリア: ${ikebukuroStores.length}件', name: 'FreshApiDataTest');

      // 検証
      expect(shinjukuStores.length, equals(2));
      expect(shibuyaStores.length, equals(1));
      expect(ikebukuroStores.length, equals(1));
      expect(allStores.length, equals(4));

      // 地域別の店舗が正しく作成されていることを確認
      expect(shinjukuStores.every((s) => s.address.contains('新宿')), isTrue);
      expect(shibuyaStores.every((s) => s.address.contains('渋谷')), isTrue);
      expect(ikebukuroStores.every((s) => s.address.contains('池袋')), isTrue);

      // 座標の妥当性確認（東京都内の範囲）
      for (final store in allStores) {
        expect(store.lat, inInclusiveRange(35.5, 35.8)); // 東京都の緯度範囲
        expect(store.lng, inInclusiveRange(139.5, 139.9)); // 東京都の経度範囲
      }

      SecureLogger.info('✅ 複数地点からのモックデータ統合が成功しました', name: 'FreshApiDataTest');
    });

    test('APIデータのフィルタリングと検索機能テスト', () async {
      SecureLogger.info('=== APIデータフィルタリングテスト ===', name: 'FreshApiDataTest');

      final mockStores = _createMockStores();

      // キーワード検索のシミュレーション
      final chineseStores = mockStores
          .where((store) =>
              store.name.contains('中華') ||
              store.name.contains('ラーメン') ||
              store.name.contains('餃子'))
          .toList();

      SecureLogger.info('中華料理店の検索結果: ${chineseStores.length}件', name: 'FreshApiDataTest');

      // 距離によるフィルタリングのシミュレーション（新宿駅周辺）
      const shinjukuLat = 35.6917;
      const shinjukuLng = 139.7006;
      const searchRadius = 0.01; // 約1km

      final nearbyStores = mockStores.where((store) {
        final latDiff = (store.lat - shinjukuLat).abs();
        final lngDiff = (store.lng - shinjukuLng).abs();
        return latDiff <= searchRadius && lngDiff <= searchRadius;
      }).toList();

      SecureLogger.info('新宿駅周辺の店舗: ${nearbyStores.length}件', name: 'FreshApiDataTest');

      // 検証
      expect(chineseStores.length, greaterThan(0));
      expect(nearbyStores.length, greaterThan(0));

      // フィルタリング結果の妥当性確認
      for (final store in chineseStores) {
        final hasChinese = store.name.contains('中華') ||
            store.name.contains('ラーメン') ||
            store.name.contains('餃子');
        expect(hasChinese, isTrue);
      }

      SecureLogger.info('✅ APIデータのフィルタリング機能が正常に動作しました', name: 'FreshApiDataTest');
    });

    tearDownAll(() {
      SecureLogger.info('=== テスト終了 ===', name: 'FreshApiDataTest');
      TestEnvSetup.cleanupTestEnvironment();
    });
  });
}

/// 基本的なモックストアデータを作成
List<Store> _createMockStores() {
  return [
    Store(
      id: 'J000123456',
      name: '新宿中華料理店',
      address: '東京都新宿区新宿1-1-1',
      lat: 35.6917,
      lng: 139.7006,
      imageUrl: 'https://example.com/image1.jpg',
      status: StoreStatus.wantToGo,
      memo: '',
      createdAt: DateTime.now(),
    ),
    Store(
      id: 'J000123457',
      name: '本格四川ラーメン店',
      address: '東京都新宿区新宿2-2-2',
      lat: 35.6920,
      lng: 139.7010,
      imageUrl: 'https://example.com/image2.jpg',
      status: StoreStatus.wantToGo,
      memo: '',
      createdAt: DateTime.now(),
    ),
    Store(
      id: 'J000123458',
      name: '手作り餃子専門店',
      address: '東京都新宿区新宿3-3-3',
      lat: 35.6925,
      lng: 139.7015,
      imageUrl: 'https://example.com/image3.jpg',
      status: StoreStatus.wantToGo,
      memo: '',
      createdAt: DateTime.now(),
    ),
  ];
}

/// 新宿エリアのモックストアデータを作成
List<Store> _createShinjukuMockStores() {
  return [
    Store(
      id: 'J000200001',
      name: '新宿東口中華飯店',
      address: '東京都新宿区新宿3-1-1',
      lat: 35.6917,
      lng: 139.7006,
      imageUrl: 'https://example.com/shinjuku1.jpg',
      status: StoreStatus.wantToGo,
      memo: '',
      createdAt: DateTime.now(),
    ),
    Store(
      id: 'J000200002',
      name: '新宿南口麺館',
      address: '東京都新宿区新宿4-1-1',
      lat: 35.6895,
      lng: 139.7003,
      imageUrl: 'https://example.com/shinjuku2.jpg',
      status: StoreStatus.wantToGo,
      memo: '',
      createdAt: DateTime.now(),
    ),
  ];
}

/// 渋谷エリアのモックストアデータを作成
List<Store> _createShibuyaMockStores() {
  return [
    Store(
      id: 'J000300001',
      name: '渋谷中華楼',
      address: '東京都渋谷区渋谷1-1-1',
      lat: 35.6598,
      lng: 139.7007,
      imageUrl: 'https://example.com/shibuya1.jpg',
      status: StoreStatus.wantToGo,
      memo: '',
      createdAt: DateTime.now(),
    ),
  ];
}

/// 池袋エリアのモックストアデータを作成
List<Store> _createIkebukuroMockStores() {
  return [
    Store(
      id: 'J000400001',
      name: '池袋中華麺房',
      address: '東京都豊島区南池袋1-1-1',
      lat: 35.7295,
      lng: 139.7109,
      imageUrl: 'https://example.com/ikebukuro1.jpg',
      status: StoreStatus.wantToGo,
      memo: '',
      createdAt: DateTime.now(),
    ),
  ];
}
