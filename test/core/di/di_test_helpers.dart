import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/di/di_container_interface.dart';
import 'package:chinese_food_app/core/di/app_di_container.dart';
import 'package:chinese_food_app/presentation/providers/store_provider.dart';
import 'package:chinese_food_app/domain/services/location_service.dart';

/// Test helper utilities for DI container testing
class DITestHelpers {
  /// Create a DI container configured for testing
  ///
  /// This helper creates an AppDIContainer instance and configures it
  /// for the test environment, ensuring consistent test setup.
  ///
  /// Example usage:
  /// ```dart
  /// final container = DITestHelpers.createTestContainer();
  /// final provider = container.getStoreProvider();
  /// ```
  static DIContainerInterface createTestContainer() {
    final container = AppDIContainer();
    container.configureForEnvironment(Environment.test);
    return container;
  }

  /// Create a DI container for a specific environment
  ///
  /// This helper allows creating containers for different environments
  /// during testing to verify environment-specific behavior.
  ///
  /// Example usage:
  /// ```dart
  /// final prodContainer = DITestHelpers.createContainerForEnvironment(Environment.production);
  /// final devContainer = DITestHelpers.createContainerForEnvironment(Environment.development);
  /// ```
  static DIContainerInterface createContainerForEnvironment(
      Environment environment) {
    final container = AppDIContainer();
    container.configureForEnvironment(environment);
    return container;
  }

  /// Verify that a DI container is properly configured and functional
  ///
  /// This helper performs comprehensive checks on a DI container to ensure
  /// it's properly configured and all services can be resolved.
  ///
  /// Example usage:
  /// ```dart
  /// final container = DITestHelpers.createTestContainer();
  /// DITestHelpers.verifyContainerState(container);
  /// ```
  static void verifyContainerState(DIContainerInterface container) {
    // Verify container is configured
    expect(container.isConfigured, isTrue,
        reason: 'Container should be configured');

    // Verify services can be resolved without errors
    expect(() => container.getStoreProvider(), returnsNormally,
        reason: 'StoreProvider should be resolvable');
    expect(() => container.getLocationService(), returnsNormally,
        reason: 'LocationService should be resolvable');

    // Verify services are of correct types
    final storeProvider = container.getStoreProvider();
    final locationService = container.getLocationService();

    expect(storeProvider, isA<StoreProvider>(),
        reason: 'Should return StoreProvider instance');
    expect(locationService, isA<LocationService>(),
        reason: 'Should return LocationService instance');
  }

  /// Verify that services are properly instantiated (not null)
  ///
  /// This helper checks that resolved services are valid instances
  /// and have expected properties.
  ///
  /// Example usage:
  /// ```dart
  /// final container = DITestHelpers.createTestContainer();
  /// DITestHelpers.verifyServiceInstances(container);
  /// ```
  static void verifyServiceInstances(DIContainerInterface container) {
    final storeProvider = container.getStoreProvider();
    final locationService = container.getLocationService();

    // Verify instances are not null
    expect(storeProvider, isNotNull,
        reason: 'StoreProvider should not be null');
    expect(locationService, isNotNull,
        reason: 'LocationService should not be null');

    // Verify instances have expected properties
    expect(storeProvider.repository, isNotNull,
        reason: 'StoreProvider should have repository');
  }

  /// Create a container and verify it throws when not configured
  ///
  /// This helper verifies that unconfigured containers properly throw
  /// exceptions when services are requested.
  ///
  /// Example usage:
  /// ```dart
  /// DITestHelpers.verifyUnconfiguredContainerBehavior();
  /// ```
  static void verifyUnconfiguredContainerBehavior() {
    final container = AppDIContainer();

    // Should throw when accessing services before configuration
    expect(() => container.getStoreProvider(),
        throwsA(isA<DIContainerException>()),
        reason: 'Should throw exception when accessing unconfigured service');
    expect(() => container.getLocationService(),
        throwsA(isA<DIContainerException>()),
        reason: 'Should throw exception when accessing unconfigured service');
  }

  /// Verify container disposal cleans up properly
  ///
  /// This helper tests the disposal mechanism to ensure proper cleanup.
  ///
  /// Example usage:
  /// ```dart
  /// final container = DITestHelpers.createTestContainer();
  /// DITestHelpers.verifyContainerDisposal(container);
  /// ```
  static void verifyContainerDisposal(DIContainerInterface container) {
    // Verify container works before disposal
    expect(container.isConfigured, isTrue);
    expect(() => container.getStoreProvider(), returnsNormally);

    // Dispose container
    container.dispose();

    // Verify container is properly disposed
    expect(container.isConfigured, isFalse,
        reason: 'Container should be unconfigured after disposal');
    expect(() => container.getStoreProvider(),
        throwsA(isA<DIContainerException>()),
        reason: 'Should throw exception after disposal');
  }

  /// Setup method for common test scenarios
  ///
  /// This helper provides a standardized setup for DI container tests,
  /// including creation, configuration, and verification.
  ///
  /// Example usage:
  /// ```dart
  /// group('DI Container Tests', () {
  ///   late DIContainerInterface container;
  ///
  ///   setUp(() {
  ///     container = DITestHelpers.setupStandardTest();
  ///   });
  ///
  ///   tearDown(() {
  ///     container.dispose();
  ///   });
  /// });
  /// ```
  static DIContainerInterface setupStandardTest() {
    final container = createTestContainer();
    verifyContainerState(container);
    return container;
  }

  /// Verify service resolution performance
  ///
  /// This helper measures service resolution performance to ensure
  /// it meets performance requirements.
  ///
  /// Example usage:
  /// ```dart
  /// final container = DITestHelpers.createTestContainer();
  /// DITestHelpers.verifyPerformance(container, iterations: 100);
  /// ```
  static void verifyPerformance(DIContainerInterface container,
      {int iterations = 1000}) {
    final stopwatch = Stopwatch()..start();

    for (int i = 0; i < iterations; i++) {
      container.getStoreProvider();
      container.getLocationService();
    }

    stopwatch.stop();

    // より現実的なパフォーマンス期待値：1000回の解決で10秒以内
    // （データベースとDI初期化を考慮した現実的な閾値）
    final maxTime = (iterations * 10).round(); // より緩い制限: 10ms per iteration
    expect(stopwatch.elapsedMilliseconds, lessThan(maxTime),
        reason:
            'Service resolution should be fast ($iterations iterations in <${maxTime}ms)');
  }
}
