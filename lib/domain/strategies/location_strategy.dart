import '../entities/location.dart';
import '../../core/types/result.dart';

/// Strategy pattern interface for location operations
///
/// This abstract class defines the contract for different location service
/// implementations, allowing the system to switch between production GPS,
/// test data, and mock implementations at runtime.
///
/// The strategy pattern enables:
/// - Environment-specific implementations (production, test, mock)
/// - Easy testing with controllable location data
/// - Runtime switching between different location providers
/// - Consistent error handling across all implementations
///
/// Example usage:
/// ```dart
/// // Production environment
/// LocationStrategy strategy = GeolocatorLocationStrategy();
///
/// // Test environment
/// LocationStrategy strategy = MockLocationStrategy();
///
/// // Use the strategy
/// final result = await strategy.getCurrentLocation();
/// switch (result) {
///   case Success<Location>():
///     print('Location: ${result.data}');
///   case Failure<Location>():
///     print('Error: ${result.exception}');
/// }
/// ```
abstract class LocationStrategy {
  /// Gets the current device location
  ///
  /// Returns a [Result<Location>] containing either:
  /// - [Success<Location>] with the current location data
  /// - [Failure<Location>] with a [LocationException] describing the error
  ///
  /// Common failure scenarios:
  /// - Location permissions denied
  /// - Location services disabled
  /// - GPS signal unavailable
  /// - Operation timeout
  ///
  /// Implementation requirements:
  /// - Must handle all permission states appropriately
  /// - Should implement reasonable timeout (e.g., 30 seconds)
  /// - Must provide accurate error information
  /// - Should respect user privacy settings
  Future<Result<Location>> getCurrentLocation();

  /// Checks if the app has location permission
  ///
  /// Returns a [Result<bool>] containing either:
  /// - [Success<bool>] with true if permission is granted
  /// - [Success<bool>] with false if permission is denied
  /// - [Failure<bool>] with a [LocationException] if check fails
  ///
  /// This method should be called before attempting to get location
  /// to provide better user experience and error handling.
  ///
  /// Implementation notes:
  /// - Should check both "when in use" and "always" permissions
  /// - Must handle permanently denied permissions appropriately
  /// - Should be fast and non-blocking
  Future<Result<bool>> hasLocationPermission();

  /// Requests location permission from the user
  ///
  /// Returns a [Result<bool>] containing either:
  /// - [Success<bool>] with true if permission was granted
  /// - [Success<bool>] with false if permission was denied
  /// - [Failure<bool>] with a [LocationException] if request fails
  ///
  /// This method may show system permission dialogs to the user.
  /// It should only be called when permission is actually needed.
  ///
  /// Implementation requirements:
  /// - Must handle "don't ask again" scenarios
  /// - Should provide appropriate user messaging
  /// - Must respect platform permission patterns
  /// - Should be idempotent (safe to call multiple times)
  Future<Result<bool>> requestLocationPermission();

  /// Checks if location services are enabled on the device
  ///
  /// Returns a [Result<bool>] containing either:
  /// - [Success<bool>] with true if location services are enabled
  /// - [Success<bool>] with false if location services are disabled
  /// - [Failure<bool>] with a [LocationException] if check fails
  ///
  /// This is a system-level check independent of app permissions.
  /// Even with app permission, location may be unavailable if
  /// system location services are disabled.
  ///
  /// Implementation notes:
  /// - Should check GPS, network, and passive location providers
  /// - Must handle different location accuracy settings
  /// - Should be fast and cached when possible
  Future<Result<bool>> isLocationServiceEnabled();
}
