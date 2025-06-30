import '../entities/location.dart';
import '../../core/types/result.dart';

/// Repository interface for location-related operations
///
/// This interface defines the contract for location data access,
/// following the Repository pattern from Clean Architecture.
/// It abstracts the data layer from the domain layer, allowing for
/// different implementations (GPS, network, cache, mock, etc.).
///
/// The repository pattern provides:
/// - Separation of concerns between domain and data layers
/// - Testability through dependency injection
/// - Flexibility to switch data sources
/// - Consistent error handling across different data sources
///
/// Example usage:
/// ```dart
/// class LocationService {
///   final LocationRepository _repository;
///
///   LocationService(this._repository);
///
///   Future<Result<Location>> getCurrentLocation() async {
///     return await _repository.getCurrentLocation();
///   }
/// }
/// ```
abstract class LocationRepository {
  /// Gets the current device location
  ///
  /// Returns a [Result<Location>] containing either:
  /// - [Success<Location>] with the current location data
  /// - [Failure<Location>] with an exception describing the error
  ///
  /// Implementation requirements:
  /// - Should handle permission checks internally
  /// - Should verify location services are enabled
  /// - Should implement appropriate timeout handling
  /// - Should provide consistent error reporting
  /// - Should respect user privacy settings
  ///
  /// Common failure scenarios:
  /// - Location permissions denied
  /// - Location services disabled
  /// - GPS signal unavailable
  /// - Network connectivity issues (for network-based location)
  /// - Operation timeout
  Future<Result<Location>> getCurrentLocation();
}
