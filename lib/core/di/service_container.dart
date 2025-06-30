/// Generic Dependency Injection Container for managing service registration and resolution
class ServiceContainer {
  final Map<Type, Function> _factories = {};

  /// Register a service factory function
  void register<T>(T Function() factory) {
    _factories[T] = factory;
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