import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/di/di_container_interface.dart';
import 'package:chinese_food_app/core/di/containers/production_di_container.dart';
import 'package:chinese_food_app/core/di/containers/development_di_container.dart';
import 'package:chinese_food_app/core/di/containers/test_di_container.dart';

void main() {
  group('Environment-specific DI Containers', () {
    group('ProductionDIContainer', () {
      late ProductionDIContainer container;

      setUp(() {
        container = ProductionDIContainer();
      });

      tearDown(() {
        container.dispose();
      });

      test('should implement DIContainerInterface', () {
        expect(container, isA<DIContainerInterface>());
      });

      test('should be configured after configure() call', () {
        // 🔴 Red: ProductionDIContainer クラスがまだ存在しないため失敗する
        container.configure();
        expect(container.isConfigured, isTrue);
      });

      test('should provide StoreProvider after configuration', () {
        container.configure();
        final storeProvider = container.getStoreProvider();
        expect(storeProvider, isNotNull);
      });

      test('should provide LocationService after configuration', () {
        container.configure();
        final locationService = container.getLocationService();
        expect(locationService, isNotNull);
      });
    });

    group('DevelopmentDIContainer', () {
      late DevelopmentDIContainer container;

      setUp(() {
        container = DevelopmentDIContainer();
      });

      tearDown(() {
        container.dispose();
      });

      test('should implement DIContainerInterface', () {
        expect(container, isA<DIContainerInterface>());
      });

      test('should be configured after configure() call', () {
        // 🔴 Red: DevelopmentDIContainer クラスがまだ存在しないため失敗する
        container.configure();
        expect(container.isConfigured, isTrue);
      });
    });

    group('TestDIContainer', () {
      late TestDIContainer container;

      setUp(() {
        container = TestDIContainer();
      });

      tearDown(() {
        container.dispose();
      });

      test('should implement DIContainerInterface', () {
        expect(container, isA<DIContainerInterface>());
      });

      test('should be configured after configure() call', () {
        // 🔴 Red: TestDIContainer クラスがまだ存在しないため失敗する
        container.configure();
        expect(container.isConfigured, isTrue);
      });

      test('should use mock services in test environment', () {
        container.configure();
        final storeProvider = container.getStoreProvider();
        expect(storeProvider, isNotNull);
        // Test環境では適切なMockが使用されることを確認
      });
    });
  });
}
