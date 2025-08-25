import 'dart:developer' as developer;
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../config/environment_config.dart' as env_config;
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
import 'di_container_interface.dart';
import 'service_container.dart';

/// Concrete implementation of DIContainerInterface using ServiceContainer
///
/// This implementation provides environment-aware dependency injection
/// with support for both production and test configurations.
///
/// Features:
/// - ServiceContainer-based dependency management
/// - Environment-specific service configuration
/// - Testability through service replacement
/// - Memory management and cleanup
class AppDIContainer implements DIContainerInterface {
  final ServiceContainer _serviceContainer = ServiceContainer();
  bool _isConfigured = false;

  // Issue #113 Phase 1: ログレベル定数の定義
  static const int logLevelWarning = 900;
  static const int logLevelError = 1000;

  @override
  bool get isConfigured => _isConfigured;

  @override
  void configure() {
    configureForEnvironment(_determineEnvironment());
  }

  @override
  void configureForEnvironment(Environment environment) {
    // Clear existing registrations
    _serviceContainer.dispose();

    // Register services based on environment
    _registerServices(environment);

    _isConfigured = true;
  }

  @override
  StoreProvider getStoreProvider() {
    _ensureConfigured();
    return _serviceContainer.resolve<StoreProvider>();
  }

  @override
  LocationService getLocationService() {
    _ensureConfigured();
    return _serviceContainer.resolve<LocationService>();
  }

  @override
  void registerTestProvider(StoreProvider provider) {
    _serviceContainer.register<StoreProvider>(() => provider);
  }

  @override
  void dispose() {
    _serviceContainer.dispose();
    _isConfigured = false;
  }

  /// Register all services based on environment
  void _registerServices(Environment environment) {
    switch (environment) {
      case Environment.production:
        _registerProductionServices();
        break;
      case Environment.development:
        _registerDevelopmentServices();
        break;
      case Environment.test:
        _registerTestServices();
        break;
    }
  }

  /// Register services for production environment
  void _registerProductionServices() {
    // Register API datasource - always use real API in production
    _serviceContainer.register<HotpepperApiDatasource>(() {
      developer.log('Using real HotPepper API datasource (production)',
          name: 'DI');
      return HotpepperApiDatasourceImpl(AppHttpClient());
    });

    _registerCommonServices();
  }

  /// Register services for development environment
  void _registerDevelopmentServices() {
    // Register API datasource - use real API if key is available (lazy check)
    _serviceContainer.register<HotpepperApiDatasource>(() {
      return _createApiDatasourceForDevelopment();
    });

    _registerCommonServices();
  }

  /// Register services for test environment
  void _registerTestServices() {
    // Register mock API datasource for testing
    _serviceContainer.register<HotpepperApiDatasource>(
      () => MockHotpepperApiDatasource(),
    );

    _registerCommonServices();
  }

  /// Create API datasource for development environment
  HotpepperApiDatasource _createApiDatasourceForDevelopment() {
    // In development, use EnvironmentConfig which properly reads from .env files
    try {
      // Ensure EnvironmentConfig is initialized and check for API key
      final apiKey = env_config.EnvironmentConfig.hotpepperApiKey;
      developer.log('🔑 Development環境でのAPIキー確認:', name: 'DI');
      developer.log(
          '  APIキー: ${apiKey.isNotEmpty ? "設定済み(${apiKey.length}文字)" : "未設定"}',
          name: 'DI');

      if (apiKey.isNotEmpty) {
        developer.log(
            'Using real HotPepper API datasource (development) - API key found',
            name: 'DI');
        developer.log('✅ 実際のHotPepperApiDatasourceImplを使用', name: 'DI');
        return HotpepperApiDatasourceImpl(AppHttpClient());
      } else {
        developer.log(
            'API key not available, using mock datasource (development)',
            name: 'DI',
            level: 900); // WARNING level
        developer.log('⚠️ APIキー未設定のためMockHotpepperApiDatasourceを使用',
            name: 'DI');
        return MockHotpepperApiDatasource();
      }
    } catch (e) {
      developer.log(
          'Error checking API key, using mock datasource (development): $e',
          name: 'DI',
          level: 900); // WARNING level
      developer.log('❌ APIキー確認エラー、MockHotpepperApiDatasourceを使用: $e',
          name: 'DI');
      return MockHotpepperApiDatasource();
    }
  }

