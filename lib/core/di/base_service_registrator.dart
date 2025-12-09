import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:developer' as developer;

import 'service_container.dart';
import '../config/environment_config.dart' as env_config;
import 'di_error_handler.dart';
import '../database/schema/app_database.dart';
import '../../data/datasources/hotpepper_proxy_datasource.dart';
import '../../data/datasources/store_local_datasource.dart';
import '../../data/datasources/visit_record_local_datasource.dart';
import '../../data/datasources/photo_local_datasource.dart';
import '../../data/repositories/store_repository_impl.dart';
import '../../data/repositories/visit_record_repository_impl.dart';
import '../../data/services/geolocator_location_service.dart';
import '../../domain/repositories/visit_record_repository.dart';
import '../../domain/services/location_service.dart';
import '../../domain/usecases/add_visit_record_usecase.dart';
import '../../domain/usecases/get_visit_records_by_store_id_usecase.dart';
import '../../presentation/providers/store_provider.dart';

/// Base class for service registration across different environments
///
/// This class provides common service registration logic that can be shared
/// across different DI container implementations.
abstract class BaseServiceRegistrator {
  /// Register services common to all environments
  static void registerCommonServices(ServiceContainer serviceContainer) {
    // Register Drift database (singleton)
    serviceContainer.registerSingleton<AppDatabase>(
      () => AppDatabase(_openDatabaseConnection()),
    );

    // Register HotpepperProxyDatasource for secure API communication
    registerHotpepperProxyDatasource(serviceContainer);

    // Register Drift datasources
    serviceContainer.register<StoreLocalDatasource>(() {
      return StoreLocalDatasourceImpl(serviceContainer.resolve<AppDatabase>());
    });

    serviceContainer.register<VisitRecordLocalDatasource>(() {
      return VisitRecordLocalDatasourceImpl(
          serviceContainer.resolve<AppDatabase>());
    });

    serviceContainer.register<PhotoLocalDatasource>(() {
      return PhotoLocalDatasourceImpl(serviceContainer.resolve<AppDatabase>());
    });

    // Register repositories
    serviceContainer.register<StoreRepositoryImpl>(() {
      return StoreRepositoryImpl(
        apiDatasource: serviceContainer.resolve<HotpepperProxyDatasource>(),
        localDatasource: serviceContainer.resolve<StoreLocalDatasource>(),
      );
    });

    serviceContainer.register<VisitRecordRepository>(() {
      return VisitRecordRepositoryImpl(
        serviceContainer.resolve<VisitRecordLocalDatasource>(),
      );
    });

    // Register StoreProvider
    serviceContainer.register<StoreProvider>(() {
      return StoreProvider(
        repository: serviceContainer.resolve<StoreRepositoryImpl>(),
      );
    });

    // Register Visit Record UseCases
    serviceContainer.register<AddVisitRecordUsecase>(() {
      return AddVisitRecordUsecase(
        serviceContainer.resolve<VisitRecordRepository>(),
        serviceContainer.resolve<StoreRepositoryImpl>(),
      );
    });

    serviceContainer.register<GetVisitRecordsByStoreIdUsecase>(() {
      return GetVisitRecordsByStoreIdUsecase(
        serviceContainer.resolve<VisitRecordRepository>(),
      );
    });

    // Register LocationService
    serviceContainer.register<LocationService>(
      () => const GeolocatorLocationService(),
    );
  }

  // HotpepperApiDatasource関連のメソッドは削除
  // プロキシサーバー経由でのみAPI呼び出しを行うため不要

  /// Register HotpepperProxyDatasource for secure API communication via Cloudflare Workers
  static void registerHotpepperProxyDatasource(
      ServiceContainer serviceContainer) {
    serviceContainer.register<HotpepperProxyDatasource>(() {
      // 環境設定からプロキシURLを取得（設定されていない場合はデフォルト使用）
      final proxyUrl = env_config.EnvironmentConfig.backendApiUrl.isNotEmpty
          ? env_config.EnvironmentConfig.backendApiUrl
          : null;

      developer.log(
          'Using HotpepperProxyDatasource with SSL bypass: ${proxyUrl ?? "default URL"}',
          name: 'DI');

      // SSL証明書バイパス版コンストラクタを使用
      return HotpepperProxyDatasourceImpl.withSSLBypass(
        proxyBaseUrl: proxyUrl,
      );
    });
  }

