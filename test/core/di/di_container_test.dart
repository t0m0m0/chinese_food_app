import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/di/service_container.dart';

void main() {
  group('ServiceContainer', () {
    late ServiceContainer container;

    setUp(() {
      container = ServiceContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should have a register method', () {
      // Arrange
      // container already initialized in setUp

      // Act & Assert
      expect(() => container.register<TestService>(() => TestService()),
          returnsNormally);
    });

    test('should have a resolve method', () {
      // Arrange
      container.register<TestService>(() => TestService());

      // Act & Assert
      expect(() => container.resolve<TestService>(), returnsNormally);
    });

    test('should register and resolve a simple service', () {
      // Arrange
      container.register<TestService>(() => TestService());

      // Act
      final result = container.resolve<TestService>();

      // Assert
      expect(result, isA<TestService>());
      expect(result.message, equals('test'));
    });

    test('should register and resolve different services', () {
      // Arrange
      container.register<TestService>(() => TestService());
      container.register<AnotherService>(() => AnotherService());

      // Act
      final testService = container.resolve<TestService>();
      final anotherService = container.resolve<AnotherService>();

      // Assert
      expect(testService, isA<TestService>());
      expect(anotherService, isA<AnotherService>());
      expect(testService.message, equals('test'));
      expect(anotherService.value, equals(42));
    });

    test('should register as singleton and return same instance', () {
      // Arrange
      container.registerSingleton<TestService>(() => TestService());

      // Act
      final instance1 = container.resolve<TestService>();
      final instance2 = container.resolve<TestService>();

      // Assert
      expect(identical(instance1, instance2), isTrue);
    });

    test('should register as transient and return different instances', () {
      // Arrange
      container.register<TestService>(() => TestService());

      // Act
      final instance1 = container.resolve<TestService>();
      final instance2 = container.resolve<TestService>();

      // Assert
      expect(identical(instance1, instance2), isFalse);
    });

    group('Error Handling', () {
      test(
          'should throw ServiceContainerException when resolving unregistered service',
          () {
        final container = ServiceContainer();

        expect(
          () => container.resolve<TestService>(),
          throwsA(isA<ServiceContainerException>().having(
            (e) => e.message,
            'message',
            contains('Service of type TestService is not registered'),
          )),
        );
      });

      test('should handle multiple unregistered services', () {
        final container = ServiceContainer();

        expect(() => container.resolve<TestService>(),
            throwsA(isA<ServiceContainerException>()));
        expect(() => container.resolve<AnotherService>(),
            throwsA(isA<ServiceContainerException>()));
      });
    });

    group('Service Registration Check', () {
      test('should correctly identify registered services', () {
        final container = ServiceContainer();
        container.register<TestService>(() => TestService());

        expect(container.isRegistered<TestService>(), isTrue);
        expect(container.isRegistered<AnotherService>(), isFalse);
      });

      test('should identify singleton services as registered', () {
        final container = ServiceContainer();
        container.registerSingleton<TestService>(() => TestService());

        expect(container.isRegistered<TestService>(), isTrue);
      });
    });

    group('Memory Management', () {
      test('should clear singleton instances when dispose is called', () {
        final container = ServiceContainer();
        container.registerSingleton<TestService>(() => TestService());

        final instance1 = container.resolve<TestService>();
        container.dispose();

        // After dispose, should create new instance
        final instance2 = container.resolve<TestService>();
        expect(identical(instance1, instance2), isFalse);
      });

      test('should clear specific singleton instance', () {
        final container = ServiceContainer();
        container.registerSingleton<TestService>(() => TestService());
        container.registerSingleton<AnotherService>(() => AnotherService());

        final testInstance1 = container.resolve<TestService>();
        final anotherInstance1 = container.resolve<AnotherService>();

        container.clearSingleton<TestService>();

        final testInstance2 = container.resolve<TestService>();
        final anotherInstance2 = container.resolve<AnotherService>();

        // TestService should be new instance, AnotherService should be same
        expect(identical(testInstance1, testInstance2), isFalse);
        expect(identical(anotherInstance1, anotherInstance2), isTrue);
      });
    });
  });
}

class TestService {
  final String message = 'test';
}

class AnotherService {
  final int value = 42;
}
