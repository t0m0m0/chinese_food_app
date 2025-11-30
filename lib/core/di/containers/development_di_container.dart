import '../di_container_interface.dart';
import '../service_container.dart';
import '../base_service_registrator.dart';
import '../../../presentation/providers/store_provider.dart';
import '../../../domain/services/location_service.dart';
import '../../../domain/usecases/add_visit_record_usecase.dart';
import '../../../domain/usecases/get_visit_records_by_store_id_usecase.dart';

/// Development environment specific DI container
///
/// This container provides development-friendly configurations with
/// fallback to mock services when real services are not available.
class DevelopmentDIContainer implements DIContainerInterface {
  final ServiceContainer _serviceContainer = ServiceContainer();
  bool _isConfigured = false;

  @override
  bool get isConfigured => _isConfigured;

  @override
  void configure() {
    configureForEnvironment(Environment.development);
  }

  @override
  void configureForEnvironment(Environment environment) {
    // For development container, we always configure for development
    if (environment != Environment.development) {
      throw const DIContainerException(
        'DevelopmentDIContainer can only be configured for development environment',
      );
    }

    // Clear existing registrations
    _serviceContainer.dispose();

    // Register development services
    _registerDevelopmentServices();

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
  GetVisitRecordsByStoreIdUsecase getGetVisitRecordsByStoreIdUsecase() {
    _ensureConfigured();
    return _serviceContainer.resolve<GetVisitRecordsByStoreIdUsecase>();
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

  /// Register services specific to development environment
  void _registerDevelopmentServices() {
    // プロキシサーバー経由でのみAPI呼び出しを行うため、
    // HotpepperApiDatasourceの登録は不要

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
