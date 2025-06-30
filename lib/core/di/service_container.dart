/// Generic Dependency Injection Container for managing service registration and resolution
///
/// This container provides a lightweight dependency injection system with support for
/// transient and singleton service lifetimes. It uses Map-based storage for O(1)
/// registration and resolution performance.
///
/// ## Usage Example:
/// ```dart
/// final container = ServiceContainer();
///
/// // Register transient services (new instance each time)
/// container.register<ApiService>(() => ApiService());
///
/// // Register singleton services (same instance each time)
/// container.registerSingleton<DatabaseService>(() => DatabaseService());
///
/// // Resolve services
/// final api = container.resolve<ApiService>(); // New instance
/// final db1 = container.resolve<DatabaseService>(); // First instance
/// final db2 = container.resolve<DatabaseService>(); // Same instance as db1
///
/// // Check registration status
/// if (container.isRegistered<LoggerService>()) {
///   final logger = container.resolve<LoggerService>();
/// }
///
/// // Memory management
/// container.clearSingleton<DatabaseService>(); // Clear specific singleton
/// container.dispose(); // Clear all singletons
/// ```
///
/// ## Performance Characteristics:
/// - Registration: O(1) - Uses Map-based storage
/// - Resolution: O(1) - Direct Map lookup
/// - Memory: Singletons are cached until explicitly cleared or disposed
///
/// ## Thread Safety:
/// This container is NOT thread-safe. Use appropriate synchronization mechanisms
/// when accessing from multiple isolates or consider using a thread-safe alternative
/// for concurrent scenarios.
///
/// ## Lifecycle Management:
/// - **Transient**: New instance created on each resolve() call
/// - **Singleton**: Single instance created on first resolve(), cached thereafter
/// - **Memory**: Call dispose() or clearSingleton() to manage memory usage
class ServiceContainer {
  final Map<Type, Function> _factories = {};
  final Map<Type, Object> _singletonInstances = {};

  /// Register a service factory function (transient)
  void register<T>(T Function() factory) {
    _factories[T] = factory;
  }

  /// Register a service as singleton
  void registerSingleton<T>(T Function() factory) {
    _factories[T] = () {
      // Check if singleton instance already exists
      if (_singletonInstances.containsKey(T)) {
        return _singletonInstances[T] as T;
      }

      // Create and store singleton instance
      final instance = factory();
      _singletonInstances[T] = instance as Object;
      return instance;
    };
  }

  /// Resolve a service instance
  T resolve<T>() {
    final factory = _factories[T];
    if (factory == null) {
      throw ServiceContainerException('Service of type $T is not registered');
    }
    return factory() as T;
  }

  /// Clear all singleton instances (useful for testing/cleanup)
  void dispose() {
    _singletonInstances.clear();
  }

  /// Clear specific singleton instance
  void clearSingleton<T>() {
    _singletonInstances.remove(T);
  }

  /// Check if a service is registered
  bool isRegistered<T>() {
    return _factories.containsKey(T);
  }
}

/// Exception thrown when ServiceContainer operations fail
class ServiceContainerException implements Exception {
  final String message;

  const ServiceContainerException(this.message);

  @override
  String toString() => 'ServiceContainerException: $message';
}
