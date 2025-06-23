import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../models/store_model.dart';
import '../../domain/entities/store.dart';

class StoreLocalDatasource {
  final DatabaseHelper _databaseHelper;

  StoreLocalDatasource(this._databaseHelper);

  Future<List<StoreModel>> getAllStores() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stores',
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return StoreModel.fromMap(maps[i]);
    });
  }

  Future<List<StoreModel>> getStoresByStatus(StoreStatus status) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stores',
      where: 'status = ?',
      whereArgs: [status.value],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return StoreModel.fromMap(maps[i]);
    });
  }

  Future<StoreModel?> getStoreById(String id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stores',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return StoreModel.fromMap(maps.first);
    }
    return null;
  }

  Future<void> insertStore(StoreModel store) async {
    final db = await _databaseHelper.database;
    await db.insert(
      'stores',
      store.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateStore(StoreModel store) async {
    final db = await _databaseHelper.database;
    await db.update(
      'stores',
      store.toMap(),
      where: 'id = ?',
      whereArgs: [store.id],
    );
  }

  Future<void> deleteStore(String id) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'stores',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<StoreModel>> searchStores(String query) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stores',
      where: 'name LIKE ? OR address LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return StoreModel.fromMap(maps[i]);
    });
  }
}