/// Abstract base class for all events in the Event-Driven Architecture
///
/// This class serves as the foundation for all events that can be published
/// and consumed through the EventBus system. All domain events should extend
/// this class to ensure type safety and consistency.
///
/// Key principles:
/// - Events should be immutable (all fields should be final)
/// - Events should represent something that has already happened
/// - Events should contain all necessary data for consumers
/// - Events should have meaningful names that describe what occurred
///
/// Example usage:
/// ```dart
/// class LocationUpdatedEvent extends BaseEvent {
///   final Location location;
///   final DateTime timestamp;
///
///   const LocationUpdatedEvent({
///     required this.location,
///     required this.timestamp,
///   });
///
///   @override
///   bool operator ==(Object other) =>
///       identical(this, other) ||
///       other is LocationUpdatedEvent &&
///           location == other.location &&
///           timestamp == other.timestamp;
///
///   @override
///   int get hashCode => Object.hash(location, timestamp);
/// }
///
/// // Publishing
/// EventBus.instance.emit(LocationUpdatedEvent(
///   location: currentLocation,
///   timestamp: DateTime.now(),
/// ));
///
/// // Consuming
/// EventBus.instance.on<LocationUpdatedEvent>().listen((event) {
///   print('Location updated: ${event.location}');
/// });
/// ```
abstract class BaseEvent {
  const BaseEvent();

  /// Events should override equality to enable proper comparison
  /// This is especially important for testing and debugging
  @override
  bool operator ==(Object other);

  /// Events should override hashCode when overriding equality
  /// This ensures proper behavior in collections and maps
  @override
  int get hashCode;

  /// Events should provide a meaningful string representation
  /// This aids in debugging and logging
  @override
  String toString() => runtimeType.toString();
}