  /// Create Drift database connection
  static DatabaseConnection _openDatabaseConnection() {
    // プラットフォーム別のデータベース接続
    if (kIsWeb) {
      return _createWebDatabaseConnection();
    } else {
      return _createNativeDatabaseConnection();
    }
  }

  /// Create Web platform database connection
  static DatabaseConnection _createWebDatabaseConnection() {
    const platform = 'Web';

    // テスト環境でのみインメモリデータベースを使用
    if (const bool.fromEnvironment('flutter.test', defaultValue: false)) {
      DIErrorHandler.logSuccessfulOperation(
        'データベース接続',
        'テスト用インメモリデータベース使用 ($platform環境)',
        isVerbose: true,
      );
      return DatabaseConnection(NativeDatabase.memory());
    } else {
      // Issue #111 修正: Web環境での本番使用をサポート
      DIErrorHandler.handleConfigurationWarning(
        platform,
        'インメモリデータベース使用（永続化なし）',
        recommendation: '将来的にはIndexedDB実装に移行予定',
      );

      try {
        // Web環境では永続化されないインメモリデータベースを使用
        return DatabaseConnection(NativeDatabase.memory());
      } catch (e) {
        final exception = e is Exception ? e : Exception(e.toString());
        DIErrorHandler.handleDatabaseError(
          platform,
          'インメモリデータベース初期化',
          exception,
          recoveryHint: 'ブラウザのキャッシュをクリアしてください',
        );
        rethrow;
      }
    }
  }

  /// Create Native platform database connection
  static DatabaseConnection _createNativeDatabaseConnection() {
    const platform = 'Native';

    if (const bool.fromEnvironment('flutter.test', defaultValue: false)) {
      // テスト環境: インメモリデータベース使用
      DIErrorHandler.logSuccessfulOperation(
        'データベース接続',
        'テスト用インメモリデータベース使用（race condition回避）',
        isVerbose: true,
      );
      return DatabaseConnection(NativeDatabase.memory());
    } else {
      // Issue #200 修正: path_providerを使用した永続化パス実装
      try {
        // 同期的にデータベースを開くために、アプリケーションディレクトリを取得する
        // Note: この処理は非同期だが、NativeDatabaseはバックグラウンドで開くため問題ない
        return _createPersistentDatabaseConnection(platform);
      } catch (e) {
        final exception = e is Exception ? e : Exception(e.toString());
        DIErrorHandler.handleDatabaseError(
          platform,
          '永続化データベース初期化',
          exception,
          recoveryHint: 'アプリを再起動してください',
        );
        // フォールバック: インメモリデータベース
        return DatabaseConnection(NativeDatabase.memory());
      }
    }
  }

  /// 永続化データベース接続を作成
  static DatabaseConnection _createPersistentDatabaseConnection(
      String platform) {
    // Issue #200: LazyDatabaseを使用して非同期でパスを解決
    // LazyDatabaseは初回アクセス時に非同期でデータベースを開く
    const dbFileName = 'app_db.sqlite';

    DIErrorHandler.logSuccessfulOperation(
      'データベース接続',
      '永続化データベースを使用: $dbFileName',
      isVerbose: true,
    );

    return DatabaseConnection(
      LazyDatabase(() async {
        // 非同期でアプリケーションドキュメントディレクトリを取得
        final directory = await getApplicationDocumentsDirectory();
        final dbPath = '${directory.path}/$dbFileName';

        developer.log(
          'Database path resolved: $dbPath',
          name: 'DI',
        );

        // 永続化されたデータベースファイルを開く
        return NativeDatabase.createInBackground(File(dbPath));
      }),
    );
  }
}
