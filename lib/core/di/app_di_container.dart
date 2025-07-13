import 'dart:developer' as developer;
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File;
import '../config/app_config.dart';
import '../database/schema/app_database.dart';
import '../network/app_http_client.dart';
import '../../data/datasources/hotpepper_api_datasource.dart';
import '../../data/datasources/store_local_datasource_drift.dart';
import '../../data/datasources/visit_record_local_datasource_drift.dart';
import '../../data/datasources/photo_local_datasource_drift.dart';
import '../../data/repositories/store_repository_impl.dart';
import '../../data/services/geolocator_location_service.dart';
import '../../domain/services/location_service.dart';
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
    // Register API datasource with fallback strategy
    _serviceContainer.register<HotpepperApiDatasource>(() {
      return _createApiDatasource(forceReal: true);
    });

    _registerCommonServices();
  }

  /// Register services for development environment
  void _registerDevelopmentServices() {
    // Register API datasource with intelligent selection
    _serviceContainer.register<HotpepperApiDatasource>(() {
      return _createApiDatasource(forceReal: false);
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

  /// Create API datasource with environment-aware selection
  HotpepperApiDatasource _createApiDatasource({bool forceReal = false}) {
    // Force real API in production or when explicitly requested
    if (forceReal) {
      // Check if API key is available, fallback to mock if not
      if (AppConfig.hasHotpepperApiKey) {
        developer.log('Using real HotPepper API datasource', name: 'DI');
        return HotpepperApiDatasourceImpl(AppHttpClient());
      } else {
        developer.log('API key not available, falling back to mock datasource',
            name: 'DI', level: 900); // WARNING level
        return MockHotpepperApiDatasource();
      }
    }

    // In development, use mock by default for faster development
    developer.log('Using mock API datasource for development', name: 'DI');
    return MockHotpepperApiDatasource();
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

    // Register repository
    _serviceContainer.register<StoreRepositoryImpl>(() {
      return StoreRepositoryImpl(
        apiDatasource: _serviceContainer.resolve<HotpepperApiDatasource>(),
        localDatasource: _serviceContainer.resolve<StoreLocalDatasourceDrift>(),
      );
    });

    // Register StoreProvider
    _serviceContainer.register<StoreProvider>(() {
      return StoreProvider(
        repository: _serviceContainer.resolve<StoreRepositoryImpl>(),
      );
    });

    // Register LocationService
    _serviceContainer.register<LocationService>(
      () => GeolocatorLocationService(),
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
      // Web環境: テスト専用のインメモリデータベース
      // 注意: CI環境ではWeb実行時にSQLite制限があるため、テスト環境のみ対応
      developer.log('Web環境: テスト専用インメモリデータベース使用', name: 'Database');

      // テスト環境でのみWeb対応、本番環境では未対応
      if (const bool.fromEnvironment('flutter.test', defaultValue: false)) {
        return DatabaseConnection(NativeDatabase.memory());
      } else {
        throw UnsupportedError('Web環境での本番使用は現在未対応です。Native環境を使用してください。');
      }
    } else {
      // Native環境: SQLiteファイルを使用
      developer.log('Native環境: SQLiteファイルを使用', name: 'Database');
      return DatabaseConnection(NativeDatabase.createInBackground(
        File('app_db.sqlite'),
      ));
    }
  }

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
  void _ensureConfigured() {
    if (!_isConfigured) {
      throw const DIContainerException(
        'Container is not configured. Call configure() first.',
      );
    }
  }
}
