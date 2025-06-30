import 'dart:async';
import 'base_event.dart';

/// Event-driven communication system for the application
///
/// The EventBus provides a decoupled way for different parts of the application
/// to communicate through events. It follows the publish-subscribe pattern,
/// allowing components to emit events and other components to listen for them
/// without direct dependencies.
///
/// Key features:
/// - Type-safe event handling
/// - Multiple subscribers per event type
/// - Stream-based API for reactive programming
/// - Singleton pattern for global access
/// - Memory management with dispose functionality
/// - Support for event filtering and transformation
///
/// Example usage:
/// ```dart
/// // Publishing events
/// EventBus.instance.emit(LocationUpdatedEvent(location));
/// EventBus.instance.emit(UserLoginEvent(user));
///
/// // Subscribing to events
/// EventBus.instance.on<LocationUpdatedEvent>().listen((event) {
///   updateUI(event.location);
/// });
///
/// // Filtered listening
/// EventBus.instance.on<UserActionEvent>()
///     .where((event) => event.isImportant)
///     .listen(handleImportantAction);
///
/// // Cleanup
/// EventBus.instance.dispose(); // Usually called on app shutdown
/// ```
class EventBus {
  static EventBus? _instance;
  final Map<Type, StreamController<BaseEvent>> _controllers = {};
  bool _disposed = false;

  /// Private constructor for singleton pattern
  EventBus._();

  /// Factory constructor that creates a new instance
  /// Use this when you need separate event bus instances for testing
  factory EventBus() => EventBus._();

  /// Singleton instance for global event communication
  /// This is the recommended way to access the event bus in production
  static EventBus get instance {
    _instance ??= EventBus._();
    return _instance!;
  }

  /// Emits an event to all subscribers of the event type
  ///
  /// [event] - The event to emit. Must extend BaseEvent
  ///
  /// The event will be delivered to all current subscribers of the event type.
  /// If there are no subscribers, the event is discarded silently.
  ///
  /// Example:
  /// ```dart
  /// eventBus.emit(LocationUpdatedEvent(currentLocation));
  /// ```
  void emit<T extends BaseEvent>(T event) {
    if (_disposed) {
      return;
    }

    final eventType = T;
    final controller = _controllers[eventType];

    if (controller != null && !controller.isClosed) {
      controller.add(event);
    }
  }

  /// Returns a stream of events for the specified event type
  ///
  /// [T] - The event type to listen for. Must extend BaseEvent
  /// Returns a [Stream<T>] that emits events of type T
  ///
  /// The returned stream can be used with all standard Dart stream operations:
  /// - listen() for simple event handling
  /// - where() for filtering events
  /// - map() for transforming events
  /// - take() for limiting the number of events
  /// - etc.
  ///
  /// Example:
  /// ```dart
  /// // Simple listening
  /// eventBus.on<LocationUpdatedEvent>().listen((event) {
  ///   handleLocationUpdate(event.location);
  /// });
  ///
  /// // Filtered listening
  /// eventBus.on<UserActionEvent>()
  ///     .where((event) => event.userId == currentUserId)
  ///     .listen(handleUserAction);
  /// ```
  Stream<T> on<T extends BaseEvent>() {
    if (_disposed) {
      // Return a closed stream if the event bus is disposed
      return const Stream.empty();
    }

    final eventType = T;

    // Create controller if it doesn't exist
    if (!_controllers.containsKey(eventType)) {
      _controllers[eventType] = StreamController<BaseEvent>.broadcast();
    }

    final controller = _controllers[eventType]!;

    // Return a typed stream that filters for the specific event type
    return controller.stream.where((event) => event is T).cast<T>();
  }

  /// Disposes of the event bus and closes all streams
  ///
  /// This method should be called when the event bus is no longer needed,
  /// typically during application shutdown. After disposal:
  /// - No new events will be emitted
  /// - All existing streams will be closed
  /// - New subscriptions will return empty streams
  ///
  /// It's safe to call dispose() multiple times.
  ///
  /// Example:
  /// ```dart
  /// // In app shutdown code
  /// EventBus.instance.dispose();
  /// ```
  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;

    // Close all stream controllers
    for (final controller in _controllers.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }

    _controllers.clear();

    // Reset singleton instance
    if (_instance == this) {
      _instance = null;
    }
  }

  /// Returns whether the event bus has been disposed
  bool get isDisposed => _disposed;

  /// Returns the number of active event type controllers
  /// Useful for debugging and testing
  int get activeControllerCount => _controllers.length;

  /// Returns the types of events that have active controllers
  /// Useful for debugging and testing
  Set<Type> get activeEventTypes => _controllers.keys.toSet();
}
