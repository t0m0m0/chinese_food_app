import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../models/store_model.dart';
import '../../domain/entities/store.dart';

class StoreLocalDatasource {
  final DatabaseHelper _databaseHelper;

  StoreLocalDatasource(this._databaseHelper);

  Future<List<StoreModel>> getAllStores() async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'stores',
        orderBy: 'created_at DESC',
      );

      return List.generate(maps.length, (i) {
        return StoreModel.fromMap(maps[i]);
      });
    } on DatabaseException catch (e) {
      throw DatabaseException('Failed to fetch stores: ${e.toString()}');
    } catch (e) {
      throw Exception('Unexpected error: ${e.toString()}');
    }
  }

  Future<List<StoreModel>> getStoresPaginated({
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      final offset = page * pageSize;
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'stores',
        orderBy: 'created_at DESC',
        limit: pageSize,
        offset: offset,
      );

      return maps.map((map) => StoreModel.fromMap(map)).toList();
    } on DatabaseException catch (e) {
      throw DatabaseException('Failed to fetch paginated stores: ${e.toString()}');
    } catch (e) {
      throw Exception('Unexpected error: ${e.toString()}');
    }
  }

  Future<List<StoreModel>> getStoresByStatus(StoreStatus status) async {
    try {
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
    } on DatabaseException catch (e) {
      throw DatabaseException('Failed to fetch stores by status: ${e.toString()}');
    } catch (e) {
      throw Exception('Unexpected error: ${e.toString()}');
    }
  }

  Future<StoreModel?> getStoreById(String id) async {
    try {
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
    } on DatabaseException catch (e) {
      throw DatabaseException('Failed to fetch store by id: ${e.toString()}');
    } catch (e) {
      throw Exception('Unexpected error: ${e.toString()}');
    }
  }

  Future<void> insertStore(StoreModel store) async {
    try {
      final db = await _databaseHelper.database;
      await db.insert(
        'stores',
        store.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } on DatabaseException catch (e) {
      throw DatabaseException('Failed to insert store: ${e.toString()}');
    } catch (e) {
      throw Exception('Unexpected error: ${e.toString()}');
    }
  }

  Future<void> updateStore(StoreModel store) async {
    try {
      final db = await _databaseHelper.database;
      await db.update(
        'stores',
        store.toMap(),
        where: 'id = ?',
        whereArgs: [store.id],
      );
    } on DatabaseException catch (e) {
      throw DatabaseException('Failed to update store: ${e.toString()}');
    } catch (e) {
      throw Exception('Unexpected error: ${e.toString()}');
    }
  }

  Future<void> deleteStore(String id) async {
    try {
      final db = await _databaseHelper.database;
      await db.delete(
        'stores',
        where: 'id = ?',
        whereArgs: [id],
      );
    } on DatabaseException catch (e) {
      throw DatabaseException('Failed to delete store: ${e.toString()}');
    } catch (e) {
      throw Exception('Unexpected error: ${e.toString()}');
    }
  }

  Future<List<StoreModel>> searchStores(String query) async {
    try {
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
    } on DatabaseException catch (e) {
      throw DatabaseException('Failed to search stores: ${e.toString()}');
    } catch (e) {
      throw Exception('Unexpected error: ${e.toString()}');
    }
  }
}