import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/utils/store_utils.dart';
import 'package:chinese_food_app/domain/entities/store.dart';

void main() {
  group('StoreUtils Tests', () {
    late ColorScheme colorScheme;

    setUp(() {
      colorScheme = const ColorScheme.light(
        primary: Colors.blue,
        onSurfaceVariant: Colors.grey,
      );
    });

    group('getStatusColor', () {
      test('should return red color for wantToGo status', () {
        // Act
        final result =
            StoreUtils.getStatusColor(StoreStatus.wantToGo, colorScheme);

        // Assert
        expect(result, Colors.red);
      });

      test('should return green color for visited status', () {
        // Act
        final result =
            StoreUtils.getStatusColor(StoreStatus.visited, colorScheme);

        // Assert
        expect(result, Colors.green);
      });

      test('should return orange color for bad status', () {
        // Act
        final result = StoreUtils.getStatusColor(StoreStatus.bad, colorScheme);

        // Assert
        expect(result, Colors.orange);
      });

      test('should return onSurfaceVariant color for null status', () {
        // Act
        final result = StoreUtils.getStatusColor(null, colorScheme);

        // Assert
        expect(result, colorScheme.onSurfaceVariant);
      });
    });

    group('getStatusIcon', () {
      test('should return favorite icon for wantToGo status', () {
        // Act
        final result = StoreUtils.getStatusIcon(StoreStatus.wantToGo);

        // Assert
        expect(result, Icons.favorite);
      });

      test('should return check_circle icon for visited status', () {
        // Act
        final result = StoreUtils.getStatusIcon(StoreStatus.visited);

        // Assert
        expect(result, Icons.check_circle);
      });

      test('should return block icon for bad status', () {
        // Act
        final result = StoreUtils.getStatusIcon(StoreStatus.bad);

        // Assert
        expect(result, Icons.block);
      });

      test('should return restaurant icon for null status', () {
        // Act
        final result = StoreUtils.getStatusIcon(null);

        // Assert
        expect(result, Icons.restaurant);
      });
    });

    group('getStatusText', () {
      test('should return "行きたい" for wantToGo status', () {
        // Act
        final result = StoreUtils.getStatusText(StoreStatus.wantToGo);

        // Assert
        expect(result, '行きたい');
      });

      test('should return "行った" for visited status', () {
        // Act
        final result = StoreUtils.getStatusText(StoreStatus.visited);

        // Assert
        expect(result, '行った');
      });

      test('should return "興味なし" for bad status', () {
        // Act
        final result = StoreUtils.getStatusText(StoreStatus.bad);

        // Assert
        expect(result, '興味なし');
      });

      test('should return "未設定" for null status', () {
        // Act
        final result = StoreUtils.getStatusText(null);

        // Assert
        expect(result, '未設定');
      });
    });

    group('formatDate', () {
      test('should format date correctly', () {
        // Arrange
        final testDate = DateTime(2024, 1, 1);

        // Act
        final result = StoreUtils.formatDate(testDate);

        // Assert
        expect(result, '2024/01/01');
      });

      test('should format date with double digits correctly', () {
        // Arrange
        final testDate = DateTime(2024, 12, 31);

        // Act
        final result = StoreUtils.formatDate(testDate);

        // Assert
        expect(result, '2024/12/31');
      });

      test('should pad single digit month and day with zero', () {
        // Arrange
        final testDate = DateTime(2024, 5, 7);

        // Act
        final result = StoreUtils.formatDate(testDate);

        // Assert
        expect(result, '2024/05/07');
      });
    });
  });
}
