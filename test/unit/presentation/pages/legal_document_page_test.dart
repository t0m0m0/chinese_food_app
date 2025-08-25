import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/presentation/pages/legal_document_page.dart';
import 'package:chinese_food_app/domain/entities/legal_document.dart';

void main() {
  group('LegalDocumentPage', () {
    late LegalDocument testDocument;

    setUp(() {
      testDocument = LegalDocument(
        id: 'privacy-policy',
        type: LegalDocumentType.privacyPolicy,
        title: 'プライバシーポリシー',
        content: 'テスト用プライバシーポリシーの内容\n\n## 第1条\n個人情報について説明します。',
        version: '1.0.0',
        effectiveDate: DateTime.parse('2024-08-25'),
        lastUpdated: DateTime.parse('2024-08-26'),
      );
    });

    testWidgets('should display document title in app bar',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: LegalDocumentPage(document: testDocument),
        ),
      );

      // Assert
      expect(find.text('プライバシーポリシー'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should display document content', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: LegalDocumentPage(document: testDocument),
        ),
      );

      // Assert
      expect(find.textContaining('テスト用プライバシーポリシーの内容'), findsOneWidget);
      expect(find.textContaining('個人情報について説明します'), findsOneWidget);
    });

    testWidgets('should display document version and dates',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: LegalDocumentPage(document: testDocument),
        ),
      );

      // Assert
      expect(find.textContaining('バージョン:'), findsOneWidget);
      expect(find.textContaining('1.0.0'), findsOneWidget);
      expect(find.textContaining('施行日:'), findsOneWidget);
      expect(find.textContaining('2024年8月25日'), findsOneWidget);
      expect(find.textContaining('最終更新:'), findsOneWidget);
      expect(find.textContaining('2024年8月26日'), findsOneWidget);
    });

    testWidgets('should have scrollable content', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: LegalDocumentPage(document: testDocument),
        ),
      );

      // Assert
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('should have proper padding for readability',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: LegalDocumentPage(document: testDocument),
        ),
      );

      // Assert
      final paddingFinder = find.byType(Padding);
      expect(paddingFinder, findsWidgets);
    });

    testWidgets('should display markdown content with proper formatting',
        (WidgetTester tester) async {
      // Arrange
      final markdownDocument = LegalDocument(
        id: 'test-doc',
        type: LegalDocumentType.termsOfService,
        title: 'テスト文書',
        content: '''
# 第1条（適用）
本規約は、アプリの利用条件を定めます。

## 第2条（定義）
以下の用語を定義します：

- **ユーザー**: アプリを利用する個人
- **サービス**: アプリが提供する機能
        ''',
        version: '1.0.0',
        effectiveDate: DateTime.parse('2024-08-25'),
        lastUpdated: DateTime.parse('2024-08-25'),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: LegalDocumentPage(document: markdownDocument),
        ),
      );

      // Assert
      expect(find.textContaining('第1条（適用）'), findsOneWidget);
      expect(find.textContaining('第2条（定義）'), findsOneWidget);
      expect(find.textContaining('ユーザー'), findsOneWidget);
      expect(find.textContaining('サービス'), findsOneWidget);
    });

    testWidgets('should handle back navigation', (WidgetTester tester) async {
      // Arrange
      bool navigationPopped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          LegalDocumentPage(document: testDocument),
                    ),
                  );
                  navigationPopped = true;
                },
                child: const Text('Navigate'),
              ),
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      // Verify we're on the legal document page
      expect(find.text('プライバシーポリシー'), findsOneWidget);

      // Go back
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Assert
      expect(navigationPopped, isTrue);
    });
  });
}
