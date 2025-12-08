import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/types/result.dart';
import 'package:chinese_food_app/core/exceptions/unified_exceptions_export.dart';

void main() {
  group('Result<T> Type System', () {
    group('Success Type', () {
      test('should create Success with data', () {
        // Act
        const result = Success<String>('test data');

        // Assert
        expect(result, isA<Success<String>>());
        expect(result, isA<Result<String>>());
        expect(result.data, equals('test data'));
      });

      test('should support different data types', () {
        // Act
        const stringResult = Success<String>('text');
        const intResult = Success<int>(42);
        const boolResult = Success<bool>(true);

        // Assert
        expect(stringResult.data, equals('text'));
        expect(intResult.data, equals(42));
        expect(boolResult.data, isTrue);
      });

      test('should support nullable data types', () {
        // Act
        const nullResult = Success<String?>(null);
        const valueResult = Success<String?>('value');

        // Assert
        expect(nullResult.data, isNull);
        expect(valueResult.data, equals('value'));
      });

      test('should support complex data types', () {
        // Arrange
        final testMap = {'key': 'value', 'number': 123};
        final testList = [1, 2, 3, 4, 5];

        // Act
        final mapResult = Success<Map<String, dynamic>>(testMap);
        final listResult = Success<List<int>>(testList);

        // Assert
        expect(mapResult.data, equals(testMap));
        expect(listResult.data, equals(testList));
      });
    });

    group('Failure Type', () {
      test('should create Failure with exception', () {
        // Arrange
        final exception = BaseException('Test error');

        // Act
        final result = Failure<String>(exception);

        // Assert
        expect(result, isA<Failure<String>>());
        expect(result, isA<Result<String>>());
        expect(result.exception, equals(exception));
        expect(result.exception.message, equals('Test error'));
      });

      test('should support different exception types', () {
        // Arrange
        final validationException = ValidationException('Invalid input');
        final networkException =
            UnifiedNetworkException.connection('Network error');
        final apiException = UnifiedNetworkException.api('API failed');

        // Act
        final validationResult = Failure<String>(validationException);
        final networkResult = Failure<int>(networkException);
        final apiResult = Failure<bool>(apiException);

        // Assert
        expect(validationResult.exception, isA<ValidationException>());
        expect(networkResult.exception, isA<UnifiedNetworkException>());
        expect(apiResult.exception, isA<UnifiedNetworkException>());
      });

      test('should preserve exception hierarchy', () {
        // Arrange
        final locationException = LocationException('Location error');
        final databaseException = DatabaseException('Database error');

        // Act
        final locationResult = Failure<String>(locationException);
        final databaseResult = Failure<String>(databaseException);

        // Assert
        expect(locationResult.exception, isA<BaseException>());
        expect(databaseResult.exception, isA<BaseException>());
        expect(locationResult.exception, isA<LocationException>());
        expect(databaseResult.exception, isA<DatabaseException>());
      });
    });

    group('Type Safety', () {
      test('should maintain type safety for Success', () {
        // Act
        const stringResult = Success<String>('text');
        const intResult = Success<int>(42);

        // Assert
        expect(stringResult, isA<Result<String>>());
        expect(stringResult, isNot(isA<Result<int>>()));
        expect(intResult, isA<Result<int>>());
        expect(intResult, isNot(isA<Result<String>>()));
      });

      test('should maintain type safety for Failure', () {
        // Arrange
        final exception = BaseException('Error');

        // Act
        final stringFailure = Failure<String>(exception);
        final intFailure = Failure<int>(exception);

        // Assert
        expect(stringFailure, isA<Result<String>>());
        expect(stringFailure, isNot(isA<Result<int>>()));
        expect(intFailure, isA<Result<int>>());
        expect(intFailure, isNot(isA<Result<String>>()));
      });
    });

    group('Pattern Matching Support', () {
      test('should support switch expressions for pattern matching', () {
        // Arrange
        const successResult = Success<String>('success');
        final failureResult = Failure<String>(BaseException('error'));

        // Act & Assert
        String successMessage = switch (successResult) {
          Success<String>() => 'Got success: ${successResult.data}',
        };
        expect(successMessage, equals('Got success: success'));

        String failureMessage = switch (failureResult) {
          Failure<String>() =>
            'Got failure: ${failureResult.exception.message}',
        };
        expect(failureMessage, equals('Got failure: error'));
      });

      test('should support is-type checking', () {
        // Arrange
        const success = Success<int>(42);
        final failure = Failure<int>(BaseException('error'));

        // Act & Assert
        expect(success, isA<Success<int>>());
        expect(failure, isA<Failure<int>>());
      });
    });

    group('Equality and Hash Code', () {
      test('should implement equality for Success', () {
        // Act
        const result1 = Success<String>('test');
        const result2 = Success<String>('test');
        const result3 = Success<String>('different');

        // Assert
        expect(result1, equals(result2));
        expect(result1, isNot(equals(result3)));
      });

      test('should implement equality for Failure', () {
        // Arrange
        final exception1 = BaseException('error');
        final exception2 = BaseException('error');
        final exception3 = BaseException('different');

        // Act
        final result1 = Failure<String>(exception1);
        final result2 = Failure<String>(exception2);
        final result3 = Failure<String>(exception3);

        // Assert
        expect(result1, equals(result2));
        expect(result1, isNot(equals(result3)));
      });

      test('should have consistent hash codes', () {
        // Arrange
        const success1 = Success<String>('test');
        const success2 = Success<String>('test');
        final failure1 = Failure<String>(BaseException('error'));
        final failure2 = Failure<String>(BaseException('error'));

        // Assert
        expect(success1.hashCode, equals(success2.hashCode));
        expect(failure1.hashCode, equals(failure2.hashCode));
      });
    });

    group('toString Representation', () {
      test('should provide readable toString for Success', () {
        // Act
        const result = Success<String>('test data');

        // Assert
        expect(result.toString(), contains('Success'));
        expect(result.toString(), contains('test data'));
      });

      test('should provide readable toString for Failure', () {
        // Arrange
        final exception = BaseException('test error');

        // Act
        final result = Failure<String>(exception);

        // Assert
        expect(result.toString(), contains('Failure'));
        expect(result.toString(), contains('test error'));
      });
    });

    group('Utility Methods', () {
      test('should provide isSuccess getter', () {
        // Arrange
        const success = Success<String>('data');
        final failure = Failure<String>(BaseException('error'));

        // Assert
        expect(success.isSuccess, isTrue);
        expect(failure.isSuccess, isFalse);
      });

      test('should provide isFailure getter', () {
        // Arrange
        const success = Success<String>('data');
        final failure = Failure<String>(BaseException('error'));

        // Assert
        expect(success.isFailure, isFalse);
        expect(failure.isFailure, isTrue);
      });

      test('should provide safe data access', () {
        // Arrange
        const success = Success<String>('data');
        final failure = Failure<String>(BaseException('error'));

        // Assert
        expect(success.dataOrNull, equals('data'));
        expect(failure.dataOrNull, isNull);
      });

      test('should provide safe exception access', () {
        // Arrange
        const success = Success<String>('data');
        final failure = Failure<String>(BaseException('error'));

        // Assert
        expect(success.exceptionOrNull, isNull);
        expect(failure.exceptionOrNull, isNotNull);
        expect(failure.exceptionOrNull?.message, equals('error'));
      });
    });
  });
}
