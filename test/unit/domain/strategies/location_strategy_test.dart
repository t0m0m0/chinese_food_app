import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/domain/strategies/location_strategy.dart';
import 'package:chinese_food_app/domain/entities/location.dart';
import 'package:chinese_food_app/core/types/result.dart';
import 'package:chinese_food_app/core/exceptions/domain_exceptions.dart'
    as domain;

void main() {
  group('LocationStrategy Interface', () {
    group('Contract Definition', () {
      test('should define abstract methods for location operations', () {
        // This test verifies that LocationStrategy is properly defined as an abstract class
        // with the required methods. Since it's abstract, we test via concrete implementations.
        expect(LocationStrategy, isA<Type>());
      });

      test('should require getCurrentLocation method', () {
        // Arrange & Act - This will be tested via concrete implementations
        // Assert - Method signature verification happens at compile time
        expect(() => _TestLocationStrategy(), returnsNormally);
      });

      test('should require hasLocationPermission method', () {
        // Arrange & Act - This will be tested via concrete implementations
        // Assert - Method signature verification happens at compile time
        expect(() => _TestLocationStrategy(), returnsNormally);
      });

      test('should require requestLocationPermission method', () {
        // Arrange & Act - This will be tested via concrete implementations
        // Assert - Method signature verification happens at compile time
        expect(() => _TestLocationStrategy(), returnsNormally);
      });

      test('should require isLocationServiceEnabled method', () {
        // Arrange & Act - This will be tested via concrete implementations
        // Assert - Method signature verification happens at compile time
        expect(() => _TestLocationStrategy(), returnsNormally);
      });
    });

    group('Return Types', () {
      test('should return Result<Location> for getCurrentLocation', () async {
        // Arrange
        final strategy = _TestLocationStrategy();

        // Act
        final result = await strategy.getCurrentLocation();

        // Assert
        expect(result, isA<Result<Location>>());
      });

      test('should return Result<bool> for permission methods', () async {
        // Arrange
        final strategy = _TestLocationStrategy();

        // Act
        final hasPermission = await strategy.hasLocationPermission();
        final requestPermission = await strategy.requestLocationPermission();
        final serviceEnabled = await strategy.isLocationServiceEnabled();

        // Assert
        expect(hasPermission, isA<Result<bool>>());
        expect(requestPermission, isA<Result<bool>>());
        expect(serviceEnabled, isA<Result<bool>>());
      });

      test('should handle Success cases for all methods', () async {
        // Arrange
        final strategy = _TestLocationStrategy();

        // Act
        final location = await strategy.getCurrentLocation();
        final hasPermission = await strategy.hasLocationPermission();
        final requestPermission = await strategy.requestLocationPermission();
        final serviceEnabled = await strategy.isLocationServiceEnabled();

        // Assert
        expect(location, isA<Success<Location>>());
        expect(hasPermission, isA<Success<bool>>());
        expect(requestPermission, isA<Success<bool>>());
        expect(serviceEnabled, isA<Success<bool>>());
      });

      test('should handle Failure cases for all methods', () async {
        // Arrange
        final strategy = _FailingLocationStrategy();

        // Act
        final location = await strategy.getCurrentLocation();
        final hasPermission = await strategy.hasLocationPermission();
        final requestPermission = await strategy.requestLocationPermission();
        final serviceEnabled = await strategy.isLocationServiceEnabled();

        // Assert
        expect(location, isA<Failure<Location>>());
        expect(hasPermission, isA<Failure<bool>>());
        expect(requestPermission, isA<Failure<bool>>());
        expect(serviceEnabled, isA<Failure<bool>>());
      });
    });

    group('Error Handling', () {
      test('should use appropriate exceptions for different error scenarios',
          () async {
        // Arrange
        final strategy = _SpecificErrorLocationStrategy();

        // Act
        final permissionResult = await strategy.hasLocationPermission();
        final serviceResult = await strategy.isLocationServiceEnabled();
        final locationResult = await strategy.getCurrentLocation();

        // Assert - Check specific exception types
        expect(permissionResult, isA<Failure<bool>>());
        expect((permissionResult as Failure<bool>).exception,
            isA<domain.LocationException>());

        expect(serviceResult, isA<Failure<bool>>());
        expect((serviceResult as Failure<bool>).exception,
            isA<domain.LocationException>());

        expect(locationResult, isA<Failure<Location>>());
        expect((locationResult as Failure<Location>).exception,
            isA<domain.LocationException>());
      });

      test('should preserve exception details', () async {
        // Arrange
        final strategy = _SpecificErrorLocationStrategy();

        // Act
        final result = await strategy.getCurrentLocation();

        // Assert
        expect(result, isA<Failure<Location>>());
        final failure = result as Failure<Location>;
        expect(failure.exception.message, contains('Location access denied'));
        expect((failure.exception as domain.LocationException).reason,
            equals(domain.LocationExceptionReason.permissionDenied));
      });
    });

    group('Integration Patterns', () {
      test('should support strategy switching at runtime', () async {
        // Arrange
        LocationStrategy strategy = _TestLocationStrategy();

        // Act - Use first strategy
        final result1 = await strategy.getCurrentLocation();

        // Switch strategy
        strategy = _MockLocationStrategy();
        final result2 = await strategy.getCurrentLocation();

        // Assert
        expect(result1, isA<Success<Location>>());
        expect(result2, isA<Success<Location>>());

        // Results should be different based on strategy
        final location1 = (result1 as Success<Location>).data;
        final location2 = (result2 as Success<Location>).data;
        expect(location1.latitude, isNot(equals(location2.latitude)));
      });

      test('should maintain consistent interface across implementations',
          () async {
        // Arrange
        final strategies = [
          _TestLocationStrategy(),
          _MockLocationStrategy(),
          _FailingLocationStrategy(),
        ];

        // Act & Assert
        for (final strategy in strategies) {
          // All strategies should implement the same interface
          expect(strategy, isA<LocationStrategy>());

          // All methods should return the expected types
          expect(await strategy.getCurrentLocation(), isA<Result<Location>>());
          expect(await strategy.hasLocationPermission(), isA<Result<bool>>());
          expect(
              await strategy.requestLocationPermission(), isA<Result<bool>>());
          expect(
              await strategy.isLocationServiceEnabled(), isA<Result<bool>>());
        }
      });
    });
  });
}

