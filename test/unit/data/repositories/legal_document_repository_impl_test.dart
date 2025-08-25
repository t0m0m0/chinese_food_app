import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/types/result.dart';
import 'package:chinese_food_app/domain/entities/legal_document.dart';
import 'package:chinese_food_app/data/repositories/legal_document_repository_impl.dart';
import 'package:chinese_food_app/data/datasources/legal_document_local_datasource.dart';

class FakeLegalDocumentLocalDatasource implements LegalDocumentLocalDatasource {
  final Map<String, LegalDocument> _documents = {};
  final Map<String, Map<LegalDocumentType, bool>> _acceptanceStatus = {};

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
    return _acceptanceStatus[userId]?[type] ?? false;
  }

  @override
  Future<void> markDocumentAccepted(String userId, LegalDocumentType type) async {
    _acceptanceStatus[userId] ??= {};
    _acceptanceStatus[userId]![type] = true;
  }

  void addDocument(LegalDocument document) {
    _documents[document.id] = document;
  }
}

void main() {
  group('LegalDocumentRepositoryImpl', () {
    late FakeLegalDocumentLocalDatasource datasource;
    late LegalDocumentRepositoryImpl repository;

    setUp(() {
      datasource = FakeLegalDocumentLocalDatasource();
      repository = LegalDocumentRepositoryImpl(datasource);
    });

    test('should get document by id', () async {
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
      
      datasource.addDocument(document);

      // Act
      final result = await repository.getDocument('privacy-policy');

      // Assert
      expect(result?.id, equals('privacy-policy'));
      expect(result?.type, equals(LegalDocumentType.privacyPolicy));
    });

    test('should get document by type', () async {
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
      
      datasource.addDocument(document);

      // Act
      final result = await repository.getDocumentByType(LegalDocumentType.termsOfService);

      // Assert
      expect(result?.id, equals('terms-of-service'));
      expect(result?.type, equals(LegalDocumentType.termsOfService));
    });

    test('should save document', () async {
      // Arrange
      final document = LegalDocument(
        id: 'test-doc',
        type: LegalDocumentType.apiAttribution,
        title: 'テスト文書',
        content: 'テスト内容',
        version: '1.0.0',
        effectiveDate: DateTime.parse('2024-08-25'),
        lastUpdated: DateTime.parse('2024-08-25'),
      );

      // Act
      await repository.saveDocument(document);
      final retrieved = await repository.getDocument('test-doc');

      // Assert
      expect(retrieved?.id, equals('test-doc'));
      expect(retrieved?.type, equals(LegalDocumentType.apiAttribution));
    });

    test('should delete document', () async {
      // Arrange
      final document = LegalDocument(
        id: 'delete-me',
        type: LegalDocumentType.privacyPolicy,
        title: '削除テスト',
        content: 'このドキュメントは削除されます',
        version: '1.0.0',
        effectiveDate: DateTime.parse('2024-08-25'),
        lastUpdated: DateTime.parse('2024-08-25'),
      );
      
      datasource.addDocument(document);
      expect(await repository.getDocument('delete-me'), isNotNull);

      // Act
      await repository.deleteDocument('delete-me');

      // Assert
      expect(await repository.getDocument('delete-me'), isNull);
    });

    test('should track document acceptance status', () async {
      // Arrange
      const userId = 'user-123';
      
      // Act & Assert - Initially not accepted
      expect(await repository.isDocumentAccepted(userId, LegalDocumentType.privacyPolicy), isFalse);
      
      // Mark as accepted
      await repository.markDocumentAccepted(userId, LegalDocumentType.privacyPolicy);
      
      // Should now be accepted
      expect(await repository.isDocumentAccepted(userId, LegalDocumentType.privacyPolicy), isTrue);
      
      // Other types should still be false
      expect(await repository.isDocumentAccepted(userId, LegalDocumentType.termsOfService), isFalse);
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
      
      datasource.addDocument(privacyPolicy);
      datasource.addDocument(termsOfService);

      // Act
      final allDocs = await repository.getAllDocuments();

      // Assert
      expect(allDocs.length, equals(2));
      expect(allDocs.any((doc) => doc.type == LegalDocumentType.privacyPolicy), isTrue);
      expect(allDocs.any((doc) => doc.type == LegalDocumentType.termsOfService), isTrue);
    });
  });
}