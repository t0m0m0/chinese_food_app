import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/domain/entities/legal_document.dart';

void main() {
  group('LegalDocument', () {
    test('should create privacy policy document with required fields', () {
      // Arrange & Act
      final privacyPolicy = LegalDocument(
        id: 'privacy-policy',
        type: LegalDocumentType.privacyPolicy,
        title: 'プライバシーポリシー',
        content: 'プライバシーポリシーの内容',
        version: '1.0.0',
        effectiveDate: DateTime.parse('2024-08-25'),
        lastUpdated: DateTime.parse('2024-08-25'),
      );

      // Assert
      expect(privacyPolicy.id, equals('privacy-policy'));
      expect(privacyPolicy.type, equals(LegalDocumentType.privacyPolicy));
      expect(privacyPolicy.title, equals('プライバシーポリシー'));
      expect(privacyPolicy.content, equals('プライバシーポリシーの内容'));
      expect(privacyPolicy.version, equals('1.0.0'));
      expect(privacyPolicy.effectiveDate, equals(DateTime.parse('2024-08-25')));
      expect(privacyPolicy.lastUpdated, equals(DateTime.parse('2024-08-25')));
    });

    test('should create terms of service document with required fields', () {
      // Arrange & Act
      final termsOfService = LegalDocument(
        id: 'terms-of-service',
        type: LegalDocumentType.termsOfService,
        title: '利用規約',
        content: '利用規約の内容',
        version: '1.0.0',
        effectiveDate: DateTime.parse('2024-08-25'),
        lastUpdated: DateTime.parse('2024-08-25'),
      );

      // Assert
      expect(termsOfService.id, equals('terms-of-service'));
      expect(termsOfService.type, equals(LegalDocumentType.termsOfService));
      expect(termsOfService.title, equals('利用規約'));
    });

    test('should validate required fields are not empty', () {
      // Assert
      expect(
        () => LegalDocument(
          id: '',
          type: LegalDocumentType.privacyPolicy,
          title: 'タイトル',
          content: 'コンテンツ',
          version: '1.0.0',
          effectiveDate: DateTime.now(),
          lastUpdated: DateTime.now(),
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => LegalDocument(
          id: 'test',
          type: LegalDocumentType.privacyPolicy,
          title: '',
          content: 'コンテンツ',
          version: '1.0.0',
          effectiveDate: DateTime.now(),
          lastUpdated: DateTime.now(),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should check if document needs update based on effective date', () {
      // Arrange
      final futureDate = DateTime.now().add(const Duration(days: 30));
      final document = LegalDocument(
        id: 'test',
        type: LegalDocumentType.privacyPolicy,
        title: 'タイトル',
        content: 'コンテンツ',
        version: '1.0.0',
        effectiveDate: futureDate,
        lastUpdated: DateTime.now(),
      );

      // Act & Assert
      expect(document.isEffective, isFalse);

      // Test with past date
      final pastDate = DateTime.now().subtract(const Duration(days: 1));
      final effectiveDocument = LegalDocument(
        id: 'test',
        type: LegalDocumentType.privacyPolicy,
        title: 'タイトル',
        content: 'コンテンツ',
        version: '1.0.0',
        effectiveDate: pastDate,
        lastUpdated: DateTime.now(),
      );

      expect(effectiveDocument.isEffective, isTrue);
    });
  });

  group('LegalDocumentType', () {
    test('should have correct display names', () {
      expect(LegalDocumentType.privacyPolicy.displayName, equals('プライバシーポリシー'));
      expect(LegalDocumentType.termsOfService.displayName, equals('利用規約'));
      expect(LegalDocumentType.apiAttribution.displayName, equals('API利用規約'));
    });
  });
}
