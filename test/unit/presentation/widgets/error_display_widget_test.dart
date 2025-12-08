import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/presentation/widgets/error_display_widget.dart';
import 'package:chinese_food_app/core/exceptions/unified_exceptions_export.dart';

void main() {
  group('ErrorDisplayWidget', () {
    testWidgets('should display error message in SnackBar',
        (WidgetTester tester) async {
      // Arrange
      const errorMessage = 'ネットワークエラーが発生しました';
      final exception = UnifiedNetworkException.connection('Connection failed');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ErrorDisplayWidget.showError(
                        context, exception, errorMessage);
                  },
                  child: const Text('Show Error'),
                );
              },
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Show Error'));
      await tester.pump();

      // Assert
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('should display error dialog for critical errors',
        (WidgetTester tester) async {
      // Arrange
      const errorMessage = 'データベースエラーが発生しました';
      final exception = DatabaseException('Database connection failed');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ErrorDisplayWidget.showErrorDialog(
                        context, exception, errorMessage);
                  },
                  child: const Text('Show Error Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Show Error Dialog'));
      await tester.pump();

      // Assert
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('エラー'), findsOneWidget);
      expect(find.text(errorMessage), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('should show retry button for network errors',
        (WidgetTester tester) async {
      // Arrange
      const errorMessage = 'ネットワークエラーが発生しました';
      final exception = UnifiedNetworkException.connection('Connection failed');
      bool retryPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ErrorDisplayWidget.showErrorDialog(
                      context,
                      exception,
                      errorMessage,
                      onRetry: () {
                        retryPressed = true;
                      },
                    );
                  },
                  child: const Text('Show Error Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Show Error Dialog'));
      await tester.pump();
      await tester.tap(find.text('再試行'));
      await tester.pump();

      // Assert
      expect(retryPressed, true);
    });

    testWidgets('should display inline error widget',
        (WidgetTester tester) async {
      // Arrange
      const errorMessage = 'データの読み込みに失敗しました';
      final exception = UnifiedNetworkException.connection('Connection failed');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDisplayWidget.inline(
              exception: exception,
              message: errorMessage,
              onRetry: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text(errorMessage), findsOneWidget);
      expect(find.text('再試行'), findsOneWidget);
    });
  });
}
