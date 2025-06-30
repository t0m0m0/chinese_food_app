import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/domain/events/location_events.dart';
import 'package:chinese_food_app/domain/entities/location.dart';
import 'package:chinese_food_app/core/events/base_event.dart';

void main() {
  group('Location Events', () {
    group('LocationUpdatedEvent', () {
      test('should implement BaseEvent', () {
        // Arrange
        final location = Location(
          latitude: 35.6762,
          longitude: 139.6503,
          timestamp: DateTime.now(),
        );
        final timestamp = DateTime.now();

        // Act
        final event = LocationUpdatedEvent(
          location: location,
          timestamp: timestamp,
        );

        // Assert
        expect(event, isA<BaseEvent>());
        expect(event.location, equals(location));
        expect(event.timestamp, equals(timestamp));
      });

      test('should implement equality correctly', () {
        // Arrange
        final location = Location(
          latitude: 35.6762,
          longitude: 139.6503,
          timestamp: DateTime.now(),
        );
        final timestamp = DateTime.parse('2023-01-01T12:00:00Z');

        // Act
        final event1 = LocationUpdatedEvent(
          location: location,
          timestamp: timestamp,
        );
        final event2 = LocationUpdatedEvent(
          location: location,
          timestamp: timestamp,
        );
        final event3 = LocationUpdatedEvent(
          location: location,
          timestamp: DateTime.parse('2023-01-01T13:00:00Z'),
        );

        // Assert
        expect(event1, equals(event2));
        expect(event1, isNot(equals(event3)));
      });

      test('should have consistent hash code', () {
        // Arrange
        final location = Location(
          latitude: 35.6762,
          longitude: 139.6503,
          timestamp: DateTime.now(),
        );
        final timestamp = DateTime.parse('2023-01-01T12:00:00Z');

        // Act
        final event1 = LocationUpdatedEvent(
          location: location,
          timestamp: timestamp,
        );
        final event2 = LocationUpdatedEvent(
          location: location,
          timestamp: timestamp,
        );

        // Assert
        expect(event1.hashCode, equals(event2.hashCode));
      });

      test('should provide meaningful toString', () {
        // Arrange
        final location = Location(
          latitude: 35.6762,
          longitude: 139.6503,
          timestamp: DateTime.now(),
        );
        final timestamp = DateTime.parse('2023-01-01T12:00:00Z');

        // Act
        final event = LocationUpdatedEvent(
          location: location,
          timestamp: timestamp,
        );

        // Assert
        expect(event.toString(), contains('LocationUpdatedEvent'));
        expect(event.toString(), contains('location:'));
        expect(event.toString(), contains('timestamp:'));
      });

      test('should handle different location data', () {
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
            accuracy: 5.0,
            timestamp: DateTime.now(),
          ),
          Location(
            latitude: 90.0,
            longitude: 180.0,
            accuracy: 100.0,
            timestamp: DateTime.now(),
          ),
        ];

        for (final location in testCases) {
          // Act
          final event = LocationUpdatedEvent(
            location: location,
            timestamp: DateTime.now(),
          );

          // Assert
          expect(event.location, equals(location));
          expect(event, isA<BaseEvent>());
        }
      });
    });

    group('LocationErrorEvent', () {
      test('should implement BaseEvent', () {
        // Arrange
        const error = 'Location access denied';
        const errorCode = 'PERMISSION_DENIED';
        final timestamp = DateTime.now();

        // Act
        final event = LocationErrorEvent(
          error: error,
          errorCode: errorCode,
          timestamp: timestamp,
        );

        // Assert
        expect(event, isA<BaseEvent>());
        expect(event.error, equals(error));
        expect(event.errorCode, equals(errorCode));
        expect(event.timestamp, equals(timestamp));
      });

      test('should implement equality correctly', () {
        // Arrange
        const error = 'Location access denied';
        const errorCode = 'PERMISSION_DENIED';
        final timestamp = DateTime.parse('2023-01-01T12:00:00Z');

        // Act
        final event1 = LocationErrorEvent(
          error: error,
          errorCode: errorCode,
          timestamp: timestamp,
        );
        final event2 = LocationErrorEvent(
          error: error,
          errorCode: errorCode,
          timestamp: timestamp,
        );
        final event3 = LocationErrorEvent(
          error: 'Different error',
          errorCode: errorCode,
          timestamp: timestamp,
        );

        // Assert
        expect(event1, equals(event2));
        expect(event1, isNot(equals(event3)));
      });

      test('should have consistent hash code', () {
        // Arrange
        const error = 'Location access denied';
        const errorCode = 'PERMISSION_DENIED';
        final timestamp = DateTime.parse('2023-01-01T12:00:00Z');

        // Act
        final event1 = LocationErrorEvent(
          error: error,
          errorCode: errorCode,
          timestamp: timestamp,
        );
        final event2 = LocationErrorEvent(
          error: error,
          errorCode: errorCode,
          timestamp: timestamp,
        );

        // Assert
        expect(event1.hashCode, equals(event2.hashCode));
      });

      test('should provide meaningful toString', () {
        // Arrange
        const error = 'Location access denied';
        const errorCode = 'PERMISSION_DENIED';
        final timestamp = DateTime.parse('2023-01-01T12:00:00Z');

        // Act
        final event = LocationErrorEvent(
          error: error,
          errorCode: errorCode,
          timestamp: timestamp,
        );

        // Assert
        expect(event.toString(), contains('LocationErrorEvent'));
        expect(event.toString(), contains('error:'));
        expect(event.toString(), contains('errorCode:'));
        expect(event.toString(), contains('timestamp:'));
      });

      test('should handle different error types', () {
        // Arrange
        final testCases = [
          {
            'error': 'Permission denied',
            'errorCode': 'PERMISSION_DENIED',
          },
          {
            'error': 'Service disabled',
            'errorCode': 'SERVICE_DISABLED',
          },
          {
            'error': 'Timeout occurred',
            'errorCode': 'TIMEOUT',
          },
          {
            'error': 'Unknown error',
            'errorCode': 'UNKNOWN',
          },
        ];

        for (final testCase in testCases) {
          // Act
          final event = LocationErrorEvent(
            error: testCase['error']!,
            errorCode: testCase['errorCode']!,
            timestamp: DateTime.now(),
          );

          // Assert
          expect(event.error, equals(testCase['error']));
          expect(event.errorCode, equals(testCase['errorCode']));
          expect(event, isA<BaseEvent>());
        }
      });
    });

    group('LocationPermissionChangedEvent', () {
      test('should implement BaseEvent', () {
        // Arrange
        const hasPermission = true;
        final timestamp = DateTime.now();

        // Act
        final event = LocationPermissionChangedEvent(
          hasPermission: hasPermission,
          timestamp: timestamp,
        );

        // Assert
        expect(event, isA<BaseEvent>());
        expect(event.hasPermission, equals(hasPermission));
        expect(event.timestamp, equals(timestamp));
      });

      test('should implement equality correctly', () {
        // Arrange
        const hasPermission = true;
        final timestamp = DateTime.parse('2023-01-01T12:00:00Z');

        // Act
        final event1 = LocationPermissionChangedEvent(
          hasPermission: hasPermission,
          timestamp: timestamp,
        );
        final event2 = LocationPermissionChangedEvent(
          hasPermission: hasPermission,
          timestamp: timestamp,
        );
        final event3 = LocationPermissionChangedEvent(
          hasPermission: false,
          timestamp: timestamp,
        );

        // Assert
        expect(event1, equals(event2));
        expect(event1, isNot(equals(event3)));
      });

      test('should have consistent hash code', () {
        // Arrange
        const hasPermission = true;
        final timestamp = DateTime.parse('2023-01-01T12:00:00Z');

        // Act
        final event1 = LocationPermissionChangedEvent(
          hasPermission: hasPermission,
          timestamp: timestamp,
        );
        final event2 = LocationPermissionChangedEvent(
          hasPermission: hasPermission,
          timestamp: timestamp,
        );

        // Assert
        expect(event1.hashCode, equals(event2.hashCode));
      });

      test('should provide meaningful toString', () {
        // Arrange
        const hasPermission = true;
        final timestamp = DateTime.parse('2023-01-01T12:00:00Z');

        // Act
        final event = LocationPermissionChangedEvent(
          hasPermission: hasPermission,
          timestamp: timestamp,
        );

        // Assert
        expect(event.toString(), contains('LocationPermissionChangedEvent'));
        expect(event.toString(), contains('hasPermission:'));
        expect(event.toString(), contains('timestamp:'));
      });

      test('should handle both permission states', () {
        // Arrange
        final timestamp = DateTime.now();

        // Act
        final grantedEvent = LocationPermissionChangedEvent(
          hasPermission: true,
          timestamp: timestamp,
        );
        final deniedEvent = LocationPermissionChangedEvent(
          hasPermission: false,
          timestamp: timestamp,
        );

        // Assert
        expect(grantedEvent.hasPermission, isTrue);
        expect(deniedEvent.hasPermission, isFalse);
        expect(grantedEvent, isA<BaseEvent>());
        expect(deniedEvent, isA<BaseEvent>());
      });
    });

    group('Event Integration', () {
      test('should be usable with EventBus', () {
        // This test verifies that the events can be used with the EventBus
        // without actually creating an EventBus instance (to avoid dependencies)

        // Arrange
        final location = Location(
          latitude: 35.6762,
          longitude: 139.6503,
          timestamp: DateTime.now(),
        );
        final events = [
          LocationUpdatedEvent(
            location: location,
            timestamp: DateTime.now(),
          ),
          LocationErrorEvent(
            error: 'Test error',
            errorCode: 'TEST_ERROR',
            timestamp: DateTime.now(),
          ),
          LocationPermissionChangedEvent(
            hasPermission: true,
            timestamp: DateTime.now(),
          ),
        ];

        // Assert - All events should extend BaseEvent
        for (final event in events) {
          expect(event, isA<BaseEvent>());
          expect(event.toString(), isNotEmpty);
          expect(event.hashCode, isA<int>());
        }
      });

      test('should have unique runtime types', () {
        // Arrange
        final location = Location(
          latitude: 35.6762,
          longitude: 139.6503,
          timestamp: DateTime.now(),
        );
        final timestamp = DateTime.now();

        final locationEvent = LocationUpdatedEvent(
          location: location,
          timestamp: timestamp,
        );
        final errorEvent = LocationErrorEvent(
          error: 'Test error',
          errorCode: 'TEST_ERROR',
          timestamp: timestamp,
        );
        final permissionEvent = LocationPermissionChangedEvent(
          hasPermission: true,
          timestamp: timestamp,
        );

        // Assert - Each event type should have a unique runtime type
        expect(
            locationEvent.runtimeType, isNot(equals(errorEvent.runtimeType)));
        expect(locationEvent.runtimeType,
            isNot(equals(permissionEvent.runtimeType)));
        expect(
            errorEvent.runtimeType, isNot(equals(permissionEvent.runtimeType)));
      });
    });
  });
}
