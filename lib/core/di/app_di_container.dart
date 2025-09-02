import 'dart:developer' as developer;

import 'di_container_interface.dart';
import 'di_container_factory.dart';
import '../../presentation/providers/store_provider.dart';
import '../../domain/services/location_service.dart';

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
  Environment _determineEnvironment() {
    // Check for test environment first (for Flutter test framework)
    if (const bool.fromEnvironment('flutter.test', defaultValue: false)) {
      developer.log('Environment: test (Flutter test framework)', name: 'DI');
      return Environment.test;
    }

    // Check for explicit environment variable
    const envMode = String.fromEnvironment('APP_ENV', defaultValue: '');

    // Valid environment values for APP_ENV
    const validEnvironments = {
      'production',
      'prod',
      'test',
      'testing',
      'development',
      'dev'
    };

    // Validate environment variable if provided
    if (envMode.isNotEmpty &&
        !validEnvironments.contains(envMode.toLowerCase())) {
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
    if (_delegate == null || !_delegate!.isConfigured) {
      throw const DIContainerException(
        'Container is not configured. Call configure() first.',
      );
    }
  }
}
