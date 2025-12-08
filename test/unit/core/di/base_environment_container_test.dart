import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/di/containers/base_environment_container.dart';
import 'package:chinese_food_app/core/di/di_container_interface.dart';
import 'package:chinese_food_app/presentation/providers/store_provider.dart';
import 'package:chinese_food_app/domain/services/location_service.dart';
import 'package:chinese_food_app/domain/usecases/add_visit_record_usecase.dart';
import 'package:chinese_food_app/domain/usecases/get_visit_records_by_store_id_usecase.dart';

void main() {
  group('BaseEnvironmentContainer', () {
    group('Contract verification', () {
      test('should provide common implementation for environment containers',
          () {
        // Act
        final testContainer = _TestConcreteContainer(Environment.test);
        testContainer.configure();

        // Assert
        expect(testContainer.isConfigured, isTrue);
      });

      test('should throw when configuring for wrong environment', () {
        // Arrange
        final testContainer = _TestConcreteContainer(Environment.test);

        // Act & Assert
        expect(
          () => testContainer.configureForEnvironment(Environment.production),
          throwsA(isA<DIContainerException>()),
        );
      });

      test('should provide services after configuration', () {
        // Arrange
        final container = _TestConcreteContainer(Environment.test);
        container.configure();

        // Act & Assert
        expect(() => container.getStoreProvider(), returnsNormally);
        expect(() => container.getLocationService(), returnsNormally);
        expect(() => container.getAddVisitRecordUsecase(), returnsNormally);
        expect(
            () => container.getGetVisitRecordsByStoreIdUsecase(), returnsNormally);
      });

      test('should throw when accessing services before configuration', () {
        // Arrange
        final container = _TestConcreteContainer(Environment.test);

        // Act & Assert
        expect(
          () => container.getStoreProvider(),
          throwsA(isA<DIContainerException>()),
        );
      });

      test('should dispose resources correctly', () {
        // Arrange
        final container = _TestConcreteContainer(Environment.test);
        container.configure();

        // Act
        container.dispose();

        // Assert
        expect(container.isConfigured, isFalse);
      });
    });

    group('Environment-specific behavior', () {
      test('TestEnvironmentContainer should allow registerTestProvider', () {
        // Arrange
        final container = _TestConcreteContainer(Environment.test);
        container.configure();
        final mockProvider = container.getStoreProvider();

        // Act & Assert - should not throw
        expect(
            () => container.registerTestProvider(mockProvider), returnsNormally);
      });

      test('ProductionEnvironmentContainer should reject registerTestProvider',
          () {
        // Arrange
        final container = _ProductionConcreteContainer();
        container.configure();
        final mockProvider = container.getStoreProvider();

        // Act & Assert
        expect(
          () => container.registerTestProvider(mockProvider),
          throwsA(isA<DIContainerException>()),
        );
      });
    });
  });
}

/// Test concrete implementation of BaseEnvironmentContainer
class _TestConcreteContainer extends BaseEnvironmentContainer {
  _TestConcreteContainer(super.environment);

  @override
  void registerEnvironmentSpecificServices() {
    // Test environment doesn't need additional services
  }

  @override
  bool get allowsTestProviderRegistration => true;
}

/// Production concrete implementation for testing
class _ProductionConcreteContainer extends BaseEnvironmentContainer {
  _ProductionConcreteContainer() : super(Environment.production);

  @override
  void registerEnvironmentSpecificServices() {
    // Production environment doesn't need additional services for test
  }

  @override
  bool get allowsTestProviderRegistration => false;
}
