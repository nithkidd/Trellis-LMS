import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/utils/khmer_collator.dart';
import '../models/teacher_model.dart';

class TeacherRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insert(TeacherModel teacher) async {
    Database db = await _dbHelper.database;
    return await db.insert(DatabaseHelper.tableTeachers, teacher.toMap());
  }

  Future<List<TeacherModel>> getTeachersBySchoolId(int schoolId) async {
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableTeachers,
      where: 'school_id = ?',
      whereArgs: [schoolId],
    );
    List<TeacherModel> teachers = maps
        .map((map) => TeacherModel.fromMap(map))
        .toList();

    // Sort by Khmer alphabetical order
    KhmerCollator.sortBy(teachers, (t) => t.name);

    return teachers;
  }

  Future<TeacherModel?> getById(int id) async {
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableTeachers,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return TeacherModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> update(TeacherModel teacher) async {
    Database db = await _dbHelper.database;
    return await db.update(
      DatabaseHelper.tableTeachers,
      teacher.toMap(),
      where: 'id = ?',
      whereArgs: [teacher.id],
    );
  }

  Future<int> delete(int id) async {
    Database db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.tableTeachers,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
