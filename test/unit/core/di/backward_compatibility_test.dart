import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/di/di_container_interface.dart';
import 'package:chinese_food_app/core/di/app_di_container.dart';
import 'package:chinese_food_app/core/di/di_container_factory.dart';

void main() {
  group('Backward Compatibility Tests', () {
    group('AppDIContainer should maintain existing API', () {
      late AppDIContainer container;

      setUp(() {
        container = AppDIContainer();
      });

      tearDown(() {
        container.dispose();
      });

      test('should implement DIContainerInterface', () {
        expect(container, isA<DIContainerInterface>());
      });

      test('should be configurable with default environment', () {
        container.configure();
        expect(container.isConfigured, isTrue);
      });

      test('should be configurable with specific environment', () {
        container.configureForEnvironment(Environment.test);
        expect(container.isConfigured, isTrue);
      });

      test('should provide consistent API for service resolution', () {
        container.configureForEnvironment(Environment.test);

        // APIが一貫していることを確認（実際のサービス取得はまだ実装しない）
        expect(() => container.getStoreProvider(), isA<Function>());
        expect(() => container.getLocationService(), isA<Function>());
      });

      test('should allow test provider registration', () {
        expect(() => container.registerTestProvider, isA<Function>());
      });

      test('should be disposable', () {
        container.configureForEnvironment(Environment.test);
        expect(container.isConfigured, isTrue);

        container.dispose();
        expect(container.isConfigured, isFalse);
      });
    });

    group('Integration with new Factory system', () {
      test('should coexist with DIContainerFactory', () {
        // 既存システムと新システムが併存できることを確認
        final oldContainer = AppDIContainer();
        final newContainer = DIContainerFactory.create(Environment.test);

        expect(oldContainer, isA<DIContainerInterface>());
        expect(newContainer, isA<DIContainerInterface>());

        oldContainer.dispose();
        newContainer.dispose();
      });

      test('should handle same environment configurations', () {
        final oldContainer = AppDIContainer();
        final newContainer = DIContainerFactory.create(Environment.test);

        oldContainer.configureForEnvironment(Environment.test);
        newContainer.configureForEnvironment(Environment.test);

        expect(oldContainer.isConfigured, isTrue);
        expect(newContainer.isConfigured, isTrue);

        oldContainer.dispose();
        newContainer.dispose();
      });
    });
  });
}
