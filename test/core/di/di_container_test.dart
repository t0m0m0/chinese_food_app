import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/di/service_container.dart';

void main() {
  group('ServiceContainer', () {
    test('should have a register method', () {
      // Arrange
      final container = ServiceContainer();
      
      // Act & Assert
      expect(() => container.register<TestService>(() => TestService()), 
             returnsNormally);
    });

    test('should have a resolve method', () {
      // Arrange
      final container = ServiceContainer();
      container.register<TestService>(() => TestService());
      
      // Act & Assert
      expect(() => container.resolve<TestService>(), 
             returnsNormally);
    });

    test('should register and resolve a simple service', () {
      // Arrange
      final container = ServiceContainer();
      container.register<TestService>(() => TestService());
      
      // Act
      final result = container.resolve<TestService>();
      
      // Assert
      expect(result, isA<TestService>());
      expect(result.message, equals('test'));
    });

    test('should register and resolve different services', () {
      // Arrange
      final container = ServiceContainer();
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
  });
}

class TestService {
  final String message = 'test';
}

class AnotherService {
  final int value = 42;
}

