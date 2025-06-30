import '../base_usecase.dart';
import '../../repositories/location_repository.dart';
import '../../entities/location.dart';
import '../../../core/types/result.dart';

/// Use Case for getting the current device location
///
/// This Use Case encapsulates the business logic for retrieving the current
/// location from the device. It acts as an intermediary between the
/// presentation layer and the data layer, ensuring that location access
/// follows the application's business rules.
///
/// Responsibilities:
/// - Delegate to LocationRepository for actual location retrieval
/// - Handle any additional business logic (validation, transformation, etc.)
/// - Provide a consistent interface for location access across the app
/// - Ensure proper error handling and reporting
///
/// Example usage:
/// ```dart
/// final useCase = GetCurrentLocationUseCase(locationRepository);
/// final result = await useCase.call(NoParams());
///
/// switch (result) {
///   case Success<Location>():
///     print('Current location: ${result.data}');
///   case Failure<Location>():
///     print('Failed to get location: ${result.exception.message}');
/// }
/// ```
class GetCurrentLocationUseCase extends BaseUseCase<NoParams, Location> {
  final LocationRepository _repository;

  /// Creates a GetCurrentLocationUseCase with the required repository
  ///
  /// [_repository] - Repository implementation for location data access
  GetCurrentLocationUseCase(this._repository);

  @override
  Future<Result<Location>> call(NoParams params) async {
    // Delegate to repository for location retrieval
    // In a more complex scenario, this might include additional business logic
    // such as caching, validation, or location processing
    return await _repository.getCurrentLocation();
  }
}
