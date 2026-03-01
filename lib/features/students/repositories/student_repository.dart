import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/utils/khmer_collator.dart';
import '../models/student_model.dart';

class StudentRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insert(StudentModel student) async {
    Database db = await _dbHelper.database;
    return await db.insert(DatabaseHelper.tableStudents, student.toMap());
  }

  Future<List<StudentModel>> getStudentsByClassId(int classId) async {
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableStudents,
      where: 'class_id = ?',
      whereArgs: [classId],
    );
    List<StudentModel> students = maps
        .map((map) => StudentModel.fromMap(map))
        .toList();

    // Sort by Khmer alphabetical order
    KhmerCollator.sortBy(students, (s) => s.name);

    return students;
  }

  Future<StudentModel?> getById(int id) async {
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableStudents,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return StudentModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> update(StudentModel student) async {
    Database db = await _dbHelper.database;
    return await db.update(
      DatabaseHelper.tableStudents,
      student.toMap(),
      where: 'id = ?',
      whereArgs: [student.id],
    );
  }

  Future<int> delete(int id) async {
    Database db = await _dbHelper.database;
    // Cascading delete handles associated scores automatically
    return await db.delete(
      DatabaseHelper.tableStudents,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
