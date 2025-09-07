import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/events/event_bus.dart';
import 'package:chinese_food_app/core/events/base_event.dart';

void main() {
  group('EventBus Basic Tests', () {
    late EventBus eventBus;

    setUp(() {
      eventBus = EventBus();
    });

    tearDown(() {
      eventBus.dispose();
    });

    test('should emit and receive events', () async {
      // Arrange
      final testEvent = const _SimpleTestEvent('test message');
      final stream = eventBus.on<_SimpleTestEvent>();
      _SimpleTestEvent? receivedEvent;

      // Act
      stream.listen((event) {
        receivedEvent = event;
      });

      eventBus.emit(testEvent);

      // Give time for async processing
      await Future.delayed(const Duration(milliseconds: 10));

      // Assert
      expect(receivedEvent, equals(testEvent));
    });

    test('should handle multiple event types', () async {
      // Arrange
      final testEvent = const _SimpleTestEvent('test');
      final otherEvent = const _OtherSimpleEvent(42);
      final testStream = eventBus.on<_SimpleTestEvent>();
      final otherStream = eventBus.on<_OtherSimpleEvent>();

      _SimpleTestEvent? receivedTestEvent;
      _OtherSimpleEvent? receivedOtherEvent;

      // Act
      testStream.listen((event) => receivedTestEvent = event);
      otherStream.listen((event) => receivedOtherEvent = event);

      eventBus.emit(testEvent);
      eventBus.emit(otherEvent);

      // Give time for async processing
      await Future.delayed(const Duration(milliseconds: 10));

      // Assert
      expect(receivedTestEvent, equals(testEvent));
      expect(receivedOtherEvent, equals(otherEvent));
    });

    test('should create singleton instance', () {
      // Act
      final instance1 = EventBus.instance;
      final instance2 = EventBus.instance;

      // Assert
      expect(instance1, same(instance2));
    });

    test('should dispose properly', () {
      // Act
      eventBus.dispose();

      // Assert
      expect(eventBus.isDisposed, isTrue);
      expect(
          () => eventBus.emit(const _SimpleTestEvent('test')), returnsNormally);
    });

    test('should handle stream filtering', () async {
      // Arrange
      final event1 = const _SimpleTestEvent('include');
      final event2 = const _SimpleTestEvent('exclude');
      final filteredStream = eventBus
          .on<_SimpleTestEvent>()
          .where((event) => event.message.contains('include'));

      final receivedEvents = <_SimpleTestEvent>[];

      // Act
      filteredStream.listen((event) => receivedEvents.add(event));

      eventBus.emit(event1);
      eventBus.emit(event2);

      // Give time for async processing
      await Future.delayed(const Duration(milliseconds: 10));

      // Assert
      expect(receivedEvents, hasLength(1));
      expect(receivedEvents.first, equals(event1));
    });
  });
}

// Simple test events
class _SimpleTestEvent extends BaseEvent {
  final String message;

  const _SimpleTestEvent(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SimpleTestEvent &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => '_SimpleTestEvent(message: $message)';
}

class _OtherSimpleEvent extends BaseEvent {
  final int value;

  const _OtherSimpleEvent(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _OtherSimpleEvent &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => '_OtherSimpleEvent(value: $value)';
}
