// Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Package imports
import 'package:provider/provider.dart';

// Local imports
import 'package:chinese_food_app/domain/entities/location.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/presentation/providers/store_provider.dart';

// Test imports
import 'fakes.dart';

/// 統一されたテストヘルパークラス
///
/// テスト間での重複コードを削減し、一貫したテストセットアップを提供する。
class TestHelpers {
  /// StoreProviderのインスタンスを作成（テスト用）
  static StoreProvider createStoreProvider() {
    return StoreProvider(
      repository: FakeStoreRepository(),
    );
  }

  /// ウィジェットテスト用のMaterialApp + Provider構成を作成
  ///
  /// 使用例：
  /// ```dart
  /// testWidgets('should display widget', (tester) async {
  ///   await tester.pumpWidget(
  ///     TestHelpers.createTestWidget(
  ///       child: MyWidget(),
  ///       locationService: FakeLocationService()..setCurrentLocation(testLocation),
  ///     ),
  ///   );
  ///
  ///   expect(find.text('Test Location'), findsOneWidget);
  /// });
  /// ```
  static Widget createTestWidget({
    Widget? child,
    FakeLocationService? locationService,
    FakeStoreRepository? storeRepository,
    FakeLocationRepository? locationRepository,
  }) {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          if (locationService != null) Provider.value(value: locationService),
          if (storeRepository != null) Provider.value(value: storeRepository),
          if (locationRepository != null)
            Provider.value(value: locationRepository),
        ],
        child: Scaffold(
          body: child ?? Container(),
        ),
      ),
    );
  }

  /// Providerテスト用のシンプルなウィジェット作成
  static Widget createProviderTestWidget<T>({
    required T provider,
    Widget? child,
  }) {
    return MaterialApp(
      home: Provider<T>.value(
        value: provider,
        child: Scaffold(
          body: child ?? Container(),
        ),
      ),
    );
  }

  /// 複数のプロバイダーを組み合わせたウィジェット作成
  static Widget createMultiProviderTestWidget({
    required List<Provider> providers,
    Widget? child,
  }) {
    return MaterialApp(
      home: MultiProvider(
        providers: providers,
        child: Scaffold(
          body: child ?? Container(),
        ),
      ),
    );
  }
}

/// テストデータビルダークラス
///
/// 一貫したテストデータを簡単に作成するためのヘルパー。
class TestDataBuilders {
  /// デフォルトのテスト用Location作成
  static Location createTestLocation({
    double latitude = 35.6762,
    double longitude = 139.6503,
    DateTime? timestamp,
    double accuracy = 10.0,
  }) {
    return Location(
      latitude: latitude,
      longitude: longitude,
      timestamp: timestamp ?? DateTime.now(),
      accuracy: accuracy,
    );
  }

  /// デフォルトのテスト用Store作成
  static Store createTestStore({
    String? id,
    String name = 'テスト中華料理店',
    String address = '東京都渋谷区テスト1-1-1',
    double lat = 35.6762,
    double lng = 139.6503,
    StoreStatus status = StoreStatus.wantToGo,
    String memo = '',
    DateTime? createdAt,
  }) {
    return Store(
      id: id ?? 'test_store_1',
      name: name,
      address: address,
      lat: lat,
      lng: lng,
      status: status,
      memo: memo,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  /// 複数のテスト用Store作成
  static List<Store> createTestStores(int count, {StoreStatus? status}) {
    return List.generate(count, (index) {
      return createTestStore(
        id: 'test_store_${index + 1}',
        name: 'テスト中華料理店 ${index + 1}',
        address: '東京都渋谷区テスト${index + 1}-1-1',
        lat: 35.6762 + (index * 0.001),
        lng: 139.6503 + (index * 0.001),
        status: status ?? StoreStatus.wantToGo,
      );
    });
  }
}

/// テスト実行時のヘルパーメソッド
class TestUtilities {
  /// ウィジェットの存在を確認し、タップする
  static Future<void> tapWidget(WidgetTester tester, Finder finder) async {
    expect(finder, findsOneWidget);
    await tester.tap(finder);
    await tester.pump();
  }

  /// ウィジェットの存在を確認し、テキストを入力する
  static Future<void> enterText(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    expect(finder, findsOneWidget);
    await tester.enterText(finder, text);
    await tester.pump();
  }

  /// ウィジェットのアニメーション完了を待つ
  static Future<void> pumpAndSettle(WidgetTester tester) async {
    await tester.pumpAndSettle();
  }

  /// 指定時間のアニメーションを進める
  static Future<void> pumpWithDuration(
    WidgetTester tester,
    Duration duration,
  ) async {
    await tester.pump(duration);
  }

  /// スクロール可能なウィジェットをスクロールする
  static Future<void> scrollWidget(
    WidgetTester tester,
    Finder finder,
    Offset offset,
  ) async {
    await tester.drag(finder, offset);
    await tester.pump();
  }
}

/// テストアサーション用のカスタムマッチャー
class CustomMatchers {
  /// Locationが期待される範囲内にあるかチェック
  static Matcher isLocationNear(
    Location expected, {
    double tolerance = 0.001,
  }) {
    return predicate<Location>(
      (actual) =>
          (actual.latitude - expected.latitude).abs() < tolerance &&
          (actual.longitude - expected.longitude).abs() < tolerance,
      'is near location $expected with tolerance $tolerance',
    );
  }

  /// Storeのプロパティをチェック
  static Matcher hasStoreProperties({
    String? name,
    String? address,
    StoreStatus? status,
  }) {
    return predicate<Store>(
      (actual) =>
          (name == null || actual.name == name) &&
          (address == null || actual.address == address) &&
          (status == null || actual.status == status),
      'has store properties: name=$name, address=$address, status=$status',
    );
  }
}

/// テスト環境のセットアップとクリーンアップ
class TestEnvironment {
  /// テスト前のセットアップ
  static void setUp() {
    // 必要に応じてテスト前の共通処理を実装
  }

  /// テスト後のクリーンアップ
  static void tearDown() {
    // 必要に応じてテスト後の共通処理を実装
  }

  /// 非同期テストの共通セットアップ
  static Future<void> setUpAsync() async {
    // 非同期処理が必要な場合のセットアップ
  }

  /// 非同期テストの共通クリーンアップ
  static Future<void> tearDownAsync() async {
    // 非同期処理が必要な場合のクリーンアップ
  }
}

/// TestsHelper は TestHelpers と TestDataBuilders に統合されました。
/// 後方互換性のためのエイリアス（将来削除予定）
@Deprecated(
    'Use TestHelpers.createStoreProvider() and TestDataBuilders.createTestStore() instead')
class TestsHelper {
  /// StoreProviderのインスタンスを作成（テスト用）
  /// 代わりに TestHelpers.createStoreProvider() を使用してください
  static StoreProvider createStoreProvider() {
    return TestHelpers.createStoreProvider();
  }

  /// テスト用のStoreを作成
  /// 代わりに TestDataBuilders.createTestStore() を使用してください
  static Store createTestStore({
    String? id,
    String? name,
    String? address,
    double lat = 35.6812,
    double lng = 139.7671,
    StoreStatus? status,
    String? memo,
  }) {
    return TestDataBuilders.createTestStore(
      id: id,
      name: name ?? 'Test Store',
      address: address ?? 'Test Address',
      lat: lat,
      lng: lng,
      status: status ?? StoreStatus.wantToGo,
      memo: memo ?? '',
    );
  }
}
