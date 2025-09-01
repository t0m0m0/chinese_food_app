import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/di/di_container_interface.dart';
import 'package:chinese_food_app/core/di/di_container_factory.dart';
import 'package:chinese_food_app/core/di/containers/production_di_container.dart';
import 'package:chinese_food_app/core/di/containers/development_di_container.dart';
import 'package:chinese_food_app/core/di/containers/test_di_container.dart';

void main() {
  group('DIContainerFactory', () {
    test('should create ProductionDIContainer for production environment', () {
      // 🔴 Red: DIContainerFactory クラスがまだ存在しないため失敗する
      final container = DIContainerFactory.create(Environment.production);

      expect(container, isA<ProductionDIContainer>());
      expect(container, isA<DIContainerInterface>());
    });

    test('should create DevelopmentDIContainer for development environment',
        () {
      final container = DIContainerFactory.create(Environment.development);

      expect(container, isA<DevelopmentDIContainer>());
      expect(container, isA<DIContainerInterface>());
    });

    test('should create TestDIContainer for test environment', () {
      final container = DIContainerFactory.create(Environment.test);

      expect(container, isA<TestDIContainer>());
      expect(container, isA<DIContainerInterface>());
    });

    test('should create and configure container in one call', () {
      final container = DIContainerFactory.createAndConfigure(Environment.test);

      expect(container.isConfigured, isTrue);
      expect(container, isA<TestDIContainer>());
    });

    test('should provide default environment detection', () {
      // デフォルト環境の自動判定をテスト
      final container = DIContainerFactory.createDefault();

      expect(container, isA<DIContainerInterface>());
      // flutter.test環境でないため、development環境が返される
      expect(container, isA<DevelopmentDIContainer>());
    });
  });
}
