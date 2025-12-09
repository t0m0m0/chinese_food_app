import 'dart:developer' as developer;

import 'di_container_interface.dart';
import 'di_container_factory.dart';
import '../../presentation/providers/store_provider.dart';
import '../../domain/services/location_service.dart';
import '../../domain/usecases/add_visit_record_usecase.dart';
import '../../domain/usecases/get_visit_records_by_store_id_usecase.dart';

/// Refactored AppDIContainer using DIContainerFactory internally
///
/// This implementation delegates to environment-specific containers through
/// DIContainerFactory, significantly reducing complexity from 410 lines to ~80 lines.
///
/// Key improvements:
/// - Single responsibility: Only delegates to appropriate container
/// - No direct service registration logic
/// - Environment-specific behavior handled by specialized containers
/// - Maintains full backward compatibility with existing API
class AppDIContainer implements DIContainerInterface {
  DIContainerInterface? _delegate;

  @override
  bool get isConfigured => _delegate?.isConfigured ?? false;

  @override
  void configure() {
    final environment = _determineEnvironment();
    configureForEnvironment(environment);
  }

  @override
  void configureForEnvironment(Environment environment) {
    developer.log(
        'AppDIContainer configuring for environment: ${environment.name}',
        name: 'DI');

    // Dispose previous delegate if exists
    _delegate?.dispose();

    // Create new environment-specific container
    _delegate = DIContainerFactory.createAndConfigure(environment);

    developer.log(
        'AppDIContainer configured successfully for ${environment.name}',
        name: 'DI');
  }

  @override
  StoreProvider getStoreProvider() {
    _ensureConfigured();
    return _delegate!.getStoreProvider();
  }

  @override
  LocationService getLocationService() {
    _ensureConfigured();
    return _delegate!.getLocationService();
  }

  @override
  AddVisitRecordUsecase getAddVisitRecordUsecase() {
    _ensureConfigured();
    return _delegate!.getAddVisitRecordUsecase();
  }

  @override
  GetVisitRecordsByStoreIdUsecase getGetVisitRecordsByStoreIdUsecase() {
    _ensureConfigured();
    return _delegate!.getGetVisitRecordsByStoreIdUsecase();
  }

  @override
  void registerTestProvider(StoreProvider provider) {
    _ensureConfigured();
    _delegate!.registerTestProvider(provider);
  }

  @override
  void dispose() {
    _delegate?.dispose();
    _delegate = null;
    developer.log('AppDIContainer disposed', name: 'DI');
  }

  /// Determine current environment based on configuration
  ///
  /// Delegates to [Environment.detect()] for the actual detection logic.
  Environment _determineEnvironment() {
    final environment = Environment.detect();

    // Log environment detection for debugging
    const envMode = String.fromEnvironment('APP_ENV', defaultValue: '');
    if (envMode.isNotEmpty && !Environment.isValidEnvValue(envMode)) {
      developer.log(
          'Unknown APP_ENV value: "$envMode", falling back to development',
          name: 'DI',
          level: 900); // WARNING level
    }

    developer.log(
        'Environment: ${environment.name}${envMode.isNotEmpty ? ' (APP_ENV=$envMode)' : ' (default)'}',
        name: 'DI');
    return environment;
  }

  /// Ensure container is configured before accessing services
  void _ensureConfigured() {
    if (_delegate == null || !_delegate!.isConfigured) {
      throw const DIContainerException(
        'Container is not configured. Call configure() first.',
      );
    }
  }
}
