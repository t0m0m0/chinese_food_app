import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/di/di_container_interface.dart';
import 'package:chinese_food_app/core/di/app_di_container.dart';
import 'package:chinese_food_app/presentation/providers/store_provider.dart';
import 'package:chinese_food_app/domain/services/location_service.dart';
import 'package:chinese_food_app/domain/repositories/store_repository.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/domain/entities/location.dart';

void main() {
  group('DIContainerInterface', () {
    late DIContainerInterface diContainer;

    setUp(() {
      diContainer = AppDIContainer();
    });

    tearDown(() {
      diContainer.dispose();
    });

    test('should have configure method for setup', () {
      // Act & Assert
      expect(() => diContainer.configure(), returnsNormally);
    });

    test('should create StoreProvider after configuration', () {
      // Arrange
      diContainer.configure();

      // Act
      final provider = diContainer.getStoreProvider();

      // Assert
      expect(provider, isA<StoreProvider>());
    });

    test('should create LocationService after configuration', () {
      // Arrange
      diContainer.configure();

      // Act
      final service = diContainer.getLocationService();

      // Assert
      expect(service, isA<LocationService>());
    });

    test('should support environment-specific configuration', () {
      // Arrange & Act
      diContainer.configureForEnvironment(Environment.test);
      final provider = diContainer.getStoreProvider();

      // Assert
      expect(provider, isA<StoreProvider>());
      // Should use mock datasources in test environment
    });

    test('should throw exception when accessing unconfigured services', () {
      // Act & Assert
      expect(
        () => diContainer.getStoreProvider(),
        throwsA(isA<DIContainerException>()),
      );
    });

    test('should be disposable for cleanup', () {
      // Arrange
      diContainer.configure();
      diContainer.getStoreProvider(); // Initialize services

      // Act & Assert
      expect(() => diContainer.dispose(), returnsNormally);
    });
  });

  group('AppDIContainer Integration', () {
    late AppDIContainer container;

    setUp(() {
      container = AppDIContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should configure dependencies correctly for production', () {
      // Act
      container.configureForEnvironment(Environment.production);
      final provider = container.getStoreProvider();

      // Assert
      expect(provider, isNotNull);
      // Note: Direct repository access was removed in new architecture
      // Instead, verify provider functionality through its public interface
      expect(provider.stores, isNotNull);
      expect(provider.isLoading, isFalse);
    });

    test('should configure dependencies correctly for test environment', () {
      // Act
      container.configureForEnvironment(Environment.test);
      final provider = container.getStoreProvider();

      // Assert
      expect(provider, isNotNull);
      // In test environment, should use mock implementations
    });

    test('should support service replacement for testing', () {
      // Arrange
      container.configure();
      final originalProvider = container.getStoreProvider();

      // Act
      final mockProvider = MockStoreProvider();
      container.registerTestProvider(mockProvider);
      final testProvider = container.getStoreProvider();

      // Assert
      expect(testProvider, equals(mockProvider));
      expect(testProvider, isNot(equals(originalProvider)));
    });
  });
}

// Test Mocks
class MockStoreProvider extends StoreProvider {
  MockStoreProvider()
      : super(
          repository: MockStoreRepository(),
          locationService: MockLocationService(),
        );
}

class MockLocationService implements LocationService {
  @override
  Future<Location> getCurrentLocation() async {
    return Location(
      latitude: 35.6917,
      longitude: 139.7006,
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<bool> hasLocationPermission() async => true;

  @override
  Future<bool> requestLocationPermission() async => true;
}

class MockStoreRepository implements StoreRepository {
  @override
  Future<void> deleteStore(String id) async {}

  @override
  Future<List<Store>> getAllStores() async => [];

  @override
  Future<Store?> getStoreById(String id) async => null;

  @override
  Future<List<Store>> getStoresByStatus(StoreStatus status) async => [];

  @override
  Future<List<Store>> searchStores(String query) async => [];

  @override
  Future<void> updateStore(Store store) async {}

  @override
  Future<void> insertStore(Store store) async {}

  @override
  Future<void> deleteAllStores() async {}

  @override
  Future<List<Store>> searchStoresFromApi({
    double? lat,
    double? lng,
    String? address,
    String? keyword,
    int range = 3,
    int count = 20,
    int start = 1,
  }) async =>
      [];
}
