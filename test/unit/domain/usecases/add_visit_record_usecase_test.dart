import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/database/schema/app_database.dart';
import 'package:chinese_food_app/data/datasources/visit_record_local_datasource.dart';
import 'package:chinese_food_app/data/datasources/store_local_datasource.dart';
import 'package:chinese_food_app/data/repositories/visit_record_repository_impl.dart';
import 'package:chinese_food_app/data/repositories/store_repository_impl.dart';
import 'package:chinese_food_app/domain/usecases/add_visit_record_usecase.dart';
import 'package:chinese_food_app/domain/entities/store.dart' as entities;
import 'package:mockito/annotations.dart';
import 'package:chinese_food_app/data/datasources/hotpepper_proxy_datasource.dart'
    hide MockHotpepperProxyDatasource;
import '../../../helpers/test_database_factory.dart';

@GenerateMocks([HotpepperProxyDatasource])
import 'add_visit_record_usecase_test.mocks.dart';

void main() {
  late AppDatabase database;
  late VisitRecordLocalDatasourceImpl visitRecordDatasource;
  late StoreLocalDatasourceImpl storeDatasource;
  late VisitRecordRepositoryImpl visitRecordRepository;
  late StoreRepositoryImpl storeRepository;
  late MockHotpepperProxyDatasource mockApiDatasource;
  late AddVisitRecordUsecase usecase;

  setUp(() async {
    database = TestDatabaseFactory.createTestDatabase();
    visitRecordDatasource = VisitRecordLocalDatasourceImpl(database);
    storeDatasource = StoreLocalDatasourceImpl(database);
    visitRecordRepository = VisitRecordRepositoryImpl(visitRecordDatasource);
    mockApiDatasource = MockHotpepperProxyDatasource();
    storeRepository = StoreRepositoryImpl(
      apiDatasource: mockApiDatasource,
      localDatasource: storeDatasource,
    );
    usecase = AddVisitRecordUsecase(
      visitRecordRepository,
      storeRepository,
    );
  });

  tearDown(() async {
    await TestDatabaseFactory.disposeTestDatabase(database);
  });

  group('AddVisitRecordUsecase', () {
    test(
        'should successfully add visit record when store already exists in local DB',
        () async {
      // 🔴 Red: 店舗が既に存在する場合の正常系テスト
      // Arrange: 事前に店舗を保存
      final store = entities.Store(
        id: 'store_1',
        name: 'テスト中華料理店',
        address: '東京都渋谷区',
        lat: 35.6812362,
        lng: 139.7649361,
        imageUrl: 'https://example.com/image.jpg',
        status: entities.StoreStatus.wantToGo,
        memo: '',
        createdAt: DateTime.now(),
      );
      await storeDatasource.insertStore(store);

      // Act: 訪問記録を追加
      final visitedAt = DateTime.now();
      final result = await usecase.call(
        storeId: store.id,
        visitedAt: visitedAt,
        menu: 'チャーハン',
        memo: '美味しかった',
      );

      // Assert: 訪問記録が正常に作成されたことを確認
      expect(result.storeId, equals(store.id));
      expect(result.menu, equals('チャーハン'));
      expect(result.memo, equals('美味しかった'));
      expect(result.visitedAt, equals(visitedAt));

      // データベースに保存されたことを確認
      final saved = await visitRecordDatasource.getVisitRecordById(result.id);
      expect(saved, isNotNull);
      expect(saved!.storeId, equals(store.id));
    });

    test(
        'should fail to add visit record when store does not exist in local DB',
        () async {
      // 🔴 Red: 店舗が存在しない場合はForeign Key制約違反でエラーになることを確認
      // Arrange: 店舗を保存しない

      // Act & Assert: 訪問記録追加時にエラーが発生することを期待
      expect(
        () async => await usecase.call(
          storeId: 'non_existent_store',
          visitedAt: DateTime.now(),
          menu: 'チャーハン',
          memo: '美味しかった',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test(
        'should automatically save store before adding visit record when store does not exist',
        () async {
      // 🔴 Red: 店舗が存在しない場合、訪問記録を保存する前に店舗を自動保存する
      // Arrange: APIから取得した店舗データ（まだローカルDBに保存されていない）
      final store = entities.Store(
        id: 'store_from_api',
        name: 'APIから取得した店舗',
        address: '東京都新宿区',
        lat: 35.6895,
        lng: 139.6917,
        imageUrl: 'https://example.com/api_store.jpg',
        status: null, // APIから取得した店舗はステータスがnull
        memo: '',
        createdAt: DateTime.now(),
      );

      // 店舗がローカルDBに存在しないことを確認
      final existingStore = await storeDatasource.getStoreById(store.id);
      expect(existingStore, isNull);

      // Act: Storeオブジェクトを渡して訪問記録を追加
      final visitedAt = DateTime.now();
      final result = await usecase.call(
        store: store, // Storeオブジェクトを渡す（新しいパラメータ）
        storeId: store.id,
        visitedAt: visitedAt,
        menu: '麻婆豆腐',
        memo: '辛くて美味しい',
      );

      // Assert: 訪問記録が正常に作成されたことを確認
      expect(result.storeId, equals(store.id));
      expect(result.menu, equals('麻婆豆腐'));
      expect(result.memo, equals('辛くて美味しい'));

      // 店舗が自動的に保存されたことを確認
      final savedStore = await storeDatasource.getStoreById(store.id);
      expect(savedStore, isNotNull);
      expect(savedStore!.name, equals('APIから取得した店舗'));
      expect(savedStore.status, isNull); // ステータスはnullのまま

      // 訪問記録がデータベースに保存されたことを確認
      final savedVisit =
          await visitRecordDatasource.getVisitRecordById(result.id);
      expect(savedVisit, isNotNull);
      expect(savedVisit!.storeId, equals(store.id));
    });

    test('should work correctly when store parameter is null', () async {
      // 🔴 Red: storeパラメータがnullの場合でも正常に動作する（後方互換性）
      // Arrange: 事前に店舗を保存
      final store = entities.Store(
        id: 'store_2',
        name: 'テスト中華料理店2',
        address: '東京都目黒区',
        lat: 35.6436,
        lng: 139.6983,
        imageUrl: 'https://example.com/image2.jpg',
        status: entities.StoreStatus.wantToGo,
        memo: '',
        createdAt: DateTime.now(),
      );
      await storeDatasource.insertStore(store);

      // Act: storeパラメータをnullで訪問記録を追加
      final visitedAt = DateTime.now();
      final result = await usecase.call(
        store: null, // storeパラメータをnullで呼び出し
        storeId: store.id,
        visitedAt: visitedAt,
        menu: 'エビチリ',
        memo: 'プリプリで美味しい',
      );

      // Assert: 訪問記録が正常に作成されたことを確認
      expect(result.storeId, equals(store.id));
      expect(result.menu, equals('エビチリ'));
      expect(result.memo, equals('プリプリで美味しい'));
    });

    test(
        'should throw exception with clear message when visit record insertion fails',
        () async {
      // 🔴 Red: 訪問記録の保存に失敗した場合、明確なエラーメッセージを含む例外をスローする
      // Arrange: 存在しないstoreIdを使用（Foreign Key制約違反を引き起こす）

      // Act & Assert: 明確なエラーメッセージを含む例外がスローされることを期待
      expect(
        () async => await usecase.call(
          store: null,
          storeId: 'non_existent_store_id',
          visitedAt: DateTime.now(),
          menu: 'チャーハン',
          memo: 'テスト',
        ),
        throwsA(
          predicate(
              (e) => e is Exception && e.toString().contains('訪問記録の保存に失敗しました')),
        ),
      );
    });
  });
}
