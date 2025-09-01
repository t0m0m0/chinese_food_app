import 'dart:developer' as developer;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'di_container_interface.dart';
import 'containers/production_di_container.dart';
import 'containers/development_di_container.dart';
import 'containers/test_di_container.dart';

/// Factory class for creating environment-specific DI containers
///
/// This factory provides a centralized way to create and configure
/// dependency injection containers based on the current environment.
///
/// Usage:
/// ```dart
/// // Create container for specific environment
/// final container = DIContainerFactory.create(Environment.production);
/// container.configure();
///
/// // Create and configure in one call
/// final configuredContainer = DIContainerFactory.createAndConfigure(Environment.test);
///
/// // Auto-detect environment and create container
/// final defaultContainer = DIContainerFactory.createDefault();
/// ```
class DIContainerFactory {
  /// Create a DI container for the specified environment
  static DIContainerInterface create(Environment environment) {
    developer.log('Creating DI container for environment: ${environment.name}',
        name: 'DIFactory');

    return switch (environment) {
      Environment.production => ProductionDIContainer(),
      Environment.development => DevelopmentDIContainer(),
      Environment.test => TestDIContainer(),
    };
  }

  /// Create and configure a DI container for the specified environment
  static DIContainerInterface createAndConfigure(Environment environment) {
    final container = create(environment);
    container.configure();
    developer.log(
        'Created and configured DI container for environment: ${environment.name}',
        name: 'DIFactory');
    return container;
  }

  /// Create a DI container with automatic environment detection
  static DIContainerInterface createDefault() {
    final environment = _determineEnvironment();
    developer.log('Auto-detected environment: ${environment.name}',
        name: 'DIFactory');
    return create(environment);
  }

  /// Create and configure a DI container with automatic environment detection
  static DIContainerInterface createAndConfigureDefault() {
    final environment = _determineEnvironment();
    developer.log(
        'Auto-detected and configuring environment: ${environment.name}',
        name: 'DIFactory');
    return createAndConfigure(environment);
  }

  /// Determine current environment based on configuration
  static Environment _determineEnvironment() {
    // Check for test environment first (for Flutter test framework)
    if (const bool.fromEnvironment('flutter.test', defaultValue: false)) {
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
        name: 'DIFactory',
        level: 900, // WARNING level
      );
    }

    return switch (envMode.toLowerCase()) {
      'production' || 'prod' => Environment.production,
      'test' || 'testing' => Environment.test,
      'development' || 'dev' || _ => Environment.development,
    };
  }
}
