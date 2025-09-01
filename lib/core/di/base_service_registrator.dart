import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:developer' as developer;

import 'service_container.dart';
import '../database/schema/app_database.dart';
import '../network/app_http_client.dart';
import '../../data/datasources/hotpepper_api_datasource.dart';
import '../../data/datasources/store_local_datasource_drift.dart';
import '../../data/datasources/visit_record_local_datasource_drift.dart';
import '../../data/datasources/photo_local_datasource_drift.dart';
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
    serviceContainer.register<StoreLocalDatasourceDrift>(() {
      return StoreLocalDatasourceDrift(serviceContainer.resolve<AppDatabase>());
    });

    serviceContainer.register<VisitRecordLocalDatasourceDrift>(() {
      return VisitRecordLocalDatasourceDrift(
          serviceContainer.resolve<AppDatabase>());
    });

    serviceContainer.register<PhotoLocalDatasourceDrift>(() {
      return PhotoLocalDatasourceDrift(serviceContainer.resolve<AppDatabase>());
    });

    // Register repositories
    serviceContainer.register<StoreRepositoryImpl>(() {
      return StoreRepositoryImpl(
        apiDatasource: serviceContainer.resolve<HotpepperApiDatasource>(),
        localDatasource: serviceContainer.resolve<StoreLocalDatasourceDrift>(),
      );
    });

    serviceContainer.register<VisitRecordRepository>(() {
      return VisitRecordRepositoryImpl(
        serviceContainer.resolve<VisitRecordLocalDatasourceDrift>(),
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

  /// Register development-specific API datasource with fallback
  static void registerDevelopmentApiDatasource(
      ServiceContainer serviceContainer) {
    serviceContainer.register<HotpepperApiDatasource>(() {
      // TODO: Implement environment-aware API datasource creation
      // For now, use mock to avoid API key dependency
      developer.log(
          'Using mock API datasource (development - API key not configured)',
          name: 'DI');
      return MockHotpepperApiDatasource();
    });
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
    // Web環境: Drift Web APIまたはインメモリデータベース
    developer.log('Web環境: データベース接続を作成', name: 'Database');

    // テスト環境でのみインメモリデータベースを使用
    if (const bool.fromEnvironment('flutter.test', defaultValue: false)) {
      developer.log('Web環境: テスト用インメモリデータベース使用', name: 'Database');
      return DatabaseConnection(NativeDatabase.memory());
    } else {
      // Issue #111 修正: Web環境での本番使用をサポート
      developer.log(
        'Web環境: インメモリデータベース使用（永続化なし）',
        name: 'Database',
        level: 900, // WARNING level
      );

      try {
        // Web環境では永続化されないインメモリデータベースを使用
        return DatabaseConnection(NativeDatabase.memory());
      } catch (e) {
        developer.log(
          'Web環境でのデータベース初期化に失敗: $e',
          name: 'Database',
          level: 1000, // ERROR level
        );
        rethrow;
      }
    }
  }

  /// Create Native platform database connection
  static DatabaseConnection _createNativeDatabaseConnection() {
    if (const bool.fromEnvironment('flutter.test', defaultValue: false)) {
      // テスト環境: インメモリデータベース使用
      developer.log('テスト環境: インメモリデータベース使用（race condition回避）', name: 'Database');
      return DatabaseConnection(NativeDatabase.memory());
    } else {
      // Issue #111 緊急修正: ファイルアクセス問題を回避するためインメモリDBを使用
      developer.log(
        '緊急修正: ファイルアクセス問題のためインメモリデータベースを使用',
        name: 'Database',
        level: 900, // WARNING level
      );
      return DatabaseConnection(NativeDatabase.memory());
    }
  }
}
