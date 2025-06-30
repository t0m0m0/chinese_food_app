import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/domain/usecases/base_usecase.dart';
import 'package:chinese_food_app/core/types/result.dart';
import 'package:chinese_food_app/core/exceptions/app_exception.dart';

void main() {
  group('BaseUseCase Abstract Interface', () {
    group('Contract Definition', () {
      test('should define abstract call method', () {
        // This test verifies that BaseUseCase is properly defined as an abstract class
        // with the required call method. Since it's abstract, we test via concrete implementations.
        expect(BaseUseCase, isA<Type>());
      });

      test('should require call method implementation', () {
        // Arrange & Act - This will be tested via concrete implementations
        // Assert - Method signature verification happens at compile time
        expect(() => _TestUseCase(), returnsNormally);
      });

      test('should support parameterless use cases', () {
        // Arrange & Act
        final useCase = _ParameterlessUseCase();
        
        // Assert
        expect(useCase, isA<BaseUseCase<NoParams, String>>());
      });

      test('should support parameterized use cases', () {
        // Arrange & Act
        final useCase = _ParameterizedUseCase();
        
        // Assert  
        expect(useCase, isA<BaseUseCase<_TestParams, int>>());
      });
    });

    group('Return Types', () {
      test('should return Future<Result<T>> from call method', () async {
        // Arrange
        final useCase = _TestUseCase();

        // Act
        final result = useCase.call('test');

        // Assert
        expect(result, isA<Future<Result<String>>>());
      });

      test('should handle Success cases', () async {
        // Arrange
        final useCase = _SuccessUseCase();

        // Act
        final result = await useCase.call('input');

        // Assert
        expect(result, isA<Success<String>>());
        expect((result as Success<String>).data, equals('Success: input'));
      });

      test('should handle Failure cases', () async {
        // Arrange
        final useCase = _FailureUseCase();

        // Act
        final result = await useCase.call('input');

        // Assert
        expect(result, isA<Failure<String>>());
        expect((result as Failure<String>).exception, isA<AppException>());
      });
    });

    group('Parameter Handling', () {
      test('should support NoParams for parameterless use cases', () {
        // Arrange
        final useCase = _ParameterlessUseCase();
        const params = NoParams();

        // Act & Assert
        expect(() => useCase.call(params), returnsNormally);
      });

      test('should support custom parameter types', () {
        // Arrange
        final useCase = _ParameterizedUseCase();
        final params = _TestParams('test', 42);

        // Act & Assert
        expect(() => useCase.call(params), returnsNormally);
      });

      test('should maintain type safety for parameters', () {
        // Arrange
        final stringUseCase = _StringParamUseCase();
        final intUseCase = _IntParamUseCase();

        // Act & Assert
        expect(stringUseCase, isA<BaseUseCase<String, String>>());
        expect(intUseCase, isA<BaseUseCase<int, int>>());
      });
    });

    group('Error Handling', () {
      test('should propagate exceptions as Failure results', () async {
        // Arrange
        final useCase = _ExceptionThrowingUseCase();

        // Act
        final result = await useCase.call('trigger-error');

        // Assert
        expect(result, isA<Failure<String>>());
        final failure = result as Failure<String>;
        expect(failure.exception.message, contains('Test exception'));
      });

      test('should handle different exception types', () async {
        // Arrange
        final useCase = _MultipleExceptionUseCase();

        // Act
        final validationResult = await useCase.call('validation-error');
        final networkResult = await useCase.call('network-error');
        final genericResult = await useCase.call('generic-error');

        // Assert
        expect(validationResult, isA<Failure<String>>());
        expect(networkResult, isA<Failure<String>>());
        expect(genericResult, isA<Failure<String>>());
      });

      test('should preserve exception details', () async {
        // Arrange
        final useCase = _DetailedExceptionUseCase();

        // Act
        final result = await useCase.call('detailed-error');

        // Assert
        expect(result, isA<Failure<String>>());
        final failure = result as Failure<String>;
        expect(failure.exception.message, equals('Detailed error message'));
        expect(failure.exception.severity, equals(ExceptionSeverity.high));
      });
    });

    group('UseCase Composition', () {
      test('should support chaining use cases', () async {
        // Arrange
        final firstUseCase = _FirstStepUseCase();
        final secondUseCase = _SecondStepUseCase();

        // Act
        final firstResult = await firstUseCase.call('input');
        if (firstResult is Success<String>) {
          final secondResult = await secondUseCase.call(firstResult.data);
          
          // Assert
          expect(secondResult, isA<Success<String>>());
          expect((secondResult as Success<String>).data, 
                 equals('Second: First: input'));
        } else {
          fail('First step should succeed');
        }
      });

      test('should handle failure propagation in chains', () async {
        // Arrange
        final failingUseCase = _FailureUseCase();
        final secondUseCase = _SecondStepUseCase();

        // Act
        final firstResult = await failingUseCase.call('input');
        
        // Assert
        expect(firstResult, isA<Failure<String>>());
        // Second use case should not be called if first fails
      });
    });

    group('Async Behavior', () {
      test('should handle async operations correctly', () async {
        // Arrange
        final useCase = _AsyncUseCase();

        // Act
        final startTime = DateTime.now();
        final result = await useCase.call('async-test');
        final endTime = DateTime.now();

        // Assert
        expect(result, isA<Success<String>>());
        expect(endTime.difference(startTime).inMilliseconds, greaterThan(100));
      });

      test('should support concurrent execution', () async {
        // Arrange
        final useCase = _AsyncUseCase();
        final futures = <Future<Result<String>>>[];

        // Act - Start multiple concurrent operations
        for (int i = 0; i < 3; i++) {
          futures.add(useCase.call('concurrent-$i'));
        }

        final results = await Future.wait(futures);

        // Assert
        expect(results, hasLength(3));
        for (final result in results) {
          expect(result, isA<Success<String>>());
        }
      });
    });
  });
}

