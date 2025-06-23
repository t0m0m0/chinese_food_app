import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../models/visit_record_model.dart';

class VisitRecordLocalDatasource {
  final DatabaseHelper _databaseHelper;

  VisitRecordLocalDatasource(this._databaseHelper);

  Future<List<VisitRecordModel>> getAllVisitRecords() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'visit_records',
      orderBy: 'visited_at DESC',
    );

    return List.generate(maps.length, (i) {
      return VisitRecordModel.fromMap(maps[i]);
    });
  }

  Future<List<VisitRecordModel>> getVisitRecordsByStoreId(String storeId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'visit_records',
      where: 'store_id = ?',
      whereArgs: [storeId],
      orderBy: 'visited_at DESC',
    );

    return List.generate(maps.length, (i) {
      return VisitRecordModel.fromMap(maps[i]);
    });
  }

  Future<VisitRecordModel?> getVisitRecordById(String id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'visit_records',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return VisitRecordModel.fromMap(maps.first);
    }
    return null;
  }

  Future<void> insertVisitRecord(VisitRecordModel visitRecord) async {
    final db = await _databaseHelper.database;
    await db.insert(
      'visit_records',
      visitRecord.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateVisitRecord(VisitRecordModel visitRecord) async {
    final db = await _databaseHelper.database;
    await db.update(
      'visit_records',
      visitRecord.toMap(),
      where: 'id = ?',
      whereArgs: [visitRecord.id],
    );
  }

  Future<void> deleteVisitRecord(String id) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'visit_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}