import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_food_app/core/types/result.dart';
import 'package:chinese_food_app/domain/entities/legal_document.dart';
import 'package:chinese_food_app/domain/repositories/legal_document_repository.dart';
import 'package:chinese_food_app/domain/usecases/get_legal_document_usecase.dart';

class FakeLegalDocumentRepository implements LegalDocumentRepository {
  final Map<String, LegalDocument> _documentsById = {};
  final Map<LegalDocumentType, LegalDocument> _documentsByType = {};
  bool shouldThrowException = false;

  void setDocumentById(String id, LegalDocument document) {
    _documentsById[id] = document;
  }

  void setDocumentByType(LegalDocumentType type, LegalDocument document) {
    _documentsByType[type] = document;
  }

  @override
  Future<LegalDocument?> getDocument(String id) async {
    if (shouldThrowException) throw Exception('Database error');
    return _documentsById[id];
  }

  @override
  Future<LegalDocument?> getDocumentByType(LegalDocumentType type) async {
    if (shouldThrowException) throw Exception('Database error');
    return _documentsByType[type];
  }

  @override
  Future<List<LegalDocument>> getAllDocuments() async {
    return [];
  }

  @override
  Future<void> saveDocument(LegalDocument document) async {}

  @override
  Future<void> deleteDocument(String id) async {}

  @override
  Future<bool> isDocumentAccepted(String userId, LegalDocumentType type) async {
    return false;
  }

  @override
  Future<void> markDocumentAccepted(
      String userId, LegalDocumentType type) async {}
}

void main() {
  group('GetLegalDocumentUseCase', () {
    late FakeLegalDocumentRepository repository;
    late GetLegalDocumentUseCase usecase;

    setUp(() {
      repository = FakeLegalDocumentRepository();
      usecase = GetLegalDocumentUseCase(repository);
    });

    test('should return legal document when it exists', () async {
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

      repository.setDocumentByType(LegalDocumentType.privacyPolicy, document);

      // Act
      final result = await usecase(
          GetLegalDocumentParams(type: LegalDocumentType.privacyPolicy));

      // Assert
      expect(result, isA<Success<LegalDocument>>());
      final success = result as Success<LegalDocument>;
      expect(success.data.id, equals('privacy-policy'));
      expect(success.data.type, equals(LegalDocumentType.privacyPolicy));
    });

    test('should return failure when document does not exist', () async {
      // Arrange - Repository has no document set

      // Act
      final result = await usecase(
          GetLegalDocumentParams(type: LegalDocumentType.privacyPolicy));

      // Assert
      expect(result, isA<Failure<LegalDocument>>());
      final failure = result as Failure<LegalDocument>;
      expect(failure.exception.message, contains('法的文書が見つかりません'));
    });

    test('should return failure when repository throws exception', () async {
      // Arrange
      repository.shouldThrowException = true;

      // Act
      final result = await usecase(
          GetLegalDocumentParams(type: LegalDocumentType.privacyPolicy));

      // Assert
      expect(result, isA<Failure<LegalDocument>>());
      final failure = result as Failure<LegalDocument>;
      expect(failure.exception.message, contains('法的文書の取得に失敗しました'));
    });

    test('should get document by ID when specified', () async {
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

      repository.setDocumentById('terms-of-service', document);

      // Act
      final result =
          await usecase(GetLegalDocumentParams(id: 'terms-of-service'));

      // Assert
      expect(result, isA<Success<LegalDocument>>());
      final success = result as Success<LegalDocument>;
      expect(success.data.id, equals('terms-of-service'));
      expect(success.data.type, equals(LegalDocumentType.termsOfService));
    });
  });

  group('GetLegalDocumentParams', () {
    test('should create params with type', () {
      // Arrange & Act
      final params =
          GetLegalDocumentParams(type: LegalDocumentType.privacyPolicy);

      // Assert
      expect(params.type, equals(LegalDocumentType.privacyPolicy));
      expect(params.id, isNull);
    });

    test('should create params with id', () {
      // Arrange & Act
      final params = GetLegalDocumentParams(id: 'test-id');

      // Assert
      expect(params.id, equals('test-id'));
      expect(params.type, isNull);
    });

    test('should throw assertion error when both id and type are null', () {
      // Assert
      expect(
        () => GetLegalDocumentParams(),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
