import '../di_container_interface.dart';
import '../service_container.dart';
import '../base_service_registrator.dart';
import '../../../presentation/providers/store_provider.dart';
import '../../../domain/services/location_service.dart';

/// Production environment specific DI container
///
/// This container provides real services and production-ready configurations
/// for the production environment.
class ProductionDIContainer implements DIContainerInterface {
  final ServiceContainer _serviceContainer = ServiceContainer();
  bool _isConfigured = false;

  @override
  bool get isConfigured => _isConfigured;

  @override
  void configure() {
    configureForEnvironment(Environment.production);
  }

  @override
  void configureForEnvironment(Environment environment) {
    // For production container, we always configure for production
    if (environment != Environment.production) {
      throw const DIContainerException(
        'ProductionDIContainer can only be configured for production environment',
      );
    }

    // Clear existing registrations
    _serviceContainer.dispose();

    // Register production services
    _registerProductionServices();

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
    throw const DIContainerException(
      'Test provider registration is not allowed in production container',
    );
  }

  @override
  void dispose() {
    _serviceContainer.dispose();
    _isConfigured = false;
  }

  /// Register services specific to production environment
  void _registerProductionServices() {
    // Register production API datasource
    BaseServiceRegistrator.registerProductionApiDatasource(_serviceContainer);

    // Register common services
    BaseServiceRegistrator.registerCommonServices(_serviceContainer);
  }

  void _ensureConfigured() {
    if (!_isConfigured) {
      throw const DIContainerException(
        'Container is not configured. Call configure() first.',
      );
    }
  }
}
