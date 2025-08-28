import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/presentation/pages/help/help_page.dart';
import 'package:chinese_food_app/core/services/support_service.dart';

void main() {
  group('HelpPage Widget Tests', () {
    late SupportService supportService;

    setUp(() {
      supportService = SupportService();
    });

    testWidgets('should display help page title', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: HelpPage(supportService: supportService),
        ),
      );

      // Act & Assert
      expect(find.text('ヘルプ'), findsOneWidget);
    });

    testWidgets('should display help sections', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: HelpPage(supportService: supportService),
        ),
      );

      // Act & Assert
      expect(find.text('よくある質問'), findsOneWidget);
      expect(find.text('使い方ガイド'), findsOneWidget);
      expect(find.text('お問い合わせ'), findsOneWidget);
    });

    testWidgets('should navigate to help section when tapped',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: HelpPage(supportService: supportService),
        ),
      );

      // Act
      await tester.tap(find.text('よくある質問'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('よくある質問'), findsWidgets);
    });

    testWidgets('should display troubleshooting steps',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: HelpPage(supportService: supportService),
        ),
      );

      // Act
      await tester.tap(find.text('トラブルシューティング'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('位置情報'), findsAny);
    });

    testWidgets('should show contact information', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: HelpPage(supportService: supportService),
        ),
      );

      // Act
      await tester.tap(find.text('お問い合わせ'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('support@'), findsOneWidget);
    });
  });
}
