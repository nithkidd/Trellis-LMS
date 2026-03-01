import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/utils/khmer_collator.dart';
import '../models/class_model.dart';

class ClassRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insert(ClassModel classModel) async {
    Database db = await _dbHelper.database;
    return await db.insert(DatabaseHelper.tableClasses, classModel.toMap());
  }

  Future<List<ClassModel>> getClassesBySchoolId(int schoolId) async {
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableClasses,
      where: 'school_id = ?',
      whereArgs: [schoolId],
    );
    List<ClassModel> classes = maps
        .map((map) => ClassModel.fromMap(map))
        .toList();

    // Sort by Khmer alphabetical order
    KhmerCollator.sortBy(classes, (c) => c.name);

    return classes;
  }

  Future<ClassModel?> getById(int id) async {
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableClasses,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return ClassModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> update(ClassModel classModel) async {
    Database db = await _dbHelper.database;
    return await db.update(
      DatabaseHelper.tableClasses,
      classModel.toMap(),
      where: 'id = ?',
      whereArgs: [classModel.id],
    );
  }

  Future<int> delete(int id) async {
    Database db = await _dbHelper.database;
    // Cascading delete handles associated students and scores automatically
    // due to PRAGMA foreign_keys = ON in database_helper.dart
    return await db.delete(
      DatabaseHelper.tableClasses,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
