import '../entities/visit_record.dart';

abstract class VisitRecordRepository {
  Future<List<VisitRecord>> getAllVisitRecords();
  Future<List<VisitRecord>> getVisitRecordsByStoreId(String storeId);
  Future<VisitRecord?> getVisitRecordById(String id);
  Future<VisitRecord> insertVisitRecord(VisitRecord visitRecord);
  Future<void> updateVisitRecord(VisitRecord visitRecord);
  Future<void> deleteVisitRecord(String id);
}
