import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/presentation/widgets/api_attribution_widget.dart';

void main() {
  group('ApiAttributionWidget', () {
    testWidgets('should display HotPepper attribution', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ApiAttributionWidget(
              apiType: ApiAttributionType.hotpepper,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Powered by HotPepper グルメサーチAPI'), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('should display Google Maps attribution', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ApiAttributionWidget(
              apiType: ApiAttributionType.googleMaps,
            ),
          ),
        ),
      );

      // Assert
      expect(find.textContaining('Google'), findsOneWidget);
    });

    testWidgets('should display OpenStreetMap attribution', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ApiAttributionWidget(
              apiType: ApiAttributionType.openStreetMap,
            ),
          ),
        ),
      );

      // Assert
      expect(find.textContaining('OpenStreetMap'), findsOneWidget);
    });

    testWidgets('should handle tap on attribution link', (WidgetTester tester) async {
      // Arrange
      bool linkTapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ApiAttributionWidget(
              apiType: ApiAttributionType.hotpepper,
              onLinkTap: () {
                linkTapped = true;
              },
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();

      // Assert
      expect(linkTapped, isTrue);
    });

    testWidgets('should display with correct styling', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ApiAttributionWidget(
              apiType: ApiAttributionType.hotpepper,
            ),
          ),
        ),
      );

      // Assert
      final textButton = tester.widget<TextButton>(find.byType(TextButton));
      expect(textButton.style?.textStyle?.resolve({}), isNotNull);
    });

    group('ApiAttributionType', () {
      test('should have correct display text', () {
        expect(ApiAttributionType.hotpepper.displayText, equals('Powered by HotPepper グルメサーチAPI'));
        expect(ApiAttributionType.googleMaps.displayText, contains('Google'));
        expect(ApiAttributionType.openStreetMap.displayText, contains('OpenStreetMap'));
      });

      test('should have correct URLs', () {
        expect(ApiAttributionType.hotpepper.url, contains('recruit'));
        expect(ApiAttributionType.googleMaps.url, contains('google'));
        expect(ApiAttributionType.openStreetMap.url, contains('openstreetmap'));
      });
    });
  });
}