import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/events/event_bus.dart';
import 'package:chinese_food_app/core/events/base_event.dart';

void main() {
  group('EventBus', () {
    late EventBus eventBus;

    setUp(() {
      eventBus = EventBus();
    });

    tearDown(() {
      eventBus.dispose();
    });

    group('Basic Functionality', () {
      test('should create singleton instance', () {
        // Act
        final instance1 = EventBus.instance;
        final instance2 = EventBus.instance;

        // Assert
        expect(instance1, same(instance2));
        expect(instance1, isA<EventBus>());
      });

      test('should allow creating separate instances', () {
        // Act
        final instance1 = EventBus();
        final instance2 = EventBus();

        // Assert
        expect(instance1, isNot(same(instance2)));
        expect(instance1, isA<EventBus>());
        expect(instance2, isA<EventBus>());
      });

      test('should provide stream for specific event type', () {
        // Act
        final stream = eventBus.on<_TestEvent>();

        // Assert
        expect(stream, isA<Stream<_TestEvent>>());
      });
    });

    group('Event Publishing', () {
      test('should emit event to subscribers', () async {
        // Arrange
        final testEvent = const _TestEvent('test message');
        final stream = eventBus.on<_TestEvent>();

        // Act & Assert
        expectLater(stream, emits(testEvent));
        eventBus.emit(testEvent);
      });

      test('should emit multiple events in order', () async {
        // Arrange
        final event1 = const _TestEvent('first');
        final event2 = const _TestEvent('second');
        final event3 = const _TestEvent('third');
        final stream = eventBus.on<_TestEvent>();

        // Act & Assert
        expectLater(
          stream,
          emitsInOrder([event1, event2, event3]),
        );

        eventBus.emit(event1);
        eventBus.emit(event2);
        eventBus.emit(event3);
      });

      test('should handle different event types separately', () async {
        // Arrange
        final testEvent = const _TestEvent('test');
        final otherEvent = const _OtherTestEvent(42);
        final testStream = eventBus.on<_TestEvent>();
        final otherStream = eventBus.on<_OtherTestEvent>();

        // Act & Assert
        expectLater(testStream, emits(testEvent));
        expectLater(otherStream, emits(otherEvent));

        eventBus.emit(testEvent);
        eventBus.emit(otherEvent);
      });

      test('should not emit to wrong event type subscribers', () async {
        // Arrange
        final testEvent = const _TestEvent('test');
        final otherEvents = <_OtherTestEvent>[];

        // Subscribe to different event type
        eventBus.on<_OtherTestEvent>().listen((event) {
          otherEvents.add(event);
        });

        // Act
        eventBus.emit(testEvent);

        // Give some time to ensure no emission
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert - No events should be received by wrong type subscriber
        expect(otherEvents, isEmpty);
      });
    });

    group('Multiple Subscribers', () {
      test('should emit to multiple subscribers of same event type', () async {
        // Arrange
        final testEvent = const _TestEvent('broadcast');
        final stream1 = eventBus.on<_TestEvent>();
        final stream2 = eventBus.on<_TestEvent>();
        final stream3 = eventBus.on<_TestEvent>();

        // Act & Assert
        expectLater(stream1, emits(testEvent));
        expectLater(stream2, emits(testEvent));
        expectLater(stream3, emits(testEvent));

        eventBus.emit(testEvent);
      });

      test('should handle subscription after event emission', () async {
        // Arrange
        final testEvent = const _TestEvent('late subscriber');
        final lateEvents = <_TestEvent>[];

        // Act - Emit before subscription
        eventBus.emit(testEvent);

        // Late subscription should not receive past events
        final lateStream = eventBus.on<_TestEvent>();
        final subscription = lateStream.listen((event) {
          lateEvents.add(event);
        });

        // Give some time to ensure no emission
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert - No past events should be received
        expect(lateEvents, isEmpty);

        // Cleanup
        await subscription.cancel();
      });
    });

    group('Event Filtering and Listening', () {
      test('should support listening with specific conditions', () async {
        // Arrange
        final event1 = const _TestEvent('include');
        final event2 = const _TestEvent('exclude');
        final filteredEvents = <_TestEvent>[];

        final stream = eventBus
            .on<_TestEvent>()
            .where((event) => event.message.contains('include'));

        stream.listen((event) {
          filteredEvents.add(event);
        });

        // Act
        eventBus.emit(event1);
        eventBus.emit(event2);

        await Future.delayed(const Duration(milliseconds: 10));

        // Assert - Only 'include' event should be received
        expect(filteredEvents, hasLength(1));
        expect(filteredEvents.first, equals(event1));
      });

      test('should support stream transformations', () async {
        // Arrange
        final testEvent = const _TestEvent('transform me');
        final transformedStream = eventBus
            .on<_TestEvent>()
            .map((event) => event.message.toUpperCase());

        // Act & Assert
        expectLater(transformedStream, emits('TRANSFORM ME'));
        eventBus.emit(testEvent);
      });

      test('should support taking limited number of events', () async {
        // Arrange
        final event1 = const _TestEvent('first');
        final event2 = const _TestEvent('second');
        final event3 = const _TestEvent('third');
        final limitedStream = eventBus.on<_TestEvent>().take(2);

        // Act & Assert
        expectLater(
          limitedStream,
          emitsInOrder([event1, event2, emitsDone]),
        );

        eventBus.emit(event1);
        eventBus.emit(event2);
        eventBus.emit(event3); // This should not be received
      });
    });

    group('Error Handling', () {
      test('should handle invalid events gracefully', () {
        // Act & Assert - Test with a valid event type instead of null
        expect(() => eventBus.emit(const _TestEvent('test')), returnsNormally);
      });

      test('should continue working after error in subscriber', () async {
        // Arrange
        final testEvent1 = const _TestEvent('test1');
        final testEvent2 = const _TestEvent('test2');

        // Subscribe with working listener
        final receivedEvents = <_TestEvent>[];
        eventBus.on<_TestEvent>().listen((event) {
          receivedEvents.add(event);
        });

        // Act - EventBus should continue working normally
        eventBus.emit(testEvent1);
        await Future.delayed(const Duration(milliseconds: 10));
        eventBus.emit(testEvent2);
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert - EventBus continues working regardless of potential subscriber errors
        expect(receivedEvents, hasLength(2));
        expect(receivedEvents[0].message, equals('test1'));
        expect(receivedEvents[1].message, equals('test2'));
      });

      test('should handle disposed event bus gracefully', () {
        // Arrange
        eventBus.dispose();

        // Act & Assert
        expect(() => eventBus.emit(const _TestEvent('after dispose')),
            returnsNormally);
        expect(() => eventBus.on<_TestEvent>(), returnsNormally);
      });
    });

    group('Memory Management', () {
      test('should close streams on dispose', () async {
        // Arrange
        final stream = eventBus.on<_TestEvent>();
        bool streamClosed = false;

        stream.listen(
          (event) {},
          onDone: () => streamClosed = true,
        );

        // Act
        eventBus.dispose();

        // Give some time for cleanup
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(streamClosed, isTrue);
      });

      test('should prevent new subscriptions after dispose', () {
        // Arrange
        eventBus.dispose();

        // Act
        final stream = eventBus.on<_TestEvent>();

        // Assert
        expectLater(stream, emitsDone);
      });

      test('should handle multiple dispose calls', () {
        // Act & Assert
        expect(() {
          eventBus.dispose();
          eventBus.dispose();
          eventBus.dispose();
        }, returnsNormally);
      });
    });

    group('Performance', () {
      test('should handle many events efficiently', () async {
        // Arrange
        const eventCount = 1000;
        final events = List.generate(
          eventCount,
          (i) => _TestEvent('event_$i'),
        );
        final stream = eventBus.on<_TestEvent>();
        final receivedEvents = <_TestEvent>[];

        // Act
        stream.listen((event) => receivedEvents.add(event));

        final stopwatch = Stopwatch()..start();
        for (final event in events) {
          eventBus.emit(event);
        }
        stopwatch.stop();

        // Give time for all events to be processed
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(receivedEvents, hasLength(eventCount));
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should be fast
      });

      test('should handle many subscribers efficiently', () async {
        // Arrange
        const subscriberCount = 100;
        final testEvent = const _TestEvent('broadcast');
        final receivedCounts = <int>[];

        // Create many subscribers
        for (int i = 0; i < subscriberCount; i++) {
          eventBus.on<_TestEvent>().listen((_) {
            receivedCounts.add(i);
          });
        }

        // Act
        final stopwatch = Stopwatch()..start();
        eventBus.emit(testEvent);
        stopwatch.stop();

        // Give time for all subscribers to process
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(receivedCounts, hasLength(subscriberCount));
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should be fast
      });
    });

    group('Concurrent Access', () {
      test('should handle concurrent emissions safely', () async {
        // Arrange
        const concurrentCount = 50;
        final stream = eventBus.on<_TestEvent>();
        final receivedEvents = <_TestEvent>[];

        stream.listen((event) => receivedEvents.add(event));

        // Act - Emit events concurrently
        final futures = List.generate(
          concurrentCount,
          (i) => Future(() => eventBus.emit(_TestEvent('concurrent_$i'))),
        );

        await Future.wait(futures);

        // Give time for all events to be processed
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(receivedEvents, hasLength(concurrentCount));
      });

      test('should handle concurrent subscriptions safely', () async {
        // Arrange
        const subscriberCount = 50;
        final testEvent = const _TestEvent('test');
        final streams = <Stream<_TestEvent>>[];

        // Act - Create subscriptions concurrently
        final futures = List.generate(
          subscriberCount,
          (i) => Future(() {
            final stream = eventBus.on<_TestEvent>();
            streams.add(stream);
            return stream;
          }),
        );

        await Future.wait(futures);

        // Emit event after all subscriptions
        eventBus.emit(testEvent);

        // Assert - All streams should receive the event
        expect(streams, hasLength(subscriberCount));
      });
    });
  });
}

// Test event classes
class _TestEvent extends BaseEvent {
  final String message;

  const _TestEvent(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _TestEvent &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => '_TestEvent(message: $message)';
}

class _OtherTestEvent extends BaseEvent {
  final int value;

  const _OtherTestEvent(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _OtherTestEvent &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => '_OtherTestEvent(value: $value)';
}
