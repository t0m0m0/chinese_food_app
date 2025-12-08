import '../di_container_interface.dart';
import '../service_container.dart';
import '../base_service_registrator.dart';
import '../../../presentation/providers/store_provider.dart';
import '../../../domain/services/location_service.dart';
import '../../../domain/usecases/add_visit_record_usecase.dart';
import '../../../domain/usecases/get_visit_records_by_store_id_usecase.dart';

/// Abstract base class for environment-specific DI containers
///
/// This class extracts common implementation from Production, Development,
/// and Test DI containers to reduce code duplication.
///
/// Subclasses only need to:
/// 1. Call super constructor with the target environment
/// 2. Override [registerEnvironmentSpecificServices] for environment-specific registrations
/// 3. Override [allowsTestProviderRegistration] to control test provider registration
///
/// Example:
/// ```dart
/// class TestDIContainer extends BaseEnvironmentContainer {
///   TestDIContainer() : super(Environment.test);
///
///   @override
///   void registerEnvironmentSpecificServices() {
///     // Register test-specific services
///   }
///
///   @override
///   bool get allowsTestProviderRegistration => true;
/// }
/// ```
abstract class BaseEnvironmentContainer implements DIContainerInterface {
  final Environment _targetEnvironment;
  final ServiceContainer _serviceContainer = ServiceContainer();
  bool _isConfigured = false;

  BaseEnvironmentContainer(this._targetEnvironment);

  /// The environment this container is designed for
  Environment get targetEnvironment => _targetEnvironment;

  /// Whether this container allows test provider registration
  ///
  /// Override this to `true` in test/development containers,
  /// `false` in production container.
  bool get allowsTestProviderRegistration;

  /// Register environment-specific services
  ///
  /// Override this method to register services specific to the environment.
  /// Common services are already registered by [BaseServiceRegistrator].
  void registerEnvironmentSpecificServices();

  @override
  bool get isConfigured => _isConfigured;

  @override
  void configure() {
    configureForEnvironment(_targetEnvironment);
  }

  @override
  void configureForEnvironment(Environment environment) {
    if (environment != _targetEnvironment) {
      throw DIContainerException(
        '${runtimeType} can only be configured for ${_targetEnvironment.name} environment',
      );
    }

    // Clear existing registrations
    _serviceContainer.dispose();

    // Register environment-specific services first (if any pre-requisites)
    registerEnvironmentSpecificServices();

    // Register common services
    BaseServiceRegistrator.registerCommonServices(_serviceContainer);

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
    if (!allowsTestProviderRegistration) {
      throw const DIContainerException(
        'Test provider registration is not allowed in production container',
      );
    }
    _serviceContainer.register<StoreProvider>(() => provider);
  }

  @override
  void dispose() {
    _serviceContainer.dispose();
    _isConfigured = false;
  }

  void _ensureConfigured() {
    if (!_isConfigured) {
      throw const DIContainerException(
        'Container is not configured. Call configure() first.',
      );
    }
  }
}
