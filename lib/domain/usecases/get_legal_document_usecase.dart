import '../entities/legal_document.dart';
import '../repositories/legal_document_repository.dart';
import '../../core/types/result.dart';
import '../../core/exceptions/domain/validation_exception.dart';
import 'base_usecase.dart';

class GetLegalDocumentParams {
  final String? id;
  final LegalDocumentType? type;

  GetLegalDocumentParams({this.id, this.type})
      : assert(
            id != null || type != null, 'Either id or type must be provided');
}

class GetLegalDocumentUseCase
    extends BaseUseCase<GetLegalDocumentParams, LegalDocument> {
  final LegalDocumentRepository _repository;

  GetLegalDocumentUseCase(this._repository);

  @override
  Future<Result<LegalDocument>> call(GetLegalDocumentParams params) async {
    try {
      LegalDocument? document;

      if (params.id != null) {
        document = await _repository.getDocument(params.id!);
      } else if (params.type != null) {
        document = await _repository.getDocumentByType(params.type!);
      }

      if (document == null) {
        return Failure(ValidationException(
          '法的文書が見つかりません。ID: ${params.id}, タイプ: ${params.type?.displayName}',
        ));
      }

      return Success(document);
    } catch (e) {
      return Failure(ValidationException(
        '法的文書の取得に失敗しました: $e',
      ));
    }
  }
}
