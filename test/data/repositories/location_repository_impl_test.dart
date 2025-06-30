import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/data/repositories/location_repository_impl.dart';
import 'package:chinese_food_app/domain/repositories/location_repository.dart';
import 'package:chinese_food_app/domain/strategies/location_strategy.dart';
import 'package:chinese_food_app/domain/entities/location.dart';
import 'package:chinese_food_app/core/types/result.dart';
import 'package:chinese_food_app/core/exceptions/domain_exceptions.dart'
    as domain;

void main() {
  group('LocationRepositoryImpl', () {
    late LocationRepositoryImpl repository;
    late MockLocationStrategy mockStrategy;

    setUp(() {
      mockStrategy = MockLocationStrategy();
      repository = LocationRepositoryImpl(mockStrategy);
    });

    group('Interface Compliance', () {
      test('should implement LocationRepository interface', () {
        // Assert
        expect(repository, isA<LocationRepository>());
      });

      test('should return Future<Result<Location>> from getCurrentLocation',
          () {
        // Arrange
        mockStrategy.setMockResult(Success(Location(
          latitude: 35.6762,
          longitude: 139.6503,
          timestamp: DateTime.now(),
        )));

        // Act
        final result = repository.getCurrentLocation();

        // Assert
        expect(result, isA<Future<Result<Location>>>());
      });
    });

    group('Strategy Delegation', () {
      test('should delegate getCurrentLocation to strategy', () async {
        // Arrange
        final expectedLocation = Location(
          latitude: 35.6762,
          longitude: 139.6503,
          accuracy: 5.0,
          timestamp: DateTime.now(),
        );
        mockStrategy.setMockResult(Success(expectedLocation));

        // Act
        await repository.getCurrentLocation();

        // Assert
        expect(mockStrategy.getCurrentLocationCalled, isTrue);
      });

      test('should return success result from strategy', () async {
        // Arrange
        final expectedLocation = Location(
          latitude: 35.6762,
          longitude: 139.6503,
          accuracy: 5.0,
          timestamp: DateTime.now(),
        );
        mockStrategy.setMockResult(Success(expectedLocation));

        // Act
        final result = await repository.getCurrentLocation();

        // Assert
        expect(result, isA<Success<Location>>());
        final success = result as Success<Location>;
        expect(success.data.latitude, equals(expectedLocation.latitude));
        expect(success.data.longitude, equals(expectedLocation.longitude));
        expect(success.data.accuracy, equals(expectedLocation.accuracy));
      });

      test('should return failure result from strategy', () async {
        // Arrange
        final exception = domain.LocationException(
          'Location access denied',
          reason: domain.LocationExceptionReason.permissionDenied,
        );
        mockStrategy.setMockResult(Failure(exception));

        // Act
        final result = await repository.getCurrentLocation();

        // Assert
        expect(result, isA<Failure<Location>>());
        final failure = result as Failure<Location>;
        expect(failure.exception, equals(exception));
      });

      test('should preserve all data from strategy result', () async {
        // Arrange
        final testLocation = Location(
          latitude: -34.6037,
          longitude: -58.3816,
          accuracy: 10.5,
          timestamp: DateTime.parse('2023-01-01T12:00:00Z'),
        );
        mockStrategy.setMockResult(Success(testLocation));

        // Act
        final result = await repository.getCurrentLocation();

        // Assert
        expect(result, isA<Success<Location>>());
        final success = result as Success<Location>;
        final location = success.data;

        expect(location.latitude, equals(-34.6037));
        expect(location.longitude, equals(-58.3816));
        expect(location.accuracy, equals(10.5));
        expect(
            location.timestamp, equals(DateTime.parse('2023-01-01T12:00:00Z')));
      });
    });

    group('Error Handling', () {
      test('should handle different exception types from strategy', () async {
        // Arrange
        final testCases = [
          domain.LocationException(
            'Permission denied',
            reason: domain.LocationExceptionReason.permissionDenied,
          ),
          domain.LocationException(
            'Service disabled',
            reason: domain.LocationExceptionReason.serviceDisabled,
          ),
          domain.LocationException(
            'Timeout',
            reason: domain.LocationExceptionReason.timeout,
          ),
          domain.LocationException(
            'Unknown error',
            reason: domain.LocationExceptionReason.unknown,
          ),
        ];

        for (final testException in testCases) {
          // Arrange
          mockStrategy.setMockResult(Failure(testException));

          // Act
          final result = await repository.getCurrentLocation();

          // Assert
          expect(result, isA<Failure<Location>>());
          final failure = result as Failure<Location>;
          expect(failure.exception, equals(testException));
          expect((failure.exception as domain.LocationException).reason,
              equals(testException.reason));
        }
      });

      test('should preserve exception hierarchy from strategy', () async {
        // Arrange
        final locationException = domain.LocationException('Location error');
        mockStrategy.setMockResult(Failure(locationException));

        // Act
        final result = await repository.getCurrentLocation();

        // Assert
        expect(result, isA<Failure<Location>>());
        final failure = result as Failure<Location>;
        expect(failure.exception, isA<domain.LocationException>());
        expect(failure.exception.message, equals('Location error'));
      });
    });

    group('Strategy Switching', () {
      test('should work with different strategy implementations', () async {
        // Arrange
        final strategy1 = _MockLocationStrategy1();
        final strategy2 = _MockLocationStrategy2();
        final repository1 = LocationRepositoryImpl(strategy1);
        final repository2 = LocationRepositoryImpl(strategy2);

        // Act
        final result1 = await repository1.getCurrentLocation();
        final result2 = await repository2.getCurrentLocation();

        // Assert
        expect(result1, isA<Success<Location>>());
        expect(result2, isA<Success<Location>>());

        final location1 = (result1 as Success<Location>).data;
        final location2 = (result2 as Success<Location>).data;

        // Results should be different based on strategy
        expect(location1.latitude, isNot(equals(location2.latitude)));
      });

      test('should maintain consistent interface across strategies', () async {
        // Arrange
        final strategies = [
          _MockLocationStrategy1(),
          _MockLocationStrategy2(),
          _FailingMockStrategy(),
        ];

        for (final strategy in strategies) {
          // Act
          final repository = LocationRepositoryImpl(strategy);
          final result = await repository.getCurrentLocation();

          // Assert
          expect(result, isA<Result<Location>>());
        }
      });
    });

    group('Performance and Concurrency', () {
      test('should handle multiple concurrent calls', () async {
        // Arrange
        final location = Location(
          latitude: 35.6762,
          longitude: 139.6503,
          timestamp: DateTime.now(),
        );
        mockStrategy.setMockResult(Success(location));

        // Act
        final futures = List.generate(
          5,
          (_) => repository.getCurrentLocation(),
        );
        final results = await Future.wait(futures);

        // Assert
        expect(results, hasLength(5));
        for (final result in results) {
          expect(result, isA<Success<Location>>());
        }
        expect(mockStrategy.getCurrentLocationCallCount, equals(5));
      });

      test('should be stateless between calls', () async {
        // Arrange
        final location1 = Location(
          latitude: 35.6762,
          longitude: 139.6503,
          timestamp: DateTime.now(),
        );
        final location2 = Location(
          latitude: 35.6895,
          longitude: 139.6917,
          timestamp: DateTime.now(),
        );

        // Act & Assert
        mockStrategy.setMockResult(Success(location1));
        final result1 = await repository.getCurrentLocation();
        expect((result1 as Success<Location>).data.latitude, equals(35.6762));

        mockStrategy.setMockResult(Success(location2));
        final result2 = await repository.getCurrentLocation();
        expect((result2 as Success<Location>).data.latitude, equals(35.6895));
      });

      test('should complete within reasonable time', () async {
        // Arrange
        final location = Location(
          latitude: 35.6762,
          longitude: 139.6503,
          timestamp: DateTime.now(),
        );
        mockStrategy.setMockResult(Success(location));

        // Act
        final stopwatch = Stopwatch()..start();
        await repository.getCurrentLocation();
        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });

    group('Edge Cases', () {
      test('should handle null accuracy from strategy', () async {
        // Arrange
        final location = Location(
          latitude: 35.6762,
          longitude: 139.6503,
          accuracy: null,
          timestamp: DateTime.now(),
        );
        mockStrategy.setMockResult(Success(location));

        // Act
        final result = await repository.getCurrentLocation();

        // Assert
        expect(result, isA<Success<Location>>());
        final success = result as Success<Location>;
        expect(success.data.accuracy, isNull);
      });

      test('should handle extreme coordinate values from strategy', () async {
        // Arrange
        final testCases = [
          Location(latitude: 0.0, longitude: 0.0, timestamp: DateTime.now()),
          Location(latitude: 90.0, longitude: 180.0, timestamp: DateTime.now()),
          Location(
              latitude: -90.0, longitude: -180.0, timestamp: DateTime.now()),
        ];

        for (final testLocation in testCases) {
          // Arrange
          mockStrategy.setMockResult(Success(testLocation));

          // Act
          final result = await repository.getCurrentLocation();

          // Assert
          expect(result, isA<Success<Location>>());
          final success = result as Success<Location>;
          expect(success.data.latitude, equals(testLocation.latitude));
          expect(success.data.longitude, equals(testLocation.longitude));
        }
      });
    });
  });
}

// Mock implementations for testing

class MockLocationStrategy implements LocationStrategy {
  Result<Location>? _mockResult;
  bool getCurrentLocationCalled = false;
  int getCurrentLocationCallCount = 0;

  void setMockResult(Result<Location> result) {
    _mockResult = result;
  }

  @override
  Future<Result<Location>> getCurrentLocation() async {
    getCurrentLocationCalled = true;
    getCurrentLocationCallCount++;

    if (_mockResult == null) {
      throw StateError('Mock result not set');
    }

    return _mockResult!;
  }

  @override
  Future<Result<bool>> hasLocationPermission() async {
    return const Success(true);
  }

  @override
  Future<Result<bool>> requestLocationPermission() async {
    return const Success(true);
  }

  @override
  Future<Result<bool>> isLocationServiceEnabled() async {
    return const Success(true);
  }
}

class _MockLocationStrategy1 implements LocationStrategy {
  @override
  Future<Result<Location>> getCurrentLocation() async {
    return Success(Location(
      latitude: 35.6762,
      longitude: 139.6503,
      timestamp: DateTime.now(),
    ));
  }

  @override
  Future<Result<bool>> hasLocationPermission() async {
    return const Success(true);
  }

  @override
  Future<Result<bool>> requestLocationPermission() async {
    return const Success(true);
  }

  @override
  Future<Result<bool>> isLocationServiceEnabled() async {
    return const Success(true);
  }
}

class _MockLocationStrategy2 implements LocationStrategy {
  @override
  Future<Result<Location>> getCurrentLocation() async {
    return Success(Location(
      latitude: 35.6895,
      longitude: 139.6917,
      timestamp: DateTime.now(),
    ));
  }

  @override
  Future<Result<bool>> hasLocationPermission() async {
    return const Success(true);
  }

  @override
  Future<Result<bool>> requestLocationPermission() async {
    return const Success(true);
  }

  @override
  Future<Result<bool>> isLocationServiceEnabled() async {
    return const Success(true);
  }
}

class _FailingMockStrategy implements LocationStrategy {
  @override
  Future<Result<Location>> getCurrentLocation() async {
    return Failure(domain.LocationException('Mock strategy failure'));
  }

  @override
  Future<Result<bool>> hasLocationPermission() async {
    return const Success(false);
  }

  @override
  Future<Result<bool>> requestLocationPermission() async {
    return const Success(false);
  }

  @override
  Future<Result<bool>> isLocationServiceEnabled() async {
    return const Success(false);
  }
}
