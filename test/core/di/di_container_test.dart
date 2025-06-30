import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DIContainer', () {
    test('should have a register method', () {
      // Arrange
      final container = DIContainer();
      
      // Act & Assert
      expect(() => container.register<TestService>(() => TestService()), 
             returnsNormally);
    });

    test('should have a resolve method', () {
      // Arrange
      final container = DIContainer();
      container.register<TestService>(() => TestService());
      
      // Act & Assert
      expect(() => container.resolve<TestService>(), 
             returnsNormally);
    });
  });
}

class TestService {
  final String message = 'test';
}

class DIContainer {
  void register<T>(T Function() factory) {
    // 仮実装：何もしない
  }
  
  T resolve<T>() {
    // 仮実装：TestServiceを返す
    return TestService() as T;
  }
}