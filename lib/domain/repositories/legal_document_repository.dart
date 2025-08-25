import '../entities/legal_document.dart';

abstract interface class LegalDocumentRepository {
  Future<LegalDocument?> getDocument(String id);
  Future<LegalDocument?> getDocumentByType(LegalDocumentType type);
  Future<List<LegalDocument>> getAllDocuments();
  Future<void> saveDocument(LegalDocument document);
  Future<void> deleteDocument(String id);
  Future<bool> isDocumentAccepted(String userId, LegalDocumentType type);
  Future<void> markDocumentAccepted(String userId, LegalDocumentType type);
}
