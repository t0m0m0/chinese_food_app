import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:developer' as developer;

import 'service_container.dart';
import '../config/environment_config.dart' as env_config;
import 'di_error_handler.dart';
import '../database/schema/app_database.dart';
import '../network/app_http_client.dart';
import '../../data/datasources/hotpepper_api_datasource.dart';
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
        apiDatasource: serviceContainer.resolve<HotpepperApiDatasource>(),
        localDatasource: serviceContainer.resolve<StoreLocalDatasource>(),
      );
    });

    serviceContainer.register<VisitRecordRepository>(() {
      return VisitRecordRepositoryImpl(
        serviceContainer.resolve<VisitRecordLocalDatasourceImpl>(),
      );
    });

    // Register StoreProvider
    serviceContainer.register<StoreProvider>(() {
      return StoreProvider(
        repository: serviceContainer.resolve<StoreRepositoryImpl>(),
        locationService: serviceContainer.resolve<LocationService>(),
      );
    });

    // Register Visit Record UseCases
    serviceContainer.register<AddVisitRecordUsecase>(() {
      return AddVisitRecordUsecase(
        serviceContainer.resolve<VisitRecordRepository>(),
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

  /// Register production-specific API datasource
  static void registerProductionApiDatasource(
      ServiceContainer serviceContainer) {
    serviceContainer.register<HotpepperApiDatasource>(() {
      developer.log('Using real HotPepper API datasource (production)',
          name: 'DI');
      return HotpepperApiDatasourceImpl(AppHttpClient());
    });
  }

  /// Register development-specific API datasource with automatic fallback
  static void registerDevelopmentApiDatasource(
      ServiceContainer serviceContainer) {
    serviceContainer.register<HotpepperApiDatasource>(() {
      return _createDevelopmentApiDatasource();
    });
  }

  /// Create API datasource for development with smart environment detection
  static HotpepperApiDatasource _createDevelopmentApiDatasource() {
    try {
      // Check if API key is available in environment configuration
      final apiKey = env_config.EnvironmentConfig.hotpepperApiKey;
      final apiKeyStatus =
          apiKey.isNotEmpty ? '設定済み(${apiKey.length}文字)' : '未設定';

      if (apiKey.isNotEmpty) {
        DIErrorHandler.logSuccessfulOperation(
          'API設定確認',
          '実際のHotPepperApiDatasourceImplを使用 (開発環境)',
        );
        return HotpepperApiDatasourceImpl(AppHttpClient());
      } else {
        DIErrorHandler.handleApiConfigurationError(
          'development',
          apiKeyStatus,
          null, // Warning level (no error)
        );
        return MockHotpepperApiDatasource();
      }
    } catch (e) {
      DIErrorHandler.handleApiConfigurationError(
        'development',
        'エラー発生',
        e is Exception ? e : Exception(e.toString()),
      );
      return MockHotpepperApiDatasource();
    }
  }

  /// Register test-specific mock services
  static void registerTestApiDatasource(ServiceContainer serviceContainer) {
    serviceContainer.register<HotpepperApiDatasource>(
      () => MockHotpepperApiDatasource(),
    );
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
      // Issue #111 緊急修正: ファイルアクセス問題を回避するためインメモリDBを使用
      DIErrorHandler.handleConfigurationWarning(
        platform,
        'ファイルアクセス問題のためインメモリデータベースを使用',
        recommendation: 'Issue #113でpath_providerによる永続化実装予定',
      );
      return DatabaseConnection(NativeDatabase.memory());
    }
  }
}
