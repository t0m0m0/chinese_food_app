import '../../core/types/result.dart';

/// Abstract base class for all Use Cases in the Clean Architecture
///
/// Use Cases represent the business logic of the application and should be
/// independent of frameworks, UI, and external concerns. Each Use Case
/// should have a single responsibility and should be testable in isolation.
///
/// The base class provides a consistent interface for all Use Cases:
/// - Input parameters of type [Params]
/// - Output wrapped in a [Result<T>] for unified error handling
/// - Async execution with [Future] support
///
/// Example usage:
/// ```dart
/// class GetCurrentLocationUseCase extends BaseUseCase<NoParams, Location> {
///   final LocationRepository _repository;
///
///   GetCurrentLocationUseCase(this._repository);
///
///   @override
///   Future<Result<Location>> call(NoParams params) async {
///     return await _repository.getCurrentLocation();
///   }
/// }
///
/// // Usage
/// final useCase = GetCurrentLocationUseCase(repository);
/// final result = await useCase.call(NoParams());
/// switch (result) {
///   case Success<Location>():
///     handleLocation(result.data);
///   case Failure<Location>():
///     handleError(result.exception);
/// }
/// ```
abstract class BaseUseCase<Params, T> {
  /// Executes the use case with the given parameters
  ///
  /// [params] - Input parameters for the use case
  /// Returns a [Future<Result<T>>] containing either:
  /// - [Success<T>] with the operation result
  /// - [Failure<T>] with an exception describing the error
  ///
  /// Implementation requirements:
  /// - Should handle all exceptions and wrap them in [Failure]
  /// - Should validate input parameters if necessary
  /// - Should be stateless and side-effect free when possible
  /// - Should delegate complex logic to repositories and services
  Future<Result<T>> call(Params params);
}

/// Parameter class for Use Cases that don't require input parameters
///
/// Use this class when your Use Case doesn't need any input parameters.
/// It provides type safety and consistency across the Use Case interface.
///
/// Example:
/// ```dart
/// class GetUserPreferencesUseCase extends BaseUseCase<NoParams, UserPreferences> {
///   @override
///   Future<Result<UserPreferences>> call(NoParams params) async {
///     // Implementation that doesn't need parameters
///   }
/// }
/// ```
class NoParams {
  const NoParams();

  @override
  bool operator ==(Object other) => identical(this, other) || other is NoParams;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'NoParams()';
}
