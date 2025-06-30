import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../database/database_helper.dart';
import '../../data/datasources/hotpepper_api_datasource.dart';
import '../../data/datasources/store_local_datasource.dart';
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
        return HotpepperApiDatasourceImpl(client: http.Client());
      } else {
        return MockHotpepperApiDatasource();
      }
    }

    // In development, use mock by default for faster development
    return MockHotpepperApiDatasource();
  }

  /// Register services common to all environments
  void _registerCommonServices() {
    // Register local datasource
    _serviceContainer.register<StoreLocalDatasource>(
      () => StoreLocalDatasourceImpl(dbHelper: DatabaseHelper()),
    );

    // Register repository
    _serviceContainer.register<StoreRepositoryImpl>(() {
      return StoreRepositoryImpl(
        apiDatasource: _serviceContainer.resolve<HotpepperApiDatasource>(),
        localDatasource: _serviceContainer.resolve<StoreLocalDatasource>(),
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

  /// Determine current environment based on configuration
  Environment _determineEnvironment() {
    // Check for test environment first (for Flutter test framework)
    if (const bool.fromEnvironment('flutter.test', defaultValue: false)) {
      return Environment.test;
    }

    // Check for explicit environment variable
    const envMode = String.fromEnvironment('APP_ENV', defaultValue: '');
    switch (envMode.toLowerCase()) {
      case 'production':
      case 'prod':
        return Environment.production;
      case 'test':
      case 'testing':
        return Environment.test;
      case 'development':
      case 'dev':
      default:
        return Environment.development;
    }
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
