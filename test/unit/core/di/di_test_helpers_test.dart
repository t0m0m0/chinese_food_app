import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/di/di_container_interface.dart';
import 'package:chinese_food_app/core/di/app_di_container.dart';
import 'di_test_helpers.dart';

void main() {
  group('DITestHelpers', () {
    group('createTestContainer', () {
      test('should create configured test container', () {
        // Act
        final container = DITestHelpers.createTestContainer();

        // Assert
        expect(container, isA<DIContainerInterface>());
        expect(container.isConfigured, isTrue);
      });

      test('should create functional test container', () {
        // Act
        final container = DITestHelpers.createTestContainer();

        // Assert
        expect(() => container.getStoreProvider(), returnsNormally);
        expect(() => container.getLocationService(), returnsNormally);
      });
    });

    group('createContainerForEnvironment', () {
      test('should create container for production environment', () {
        // Act
        final container =
            DITestHelpers.createContainerForEnvironment(Environment.production);

        // Assert
        expect(container.isConfigured, isTrue);
        expect(() => container.getStoreProvider(), returnsNormally);

        // Cleanup
        container.dispose();
      });

      test('should create container for development environment', () {
        // Act
        final container = DITestHelpers.createContainerForEnvironment(
            Environment.development);

        // Assert
        expect(container.isConfigured, isTrue);
        expect(() => container.getStoreProvider(), returnsNormally);

        // Cleanup
        container.dispose();
      });

      test('should create container for test environment', () {
        // Act
        final container =
            DITestHelpers.createContainerForEnvironment(Environment.test);

        // Assert
        expect(container.isConfigured, isTrue);
        expect(() => container.getStoreProvider(), returnsNormally);

        // Cleanup
        container.dispose();
      });
    });

    group('verifyContainerState', () {
      test('should pass verification for properly configured container', () {
        // Arrange
        final container = DITestHelpers.createTestContainer();

        // Act & Assert
        expect(() => DITestHelpers.verifyContainerState(container),
            returnsNormally);

        // Cleanup
        container.dispose();
      });

      test('should fail verification for unconfigured container', () {
        // Arrange
        final container = AppDIContainer();

        // Act & Assert
        expect(() => DITestHelpers.verifyContainerState(container),
            throwsA(isA<TestFailure>()));

        // Cleanup
        container.dispose();
      });
    });

    group('verifyServiceInstances', () {
      test('should verify service instances are valid', () {
        // Arrange
        final container = DITestHelpers.createTestContainer();

        // Act & Assert
        expect(() => DITestHelpers.verifyServiceInstances(container),
            returnsNormally);

        // Cleanup
        container.dispose();
      });
    });

    group('verifyUnconfiguredContainerBehavior', () {
      test('should verify unconfigured container throws exceptions', () {
        // Act & Assert
        expect(() => DITestHelpers.verifyUnconfiguredContainerBehavior(),
            returnsNormally);
      });
    });

    group('verifyContainerDisposal', () {
      test('should verify container disposal works correctly', () {
        // Arrange
        final container = DITestHelpers.createTestContainer();

        // Act & Assert
        expect(() => DITestHelpers.verifyContainerDisposal(container),
            returnsNormally);
      });
    });

    group('setupStandardTest', () {
      test('should create and verify standard test container', () {
        // Act
        final container = DITestHelpers.setupStandardTest();

        // Assert
        expect(container, isA<DIContainerInterface>());
        expect(container.isConfigured, isTrue);

        // Cleanup
        container.dispose();
      });
    });

    group('verifyPerformance', () {
      test('should verify service resolution performance', () {
        // Arrange
        final container = DITestHelpers.createTestContainer();

        // Act & Assert
        expect(() => DITestHelpers.verifyPerformance(container, iterations: 10),
            returnsNormally);

        // Cleanup
        container.dispose();
      });

      test('should handle custom iteration counts', () {
        // Arrange
        final container = DITestHelpers.createTestContainer();

        // Act & Assert
        expect(() => DITestHelpers.verifyPerformance(container, iterations: 5),
            returnsNormally);
        expect(() => DITestHelpers.verifyPerformance(container, iterations: 20),
            returnsNormally);

        // Cleanup
        container.dispose();
      });
    });

    group('Integration with existing DI tests', () {
      test('should work with standard test workflow', () {
        late DIContainerInterface container;

        // Setup
        container = DITestHelpers.setupStandardTest();

        // Use container in test
        final provider = container.getStoreProvider();
        final service = container.getLocationService();

        expect(provider, isNotNull);
        expect(service, isNotNull);

        // Cleanup
        container.dispose();
      });

      test('should support multiple environment testing', () {
        final environments = [
          Environment.production,
          Environment.development,
          Environment.test
        ];

        for (final env in environments) {
          final container = DITestHelpers.createContainerForEnvironment(env);
          DITestHelpers.verifyContainerState(container);
          container.dispose();
        }
      });
    });
  });
}
