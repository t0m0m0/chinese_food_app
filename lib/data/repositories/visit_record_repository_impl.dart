import '../../domain/entities/visit_record.dart';
import '../../domain/repositories/visit_record_repository.dart';
import '../datasources/visit_record_local_datasource.dart';
import '../models/visit_record_model.dart';

class VisitRecordRepositoryImpl implements VisitRecordRepository {
  final VisitRecordLocalDatasource _localDatasource;

  VisitRecordRepositoryImpl(this._localDatasource);

  @override
  Future<List<VisitRecord>> getAllVisitRecords() async {
    final visitRecordModels = await _localDatasource.getAllVisitRecords();
    return visitRecordModels.cast<VisitRecord>();
  }

  @override
  Future<List<VisitRecord>> getVisitRecordsByStoreId(String storeId) async {
    final visitRecordModels =
        await _localDatasource.getVisitRecordsByStoreId(storeId);
    return visitRecordModels.cast<VisitRecord>();
  }

  @override
  Future<VisitRecord?> getVisitRecordById(String id) async {
    final visitRecordModel = await _localDatasource.getVisitRecordById(id);
    return visitRecordModel;
  }

  @override
  Future<void> insertVisitRecord(VisitRecord visitRecord) async {
    final visitRecordModel = VisitRecordModel.fromEntity(visitRecord);
    await _localDatasource.insertVisitRecord(visitRecordModel);
  }

  @override
  Future<void> updateVisitRecord(VisitRecord visitRecord) async {
    final visitRecordModel = VisitRecordModel.fromEntity(visitRecord);
    await _localDatasource.updateVisitRecord(visitRecordModel);
  }

  @override
  Future<void> deleteVisitRecord(String id) async {
    await _localDatasource.deleteVisitRecord(id);
  }
}
