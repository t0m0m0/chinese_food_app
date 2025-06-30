import '../../domain/repositories/location_repository.dart';
import '../../domain/strategies/location_strategy.dart';
import '../../domain/entities/location.dart';
import '../../core/types/result.dart';

/// Concrete implementation of LocationRepository
///
/// This implementation uses the Strategy pattern to delegate location
/// operations to a configurable LocationStrategy. This allows for
/// different location providers (GPS, network, mock) to be swapped
/// at runtime without changing the repository interface.
///
/// Features:
/// - Strategy pattern for flexible location providers
/// - Consistent error handling through Result type
/// - Clean separation between repository and strategy concerns
/// - Easy testing with injectable strategies
///
/// Example usage:
/// ```dart
/// // Production setup
/// final strategy = GeolocatorLocationStrategy();
/// final repository = LocationRepositoryImpl(strategy);
///
/// // Test setup
/// final mockStrategy = MockLocationStrategy();
/// final repository = LocationRepositoryImpl(mockStrategy);
///
/// // Usage
/// final result = await repository.getCurrentLocation();
/// ```
class LocationRepositoryImpl implements LocationRepository {
  final LocationStrategy _strategy;

  /// Creates a LocationRepositoryImpl with the specified strategy
  ///
  /// [_strategy] - The location strategy to use for location operations
  const LocationRepositoryImpl(this._strategy);

  @override
  Future<Result<Location>> getCurrentLocation() async {
    // Delegate to the strategy for actual location retrieval
    // The repository acts as a facade that could potentially:
    // - Add caching logic
    // - Implement retry mechanisms
    // - Add logging/analytics
    // - Perform data transformation
    // For now, it simply delegates to the strategy
    return await _strategy.getCurrentLocation();
  }
}
