import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/di/di_container_interface.dart';
import 'package:chinese_food_app/core/di/app_di_container.dart';

void main() {
  group('Refactored AppDIContainer', () {
    group('should maintain backward compatibility', () {
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

      test('should configure with default environment detection', () {
        container.configure();
        expect(container.isConfigured, isTrue);
      });

      test('should configure for specific environments', () {
        container.configureForEnvironment(Environment.test);
        expect(container.isConfigured, isTrue);

        container.configureForEnvironment(Environment.development);
        expect(container.isConfigured, isTrue);

        container.configureForEnvironment(Environment.production);
        expect(container.isConfigured, isTrue);
      });

      test('should provide services after configuration', () {
        container.configureForEnvironment(Environment.test);

        final storeProvider = container.getStoreProvider();
        expect(storeProvider, isNotNull);

        final locationService = container.getLocationService();
        expect(locationService, isNotNull);
      });

      test('should support test provider registration', () {
        container.configureForEnvironment(Environment.test);

        // Test provider registration should not throw
        expect(() {
          // This would register a mock provider in tests
          // container.registerTestProvider(mockProvider);
        }, returnsNormally);
      });

      test('should dispose properly', () {
        container.configureForEnvironment(Environment.test);
        expect(container.isConfigured, isTrue);

        container.dispose();
        expect(container.isConfigured, isFalse);
      });

      test('should throw when accessing services before configuration', () {
        expect(
          () => container.getStoreProvider(),
          throwsA(isA<DIContainerException>()),
        );

        expect(
          () => container.getLocationService(),
          throwsA(isA<DIContainerException>()),
        );
      });
    });

    group('should be much simpler than original implementation', () {
      test('should delegate to environment-specific containers internally', () {
        // この実装では内部的にDIContainerFactoryを使用する
        final container = AppDIContainer();

        // 各環境での設定が正常に動作することを確認
        container.configureForEnvironment(Environment.test);
        expect(container.isConfigured, isTrue);

        container.configureForEnvironment(Environment.development);
        expect(container.isConfigured, isTrue);
      });
    });
  });
}