// Test implementations for testing the abstract interface

class _TestLocationStrategy extends LocationStrategy {
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

class _FailingLocationStrategy extends LocationStrategy {
  @override
  Future<Result<Location>> getCurrentLocation() async {
    return Failure(domain.LocationException('Failed to get location'));
  }

  @override
  Future<Result<bool>> hasLocationPermission() async {
    return Failure(domain.LocationException('Permission check failed'));
  }

  @override
  Future<Result<bool>> requestLocationPermission() async {
    return Failure(domain.LocationException('Permission request failed'));
  }

  @override
  Future<Result<bool>> isLocationServiceEnabled() async {
    return Failure(domain.LocationException('Service check failed'));
  }
}

class _SpecificErrorLocationStrategy extends LocationStrategy {
  @override
  Future<Result<Location>> getCurrentLocation() async {
    return Failure(domain.LocationException(
      'Location access denied',
      reason: domain.LocationExceptionReason.permissionDenied,
    ));
  }

  @override
  Future<Result<bool>> hasLocationPermission() async {
    return Failure(domain.LocationException(
      'Permission denied',
      reason: domain.LocationExceptionReason.permissionDenied,
    ));
  }

  @override
  Future<Result<bool>> requestLocationPermission() async {
    return Failure(domain.LocationException(
      'Service disabled',
      reason: domain.LocationExceptionReason.serviceDisabled,
    ));
  }

  @override
  Future<Result<bool>> isLocationServiceEnabled() async {
    return Failure(domain.LocationException(
      'Service check timeout',
      reason: domain.LocationExceptionReason.timeout,
    ));
  }
}

class _MockLocationStrategy extends LocationStrategy {
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
