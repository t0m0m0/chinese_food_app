import '../../presentation/providers/store_provider.dart';
import '../../domain/services/location_service.dart';

/// Environment types for dependency injection configuration
enum Environment {
  /// Production environment with real services
  production,

  /// Development environment with mixed real/mock services
  development,

  /// Test environment with mock services
  test,
}

/// Exception thrown when DIContainer operations fail
class DIContainerException implements Exception {
  final String message;

  const DIContainerException(this.message);

  @override
  String toString() => 'DIContainerException: $message';
}

/// Interface for dependency injection container
///
/// This interface defines the contract for managing application dependencies
/// with support for different environments and testability.
///
/// Example usage:
/// ```dart
/// final container = AppDIContainer();
/// container.configure();
///
/// final storeProvider = container.getStoreProvider();
/// final locationService = container.getLocationService();
/// ```
abstract class DIContainerInterface {
  /// Configure the container with default environment settings
  void configure();

  /// Configure the container for a specific environment
  void configureForEnvironment(Environment environment);

  /// Get configured StoreProvider instance
  ///
  /// Throws [DIContainerException] if not configured
  StoreProvider getStoreProvider();

  /// Get configured LocationService instance
  ///
  /// Throws [DIContainerException] if not configured
  LocationService getLocationService();

  /// Register a test StoreProvider (for testing purposes)
  void registerTestProvider(StoreProvider provider);

  /// Check if the container is configured
  bool get isConfigured;

  /// Dispose all resources and clear registrations
  void dispose();
}