  /// Register services common to all environments
  void _registerCommonServices() {
    // Register Drift database (singleton)
    _serviceContainer.registerSingleton<AppDatabase>(
      () => AppDatabase(_openDatabaseConnection()),
    );

    // Register Drift datasources
    _serviceContainer.register<StoreLocalDatasourceDrift>(() {
      return StoreLocalDatasourceDrift(
          _serviceContainer.resolve<AppDatabase>());
    });

    _serviceContainer.register<VisitRecordLocalDatasourceDrift>(() {
      return VisitRecordLocalDatasourceDrift(
          _serviceContainer.resolve<AppDatabase>());
    });

    _serviceContainer.register<PhotoLocalDatasourceDrift>(() {
      return PhotoLocalDatasourceDrift(
          _serviceContainer.resolve<AppDatabase>());
    });

    // Register repositories
    _serviceContainer.register<StoreRepositoryImpl>(() {
      return StoreRepositoryImpl(
        apiDatasource: _serviceContainer.resolve<HotpepperApiDatasource>(),
        localDatasource: _serviceContainer.resolve<StoreLocalDatasourceDrift>(),
      );
    });

    _serviceContainer.register<VisitRecordRepository>(() {
      return VisitRecordRepositoryImpl(
        _serviceContainer.resolve<VisitRecordLocalDatasourceDrift>(),
      );
    });

    // Register StoreProvider
    _serviceContainer.register<StoreProvider>(() {
      return StoreProvider(
        repository: _serviceContainer.resolve<StoreRepositoryImpl>(),
        locationService: _serviceContainer.resolve<LocationService>(),
      );
    });

    // Register Visit Record UseCases
    _serviceContainer.register<AddVisitRecordUsecase>(() {
      return AddVisitRecordUsecase(
        _serviceContainer.resolve<VisitRecordRepository>(),
      );
    });

    _serviceContainer.register<GetVisitRecordsByStoreIdUsecase>(() {
      return GetVisitRecordsByStoreIdUsecase(
        _serviceContainer.resolve<VisitRecordRepository>(),
      );
    });

    // Register LocationService
    _serviceContainer.register<LocationService>(
      () => const GeolocatorLocationService(),
    );
  }

  /// Valid environment values for APP_ENV
  static const _validEnvironments = {
    'production',
    'prod',
    'test',
    'testing',
    'development',
    'dev'
  };

  /// Create Drift database connection
  DatabaseConnection _openDatabaseConnection() {
    // プラットフォーム別のデータベース接続
    if (kIsWeb) {
      return _createWebDatabaseConnection();
    } else {
      return _createNativeDatabaseConnection();
    }
  }

  /// Create Web platform database connection
  DatabaseConnection _createWebDatabaseConnection() {
    // Web環境: Drift Web APIまたはインメモリデータベース
    developer.log('Web環境: データベース接続を作成', name: 'Database');

    // テスト環境でのみインメモリデータベースを使用
    if (const bool.fromEnvironment('flutter.test', defaultValue: false)) {
      developer.log('Web環境: テスト用インメモリデータベース使用', name: 'Database');
      return DatabaseConnection(NativeDatabase.memory());
    } else {
      // Issue #111 修正: Web環境での本番使用をサポート
      // ただし、データはセッション限りとなることをユーザーに警告
      developer.log(
        'Web環境: インメモリデータベース使用（永続化なし）',
        name: 'Database',
        level: logLevelWarning,
      );

      try {
        // Web環境では永続化されないインメモリデータベースを使用
        // 将来的には IndexedDB ベースの実装に移行予定
        return DatabaseConnection(NativeDatabase.memory());
      } catch (e) {
        developer.log(
          'Web環境でのデータベース初期化に失敗: $e',
          name: 'Database',
          level: logLevelError,
        );
        rethrow;
      }
    }
  }

