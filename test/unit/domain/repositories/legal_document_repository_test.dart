import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/domain/entities/legal_document.dart';
import 'package:chinese_food_app/domain/repositories/legal_document_repository.dart';

class MockLegalDocumentRepository implements LegalDocumentRepository {
  final Map<String, LegalDocument> _documents = {};

  @override
  Future<LegalDocument?> getDocument(String id) async {
    return _documents[id];
  }

  @override
  Future<LegalDocument?> getDocumentByType(LegalDocumentType type) async {
    return _documents.values.where((doc) => doc.type == type).firstOrNull;
  }

  @override
  Future<List<LegalDocument>> getAllDocuments() async {
    return _documents.values.toList();
  }

  @override
  Future<void> saveDocument(LegalDocument document) async {
    _documents[document.id] = document;
  }

  @override
  Future<void> deleteDocument(String id) async {
    _documents.remove(id);
  }

  @override
  Future<bool> isDocumentAccepted(String userId, LegalDocumentType type) async {
    return true; // Mock implementation
  }

  @override
  Future<void> markDocumentAccepted(String userId, LegalDocumentType type) async {
    // Mock implementation
  }
}

void main() {
  group('LegalDocumentRepository', () {
    late MockLegalDocumentRepository repository;

    setUp(() {
      repository = MockLegalDocumentRepository();
    });

    test('should save and retrieve legal document', () async {
      // Arrange
      final document = LegalDocument(
        id: 'privacy-policy',
        type: LegalDocumentType.privacyPolicy,
        title: 'プライバシーポリシー',
        content: 'プライバシーポリシーの内容',
        version: '1.0.0',
        effectiveDate: DateTime.parse('2024-08-25'),
        lastUpdated: DateTime.parse('2024-08-25'),
      );

      // Act
      await repository.saveDocument(document);
      final retrieved = await repository.getDocument('privacy-policy');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('privacy-policy'));
      expect(retrieved.type, equals(LegalDocumentType.privacyPolicy));
      expect(retrieved.title, equals('プライバシーポリシー'));
    });

    test('should retrieve document by type', () async {
      // Arrange
      final document = LegalDocument(
        id: 'terms-of-service',
        type: LegalDocumentType.termsOfService,
        title: '利用規約',
        content: '利用規約の内容',
        version: '1.0.0',
        effectiveDate: DateTime.parse('2024-08-25'),
        lastUpdated: DateTime.parse('2024-08-25'),
      );

      // Act
      await repository.saveDocument(document);
      final retrieved = await repository.getDocumentByType(LegalDocumentType.termsOfService);

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.type, equals(LegalDocumentType.termsOfService));
      expect(retrieved.title, equals('利用規約'));
    });

    test('should get all documents', () async {
      // Arrange
      final privacyPolicy = LegalDocument(
        id: 'privacy-policy',
        type: LegalDocumentType.privacyPolicy,
        title: 'プライバシーポリシー',
        content: 'プライバシーポリシーの内容',
        version: '1.0.0',
        effectiveDate: DateTime.parse('2024-08-25'),
        lastUpdated: DateTime.parse('2024-08-25'),
      );

      final termsOfService = LegalDocument(
        id: 'terms-of-service',
        type: LegalDocumentType.termsOfService,
        title: '利用規約',
        content: '利用規約の内容',
        version: '1.0.0',
        effectiveDate: DateTime.parse('2024-08-25'),
        lastUpdated: DateTime.parse('2024-08-25'),
      );

      // Act
      await repository.saveDocument(privacyPolicy);
      await repository.saveDocument(termsOfService);
      final allDocuments = await repository.getAllDocuments();

      // Assert
      expect(allDocuments.length, equals(2));
      expect(allDocuments.any((doc) => doc.type == LegalDocumentType.privacyPolicy), isTrue);
      expect(allDocuments.any((doc) => doc.type == LegalDocumentType.termsOfService), isTrue);
    });

    test('should delete document', () async {
      // Arrange
      final document = LegalDocument(
        id: 'test-doc',
        type: LegalDocumentType.privacyPolicy,
        title: 'テスト文書',
        content: 'テスト内容',
        version: '1.0.0',
        effectiveDate: DateTime.parse('2024-08-25'),
        lastUpdated: DateTime.parse('2024-08-25'),
      );

      // Act
      await repository.saveDocument(document);
      await repository.deleteDocument('test-doc');
      final retrieved = await repository.getDocument('test-doc');

      // Assert
      expect(retrieved, isNull);
    });

    test('should track document acceptance status', () async {
      // Act & Assert
      final isAccepted = await repository.isDocumentAccepted('user-123', LegalDocumentType.privacyPolicy);
      expect(isAccepted, isTrue);
      
      // Mark as accepted should not throw
      await repository.markDocumentAccepted('user-123', LegalDocumentType.privacyPolicy);
    });
  });
}