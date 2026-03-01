import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../models/school_model.dart';

class SchoolRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insert(SchoolModel school) async {
    Database db = await _dbHelper.database;
    return await db.insert(DatabaseHelper.tableSchools, school.toMap());
  }

  Future<List<SchoolModel>> getAll() async {
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableSchools,
      orderBy: 'display_order DESC, created_at DESC',
    );
    return maps.map((map) => SchoolModel.fromMap(map)).toList();
  }

  Future<void> updateDisplayOrder(int id, int displayOrder) async {
    Database db = await _dbHelper.database;
    await db.update(
      DatabaseHelper.tableSchools,
      {'display_order': displayOrder},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<SchoolModel?> getById(int id) async {
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableSchools,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return SchoolModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> update(SchoolModel school) async {
    Database db = await _dbHelper.database;
    return await db.update(
      DatabaseHelper.tableSchools,
      school.toMap(),
      where: 'id = ?',
      whereArgs: [school.id],
    );
  }

  Future<int> delete(int id) async {
    Database db = await _dbHelper.database;
    // Cascading delete handles associated classes, students, and scores automatically
    return await db.delete(
      DatabaseHelper.tableSchools,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