  /// Create Native platform database connection
  DatabaseConnection _createNativeDatabaseConnection() {
    if (const bool.fromEnvironment('flutter.test', defaultValue: false)) {
      // テスト環境: インメモリデータベース使用
      developer.log('テスト環境: インメモリデータベース使用（race condition回避）', name: 'Database');
      return DatabaseConnection(NativeDatabase.memory());
    } else {
      // Issue #111 緊急修正: ファイルアクセス問題を回避するためインメモリDBを使用
      // 注意: これは一時的な修正で、データは永続化されません
      developer.log(
        '緊急修正: ファイルアクセス問題のためインメモリデータベースを使用',
        name: 'Database',
        level: logLevelWarning,
      );
      return DatabaseConnection(NativeDatabase.memory());

      // TODO(Issue #113 Phase 3 by 2025-09-01): 永続化機能の復活
      // path_providerを使用した適切なファイルパス取得と永続化の実装
      // return DatabaseConnection(NativeDatabase.createInBackground(
      //   await _getDatabaseFileWithPathProvider(),
      // ));
    }
  }

  /// NOTE: Persistent Database Implementation Plan
  ///
  /// The following methods were temporarily removed to fix CI warnings:
  /// - `_getDatabaseFile()`: Platform-specific database file path creation
  /// - `_getApplicationSupportDirectory()`: Application support directory access
  ///
  /// **Current Status**: Emergency fix using in-memory database (Issue #111)
  /// - **Limitation**: Data is lost on app restart
  /// - **Affected Users**: All platforms (temporary)
  /// - **Code Preservation**: Available in git history (commit 54cf1f3)
  ///
  /// **Recovery Plan** (Issue #113):
  /// - Phase 3: Implement path_provider for proper file access
  /// - Target: 2025-09-01
  /// - Impact: Full data persistence restoration

  /// Determine current environment based on configuration
  Environment _determineEnvironment() {
    // Check for test environment first (for Flutter test framework)
    if (const bool.fromEnvironment('flutter.test', defaultValue: false)) {
      developer.log('Environment: test (Flutter test framework)', name: 'DI');
      return Environment.test;
    }

    // Check for explicit environment variable
    const envMode = String.fromEnvironment('APP_ENV', defaultValue: '');

    // Validate environment variable if provided
    if (envMode.isNotEmpty &&
        !_validEnvironments.contains(envMode.toLowerCase())) {
      developer.log(
          'Unknown APP_ENV value: "$envMode", falling back to development',
          name: 'DI',
          level: 900); // WARNING level
    }

    final environment = switch (envMode.toLowerCase()) {
      'production' || 'prod' => Environment.production,
      'test' || 'testing' => Environment.test,
      'development' || 'dev' || _ => Environment.development,
    };

    developer.log(
        'Environment: ${environment.name}${envMode.isNotEmpty ? ' (APP_ENV=$envMode)' : ' (default)'}',
        name: 'DI');
    return environment;
  }

  /// Ensure container is configured before accessing services
  /// 永続化データベース接続を作成（Issue #113 Phase 3）
  /// 
  /// path_providerを使用して適切なファイルパスでデータベースを作成します。
  /// 現在は未実装のため、UnimplementedErrorを投げます。
  Future<DatabaseConnection> createPersistentDatabaseConnection() async {
    throw UnimplementedError('Persistent database connection not yet implemented');
  }

  /// path_providerを使用したデータベースファイルパス取得（Issue #113 Phase 3）
  /// 
  /// アプリケーションサポートディレクトリ内にデータベースファイルを作成します。
  /// 現在は未実装のため、UnimplementedErrorを投げます。
  Future<String> getDatabaseFileWithPathProvider() async {
    throw UnimplementedError('Database file path with path_provider not yet implemented');
  }

  /// 本番環境用データベース作成（Issue #113 Phase 3）
  /// 
  /// 本番環境では永続化データベースを使用します。
  /// 現在は未実装のため、UnimplementedErrorを投げます。
  Future<DatabaseConnection> createProductionDatabase() async {
    throw UnimplementedError('Production database creation not yet implemented');
  }

  void _ensureConfigured() {
    if (!_isConfigured) {
      throw const DIContainerException(
        'Container is not configured. Call configure() first.',
      );
    }
  }
}
