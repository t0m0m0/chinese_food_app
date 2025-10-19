import '../di_container_interface.dart';
import '../service_container.dart';
import '../base_service_registrator.dart';
import '../../../presentation/providers/store_provider.dart';
import '../../../domain/services/location_service.dart';
import '../../../domain/usecases/add_visit_record_usecase.dart';

/// Test environment specific DI container
///
/// This container provides mock services and test-friendly configurations
/// for the test environment.
class TestDIContainer implements DIContainerInterface {
  final ServiceContainer _serviceContainer = ServiceContainer();
  bool _isConfigured = false;

  @override
  bool get isConfigured => _isConfigured;

  @override
  void configure() {
    configureForEnvironment(Environment.test);
  }

  @override
  void configureForEnvironment(Environment environment) {
    // For test container, we always configure for test
    if (environment != Environment.test) {
      throw const DIContainerException(
        'TestDIContainer can only be configured for test environment',
      );
    }

    // Clear existing registrations
    _serviceContainer.dispose();

    // Register test services
    _registerTestServices();

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
  AddVisitRecordUsecase getAddVisitRecordUsecase() {
    _ensureConfigured();
    return _serviceContainer.resolve<AddVisitRecordUsecase>();
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

  /// Register services specific to test environment
  void _registerTestServices() {
    // Register test API datasource (mock)
    BaseServiceRegistrator.registerTestApiDatasource(_serviceContainer);

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
