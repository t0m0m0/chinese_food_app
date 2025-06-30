/// Generic Dependency Injection Container for managing service registration and resolution
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
}

/// Exception thrown when ServiceContainer operations fail
class ServiceContainerException implements Exception {
  final String message;
  
  const ServiceContainerException(this.message);
  
  @override
  String toString() => 'ServiceContainerException: $message';
}