import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chinese_food_app/presentation/widgets/app_review_prompt_dialog.dart';
import 'package:chinese_food_app/core/services/app_review_service.dart';

void main() {
  group('AppReviewPromptDialog', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() async {
      await AppReviewService.clearAllRecords();
    });

    testWidgets('should display review prompt dialog correctly',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppReviewPromptDialog(),
          ),
        ),
      );

      // Assert
      expect(find.text('アプリを評価してください'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsWidgets);
      expect(find.text('後で'), findsOneWidget);
      expect(find.text('レビューする'), findsOneWidget);
      expect(find.textContaining('マチアプ'), findsOneWidget);
      expect(find.textContaining('ありがとうございます'), findsOneWidget);
    });

    testWidgets('should handle decline button tap', (tester) async {
      // Arrange
      bool declineCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppReviewPromptDialog(
              onReviewDeclined: () {
                declineCalled = true;
              },
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('後で'));
      await tester.pumpAndSettle();

      // Assert
      expect(declineCalled, isTrue);
      expect(await AppReviewService.isReviewDeclined(), isTrue);
    });

    testWidgets('should handle review button tap', (tester) async {
      // Arrange
      bool reviewCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppReviewPromptDialog(
              onReviewCompleted: () {
                reviewCalled = true;
              },
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('レビューする'));
      await tester.pumpAndSettle();

      // Assert
      expect(reviewCalled, isTrue);
    });

    testWidgets('should show if appropriate conditions are met',
        (tester) async {
      // Arrange
      await AppReviewService.triggerReviewPrompt(); // Debug method

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  await AppReviewPromptDialog.showIfAppropriate(context);
                },
                child: const Text('Check Review'),
              ),
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Check Review'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('アプリを評価してください'), findsOneWidget);
    });

    testWidgets('should not show if conditions not met', (tester) async {
      // Arrange - Don't set up conditions
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  await AppReviewPromptDialog.showIfAppropriate(context);
                },
                child: const Text('Check Review'),
              ),
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Check Review'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('アプリを評価してください'), findsNothing);
    });
  });

  group('AppReviewBanner', () {
    testWidgets('should display review banner correctly', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppReviewBanner(),
          ),
        ),
      );

      // Assert
      expect(find.text('気に入っていただけましたか？'), findsOneWidget);
      expect(find.text('レビューでアプリを応援してください'), findsOneWidget);
      expect(find.byIcon(Icons.star_rate_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('should handle tap action', (tester) async {
      // Arrange
      bool tapCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppReviewBanner(
              onTap: () {
                tapCalled = true;
              },
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('気に入っていただけましたか？'));
      await tester.pumpAndSettle();

      // Assert
      expect(tapCalled, isTrue);
    });

    testWidgets('should handle dismiss action', (tester) async {
      // Arrange
      bool dismissCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppReviewBanner(
              onDismiss: () {
                dismissCalled = true;
              },
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Assert
      expect(dismissCalled, isTrue);
    });
  });

  group('AppReviewThanksDialog', () {
    testWidgets('should display thanks dialog correctly', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppReviewThanksDialog(),
          ),
        ),
      );

      // Assert
      expect(find.text('ありがとうございます！'), findsOneWidget);
      expect(find.text('探索を続ける'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.textContaining('レビューをいただき'), findsOneWidget);
      expect(find.textContaining('マチアプ'), findsOneWidget);
    });

    testWidgets('should handle continue button tap', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppReviewThanksDialog(),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('探索を続ける'));
      await tester.pumpAndSettle();

      // Assert - Dialog should close (we can't test navigation directly)
      expect(find.text('探索を続ける'), findsOneWidget);
    });

    testWidgets('should show via static method', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppReviewThanksDialog.show(context);
                },
                child: const Text('Show Thanks'),
              ),
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Show Thanks'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('ありがとうございます！'), findsOneWidget);
    });
  });

  group('AppReviewHelper', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('should check on app launch', (tester) async {
      // Arrange
      await AppReviewService.triggerReviewPrompt(); // Set up conditions

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  await AppReviewHelper.checkOnAppLaunch(context);
                },
                child: const Text('Launch Check'),
              ),
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Launch Check'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('アプリを評価してください'), findsOneWidget);
    });

    testWidgets('should check on store visit', (tester) async {
      // Arrange
      await AppReviewService.triggerReviewPrompt(); // Set up conditions

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  await AppReviewHelper.checkOnStoreVisit(context);
                },
                child: const Text('Visit Check'),
              ),
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Visit Check'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('アプリを評価してください'), findsOneWidget);
    });

    testWidgets('should check on action complete', (tester) async {
      // Arrange
      await AppReviewService.triggerReviewPrompt(); // Set up conditions

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  await AppReviewHelper.checkOnActionComplete(
                    context,
                    incrementSession: true,
                    incrementStoreVisit: true,
                  );
                },
                child: const Text('Action Check'),
              ),
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Action Check'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('アプリを評価してください'), findsOneWidget);
    });

    testWidgets('should not show when conditions not met', (tester) async {
      // Arrange - Don't set up conditions
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  await AppReviewHelper.checkOnAppLaunch(context);
                },
                child: const Text('Launch Check'),
              ),
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Launch Check'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('アプリを評価してください'), findsNothing);
    });
  });
}
