import '../config/app_config.dart';
import '../database/schema/app_database.dart';
import '../network/app_http_client.dart';
import '../../data/datasources/hotpepper_api_datasource.dart';
import '../../data/datasources/store_local_datasource_drift.dart';
import '../../data/repositories/store_repository_impl.dart';
import '../../data/services/geolocator_location_service.dart';
import '../../domain/services/location_service.dart';
import '../../presentation/providers/store_provider.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'dart:io';

/// 依存性注入コンテナ
///
/// アプリケーション全体の依存関係を管理し、
/// 適切なオブジェクトの生成と注入を担当する
class DIContainer {
  /// StoreProviderを作成し、必要な依存関係を注入
  ///
  /// 環境に応じて適切なAPIデータソースを選択し、
  /// Clean Architectureの原則に従って依存関係を構築する
  static StoreProvider createStoreProvider() {
    // API データソースの選択
    final HotpepperApiDatasource apiDatasource = _createApiDatasource();

    // ローカルデータソースの作成
    final StoreLocalDatasourceDrift localDatasource = _createLocalDatasource();

    // リポジトリの作成
    final StoreRepositoryImpl repository = StoreRepositoryImpl(
      apiDatasource: apiDatasource,
      localDatasource: localDatasource,
    );

    // Providerの作成
    return StoreProvider(
        repository: repository, locationService: createLocationService());
  }

  /// 環境に応じたAPIデータソースを作成
  static HotpepperApiDatasource _createApiDatasource() {
    if (AppConfig.isProduction) {
      // 本番環境では常に実APIを使用
      return HotpepperApiDatasourceImpl(AppHttpClient());
    } else if (AppConfig.hasHotpepperApiKey) {
      // 開発環境でAPIキーが設定されている場合は実API使用
      return HotpepperApiDatasourceImpl(AppHttpClient());
    } else {
      // APIキー未設定時はモック使用
      return MockHotpepperApiDatasource();
    }
  }

  /// ローカルデータソースを作成
  static StoreLocalDatasourceDrift _createLocalDatasource() {
    final database =
        AppDatabase(DatabaseConnection(NativeDatabase.createInBackground(
      File('app_db.sqlite'),
    )));
    return StoreLocalDatasourceDrift(database);
  }

  /// LocationServiceを作成
  static LocationService createLocationService() {
    return const GeolocatorLocationService();
  }

  // 将来の拡張用メソッド

  /// 将来的に他のProviderを追加する場合の例
  // static PhotoProvider createPhotoProvider() { ... }
  // static VisitRecordProvider createVisitRecordProvider() { ... }

  /// テスト用の依存関係を作成する場合の例
  // static StoreProvider createTestStoreProvider({
  //   required StoreRepository mockRepository,
  // }) {
  //   return StoreProvider(repository: mockRepository);
  // }
}
