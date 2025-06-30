import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/domain/usecases/location/get_current_location_usecase.dart';
import 'package:chinese_food_app/domain/usecases/base_usecase.dart';
import 'package:chinese_food_app/domain/repositories/location_repository.dart';
import 'package:chinese_food_app/domain/entities/location.dart';
import 'package:chinese_food_app/core/types/result.dart';
import 'package:chinese_food_app/core/exceptions/domain_exceptions.dart'
    as domain;

void main() {
  group('GetCurrentLocationUseCase', () {
    late GetCurrentLocationUseCase useCase;
    late MockLocationRepository mockRepository;

    setUp(() {
      mockRepository = MockLocationRepository();
      useCase = GetCurrentLocationUseCase(mockRepository);
    });

    group('Interface Compliance', () {
      test('should implement BaseUseCase interface', () {
        // Assert
        expect(useCase, isA<BaseUseCase<NoParams, Location>>());
      });

      test('should accept NoParams as input', () {
        // Act & Assert
        expect(() => useCase.call(const NoParams()), returnsNormally);
      });

      test('should return Future<Result<Location>>', () {
        // Arrange
        mockRepository.setMockResult(Success(Location(
          latitude: 35.6762,
          longitude: 139.6503,
          timestamp: DateTime.now(),
        )));

        // Act
        final result = useCase.call(const NoParams());

        // Assert
        expect(result, isA<Future<Result<Location>>>());
      });
    });

    group('Success Cases', () {
      test('should return location when repository succeeds', () async {
        // Arrange
        final expectedLocation = Location(
          latitude: 35.6762,
          longitude: 139.6503,
          accuracy: 5.0,
          timestamp: DateTime.now(),
        );
        mockRepository.setMockResult(Success(expectedLocation));

        // Act
        final result = await useCase.call(const NoParams());

        // Assert
        expect(result, isA<Success<Location>>());
        final success = result as Success<Location>;
        expect(success.data.latitude, equals(expectedLocation.latitude));
        expect(success.data.longitude, equals(expectedLocation.longitude));
        expect(success.data.accuracy, equals(expectedLocation.accuracy));
      });

      test('should call repository getCurrentLocation method', () async {
        // Arrange
        final location = Location(
          latitude: 35.6762,
          longitude: 139.6503,
          timestamp: DateTime.now(),
        );
        mockRepository.setMockResult(Success(location));

        // Act
        await useCase.call(const NoParams());

        // Assert
        expect(mockRepository.getCurrentLocationCalled, isTrue);
      });

      test('should handle different location data', () async {
        // Arrange
        final testCases = [
          Location(
            latitude: 0.0,
            longitude: 0.0,
            timestamp: DateTime.now(),
          ),
          Location(
            latitude: -90.0,
            longitude: -180.0,
            accuracy: 1.0,
            timestamp: DateTime.now(),
          ),
          Location(
            latitude: 90.0,
            longitude: 180.0,
            accuracy: 100.0,
            timestamp: DateTime.now(),
          ),
        ];

        for (final testLocation in testCases) {
          // Arrange
          mockRepository.setMockResult(Success(testLocation));

          // Act
          final result = await useCase.call(const NoParams());

          // Assert
          expect(result, isA<Success<Location>>());
          final success = result as Success<Location>;
          expect(success.data.latitude, equals(testLocation.latitude));
          expect(success.data.longitude, equals(testLocation.longitude));
        }
      });
    });

    group('Failure Cases', () {
      test('should return failure when repository fails', () async {
        // Arrange
        final exception = domain.LocationException(
          'Location access denied',
          reason: domain.LocationExceptionReason.permissionDenied,
        );
        mockRepository.setMockResult(Failure(exception));

        // Act
        final result = await useCase.call(const NoParams());

        // Assert
        expect(result, isA<Failure<Location>>());
        final failure = result as Failure<Location>;
        expect(failure.exception, equals(exception));
      });

      test('should handle different failure scenarios', () async {
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
          mockRepository.setMockResult(Failure(testException));

          // Act
          final result = await useCase.call(const NoParams());

          // Assert
          expect(result, isA<Failure<Location>>());
          final failure = result as Failure<Location>;
          expect(failure.exception, equals(testException));
          expect((failure.exception as domain.LocationException).reason,
              equals(testException.reason));
        }
      });

      test('should preserve exception hierarchy', () async {
        // Arrange
        final locationException = domain.LocationException('Location error');
        mockRepository.setMockResult(Failure(locationException));

        // Act
        final result = await useCase.call(const NoParams());

        // Assert
        expect(result, isA<Failure<Location>>());
        final failure = result as Failure<Location>;
        expect(failure.exception, isA<domain.LocationException>());
      });
    });

    group('Edge Cases', () {
      test('should handle null accuracy in location', () async {
        // Arrange
        final location = Location(
          latitude: 35.6762,
          longitude: 139.6503,
          accuracy: null, // null accuracy
          timestamp: DateTime.now(),
        );
        mockRepository.setMockResult(Success(location));

        // Act
        final result = await useCase.call(const NoParams());

        // Assert
        expect(result, isA<Success<Location>>());
        final success = result as Success<Location>;
        expect(success.data.accuracy, isNull);
      });

      test('should handle multiple consecutive calls', () async {
        // Arrange
        final location = Location(
          latitude: 35.6762,
          longitude: 139.6503,
          timestamp: DateTime.now(),
        );
        mockRepository.setMockResult(Success(location));

        // Act
        final result1 = await useCase.call(const NoParams());
        final result2 = await useCase.call(const NoParams());
        final result3 = await useCase.call(const NoParams());

        // Assert
        expect(result1, isA<Success<Location>>());
        expect(result2, isA<Success<Location>>());
        expect(result3, isA<Success<Location>>());
        expect(mockRepository.getCurrentLocationCallCount, equals(3));
      });

      test('should handle concurrent calls', () async {
        // Arrange
        final location = Location(
          latitude: 35.6762,
          longitude: 139.6503,
          timestamp: DateTime.now(),
        );
        mockRepository.setMockResult(Success(location));

        // Act
        final futures = List.generate(
          5,
          (_) => useCase.call(const NoParams()),
        );
        final results = await Future.wait(futures);

        // Assert
        expect(results, hasLength(5));
        for (final result in results) {
          expect(result, isA<Success<Location>>());
        }
        expect(mockRepository.getCurrentLocationCallCount, equals(5));
      });
    });

    group('Performance', () {
      test('should complete within reasonable time', () async {
        // Arrange
        final location = Location(
          latitude: 35.6762,
          longitude: 139.6503,
          timestamp: DateTime.now(),
        );
        mockRepository.setMockResult(Success(location));

        // Act
        final stopwatch = Stopwatch()..start();
        await useCase.call(const NoParams());
        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds,
            lessThan(1000)); // Should complete within 1 second
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
        mockRepository.setMockResult(Success(location1));
        final result1 = await useCase.call(const NoParams());
        expect((result1 as Success<Location>).data.latitude, equals(35.6762));

        mockRepository.setMockResult(Success(location2));
        final result2 = await useCase.call(const NoParams());
        expect((result2 as Success<Location>).data.latitude, equals(35.6895));
      });
    });
  });
}

// Mock implementation for testing
class MockLocationRepository implements LocationRepository {
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
}
