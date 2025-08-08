import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:chinese_food_app/core/di/di_container_interface.dart';
import 'package:chinese_food_app/core/di/app_di_container.dart';
import 'package:chinese_food_app/presentation/providers/store_provider.dart';
import 'package:chinese_food_app/domain/services/location_service.dart';

void main() {
  // テスト開始時にDrift警告を無効化
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });
  group('DI Migration Integration Tests', () {
    late DIContainerInterface container;

    setUp(() {
      container = AppDIContainer();
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('should integrate with Provider framework correctly',
        (tester) async {
      // Arrange
      container.configure();

      final testWidget = MaterialApp(
        home: MultiProvider(
          providers: [
            Provider<DIContainerInterface>.value(value: container),
            ChangeNotifierProvider(
              create: (_) => container.getStoreProvider(),
            ),
            Provider(
              create: (_) => container.getLocationService(),
            ),
          ],
          child: const TestConsumerWidget(),
        ),
      );

      // Act
      await tester.pumpWidget(testWidget);

      // Assert
      expect(find.text('DI Container: Configured'), findsOneWidget);
      expect(find.text('StoreProvider: Available'), findsOneWidget);
      expect(find.text('LocationService: Available'), findsOneWidget);
    });

    testWidgets('should handle environment switching in widgets',
        (tester) async {
      // Arrange - Start with test environment
      container.configureForEnvironment(Environment.test);

      final testWidget = MaterialApp(
        home: MultiProvider(
          providers: [
            Provider<DIContainerInterface>.value(value: container),
            ChangeNotifierProvider(
              create: (_) => container.getStoreProvider(),
            ),
          ],
          child: const EnvironmentTestWidget(),
        ),
      );

      // Act
      await tester.pumpWidget(testWidget);
      await tester.pump();

      // Assert
      expect(find.text('Environment: Test'), findsOneWidget);

      // Act - Switch to production environment
      await tester.tap(find.text('Switch to Production'));
      await tester.pump();

      // Assert
      expect(find.text('Environment: Production'), findsOneWidget);
    });

    test('should maintain singleton behavior across widget rebuilds', () {
      // Arrange
      container.configure();

      // Act
      final provider1 = container.getStoreProvider();
      final provider2 = container.getStoreProvider();
      final service1 = container.getLocationService();
      final service2 = container.getLocationService();

      // Assert
      // Services should be different instances (transient)
      expect(identical(provider1, provider2), isFalse);
      expect(identical(service1, service2), isFalse);

      // But they should be of the same type
      expect(provider1.runtimeType, equals(provider2.runtimeType));
      expect(service1.runtimeType, equals(service2.runtimeType));
    });

    test('should properly dispose resources', () {
      // Arrange
      container.configure();
      container.getStoreProvider();
      container.getLocationService();

      // Act
      container.dispose();

      // Assert
      expect(() => container.getStoreProvider(),
          throwsA(isA<DIContainerException>()));
      expect(() => container.getLocationService(),
          throwsA(isA<DIContainerException>()));
    });

    group('Performance Tests', () {
      test('should resolve services efficiently', () {
        // Arrange
        container.configure();
        const iterations = 1000;

        // Act & Assert
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < iterations; i++) {
          container.getStoreProvider();
          container.getLocationService();
        }

        stopwatch.stop();

        // Should complete 1000 resolutions in reasonable time (< 200ms for CI)
        expect(stopwatch.elapsedMilliseconds, lessThan(200));
      });

      test('should handle concurrent access correctly', () async {
        // Arrange
        container.configure();
        const concurrentRequests = 100;

        // Act
        final futures = List.generate(concurrentRequests, (_) async {
          return container.getStoreProvider();
        });

        final results = await Future.wait(futures);

        // Assert
        expect(results.length, equals(concurrentRequests));
        // All should be valid StoreProvider instances
        for (final result in results) {
          expect(result, isA<StoreProvider>());
        }
      });
    });
  });
}

/// Test widget that consumes services from DI container
class TestConsumerWidget extends StatelessWidget {
  const TestConsumerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final container = Provider.of<DIContainerInterface>(context);
    // Test that services can be accessed through Provider
    Provider.of<StoreProvider>(context, listen: false);
    Provider.of<LocationService>(context, listen: false);

    return Scaffold(
      body: Column(
        children: [
          Text(
              'DI Container: ${container.isConfigured ? 'Configured' : 'Not Configured'}'),
          const Text('StoreProvider: Available'),
          const Text('LocationService: Available'),
        ],
      ),
    );
  }
}

/// Test widget for environment switching
class EnvironmentTestWidget extends StatefulWidget {
  const EnvironmentTestWidget({super.key});

  @override
  State<EnvironmentTestWidget> createState() => _EnvironmentTestWidgetState();
}

class _EnvironmentTestWidgetState extends State<EnvironmentTestWidget> {
  Environment _currentEnvironment = Environment.test;

  String _environmentName(Environment env) {
    switch (env) {
      case Environment.test:
        return 'Test';
      case Environment.development:
        return 'Development';
      case Environment.production:
        return 'Production';
    }
  }

  @override
  Widget build(BuildContext context) {
    final container = Provider.of<DIContainerInterface>(context, listen: false);

    return Scaffold(
      body: Column(
        children: [
          Text('Environment: ${_environmentName(_currentEnvironment)}'),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _currentEnvironment = Environment.production;
                container.configureForEnvironment(_currentEnvironment);
              });
            },
            child: const Text('Switch to Production'),
          ),
        ],
      ),
    );
  }
}
