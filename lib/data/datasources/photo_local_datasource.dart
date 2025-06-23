import 'package:sqflite/sqflite.dart';

import '../../core/database/database_helper.dart';
import '../models/photo_model.dart';

class PhotoLocalDatasource {
  final DatabaseHelper _databaseHelper;

  PhotoLocalDatasource(this._databaseHelper);

  Future<List<PhotoModel>> getAllPhotos() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'photos',
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return PhotoModel.fromMap(maps[i]);
    });
  }

  Future<List<PhotoModel>> getPhotosByStoreId(String storeId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'photos',
      where: 'store_id = ?',
      whereArgs: [storeId],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return PhotoModel.fromMap(maps[i]);
    });
  }

  Future<List<PhotoModel>> getPhotosByVisitId(String visitId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'photos',
      where: 'visit_id = ?',
      whereArgs: [visitId],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return PhotoModel.fromMap(maps[i]);
    });
  }

  Future<PhotoModel?> getPhotoById(String id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'photos',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return PhotoModel.fromMap(maps.first);
    }
    return null;
  }

  Future<void> insertPhoto(PhotoModel photo) async {
    final db = await _databaseHelper.database;
    await db.insert(
      'photos',
      photo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updatePhoto(PhotoModel photo) async {
    final db = await _databaseHelper.database;
    await db.update(
      'photos',
      photo.toMap(),
      where: 'id = ?',
      whereArgs: [photo.id],
    );
  }

  Future<void> deletePhoto(String id) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'photos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