// Test implementations for testing the abstract interface

class _TestUseCase extends BaseUseCase<String, String> {
  @override
  Future<Result<String>> call(String params) async {
    return Success('Processed: $params');
  }
}

class _ParameterlessUseCase extends BaseUseCase<NoParams, String> {
  @override
  Future<Result<String>> call(NoParams params) async {
    return const Success('No parameters needed');
  }
}

class _ParameterizedUseCase extends BaseUseCase<_TestParams, int> {
  @override
  Future<Result<int>> call(_TestParams params) async {
    return Success(params.value * 2);
  }
}

class _SuccessUseCase extends BaseUseCase<String, String> {
  @override
  Future<Result<String>> call(String params) async {
    return Success('Success: $params');
  }
}

class _FailureUseCase extends BaseUseCase<String, String> {
  @override
  Future<Result<String>> call(String params) async {
    return Failure(AppException('Use case failed'));
  }
}

class _StringParamUseCase extends BaseUseCase<String, String> {
  @override
  Future<Result<String>> call(String params) async {
    return Success(params.toUpperCase());
  }
}

class _IntParamUseCase extends BaseUseCase<int, int> {
  @override
  Future<Result<int>> call(int params) async {
    return Success(params * 2);
  }
}

class _ExceptionThrowingUseCase extends BaseUseCase<String, String> {
  @override
  Future<Result<String>> call(String params) async {
    try {
      if (params == 'trigger-error') {
        throw Exception('Test exception');
      }
      return Success('Success');
    } catch (e) {
      return Failure(AppException('Test exception: ${e.toString()}'));
    }
  }
}

class _MultipleExceptionUseCase extends BaseUseCase<String, String> {
  @override
  Future<Result<String>> call(String params) async {
    switch (params) {
      case 'validation-error':
        return Failure(AppException('Validation failed', 
                                  severity: ExceptionSeverity.medium));
      case 'network-error':
        return Failure(AppException('Network error', 
                                  severity: ExceptionSeverity.high));
      case 'generic-error':
        return Failure(AppException('Generic error'));
      default:
        return const Success('Success');
    }
  }
}

class _DetailedExceptionUseCase extends BaseUseCase<String, String> {
  @override
  Future<Result<String>> call(String params) async {
    return Failure(AppException(
      'Detailed error message',
      severity: ExceptionSeverity.high,
    ));
  }
}

class _FirstStepUseCase extends BaseUseCase<String, String> {
  @override
  Future<Result<String>> call(String params) async {
    return Success('First: $params');
  }
}

class _SecondStepUseCase extends BaseUseCase<String, String> {
  @override
  Future<Result<String>> call(String params) async {
    return Success('Second: $params');
  }
}

class _AsyncUseCase extends BaseUseCase<String, String> {
  @override
  Future<Result<String>> call(String params) async {
    // Simulate async operation
    await Future.delayed(const Duration(milliseconds: 100));
    return Success('Processed async: $params');
  }
}

// Test parameter class
class _TestParams {
  final String name;
  final int value;

  const _TestParams(this.name, this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _TestParams &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          value == other.value;

  @override
  int get hashCode => Object.hash(name, value);
}