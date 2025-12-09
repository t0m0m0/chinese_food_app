import '../../presentation/providers/store_provider.dart';
import '../../domain/services/location_service.dart';
import '../../domain/usecases/add_visit_record_usecase.dart';
import '../../domain/usecases/get_visit_records_by_store_id_usecase.dart';

/// Environment types for dependency injection configuration
enum Environment {
  /// Production environment with real services
  production,

  /// Development environment with mixed real/mock services
  development,

  /// Test environment with mock services
  test;

  /// Determine current environment based on configuration
  ///
  /// Checks environment variables and compile-time constants
  /// to determine the appropriate environment.
  ///
  /// Priority:
  /// 1. Flutter test framework detection (`flutter.test`)
  /// 2. Explicit APP_ENV environment variable
  /// 3. Default to development
  static Environment detect() {
    // Check for test environment first (for Flutter test framework)
    if (const bool.fromEnvironment('flutter.test', defaultValue: false)) {
      return Environment.test;
    }

    // Check for explicit environment variable
    const envMode = String.fromEnvironment('APP_ENV', defaultValue: '');

    return switch (envMode.toLowerCase()) {
      'production' || 'prod' => Environment.production,
      'test' || 'testing' => Environment.test,
      'development' || 'dev' || _ => Environment.development,
    };
  }

  /// Valid APP_ENV values for validation
  static const validEnvValues = {
    'production',
    'prod',
    'test',
    'testing',
    'development',
    'dev',
  };

  /// Check if a given APP_ENV value is valid
  static bool isValidEnvValue(String value) {
    return validEnvValues.contains(value.toLowerCase());
  }
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

  /// Get configured AddVisitRecordUsecase instance
  ///
  /// Throws [DIContainerException] if not configured
  AddVisitRecordUsecase getAddVisitRecordUsecase();

  /// Get configured GetVisitRecordsByStoreIdUsecase instance
  ///
  /// Throws [DIContainerException] if not configured
  GetVisitRecordsByStoreIdUsecase getGetVisitRecordsByStoreIdUsecase();

  /// Register a test StoreProvider (for testing purposes)
  void registerTestProvider(StoreProvider provider);

  /// Check if the container is configured
  bool get isConfigured;

  /// Dispose all resources and clear registrations
  void dispose();
}
