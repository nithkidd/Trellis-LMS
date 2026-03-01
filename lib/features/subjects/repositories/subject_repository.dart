import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../models/subject_model.dart';

class SubjectRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insert(SubjectModel subject) async {
    Database db = await _dbHelper.database;
    return await db.insert(DatabaseHelper.tableSubjects, subject.toMap());
  }

  Future<List<SubjectModel>> getByClassId(int classId) async {
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableSubjects,
      where: 'class_id = ?',
      whereArgs: [classId],
      orderBy: 'name ASC',
    );
    return maps.map((map) => SubjectModel.fromMap(map)).toList();
  }

  Future<SubjectModel?> getById(int id) async {
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableSubjects,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return SubjectModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> update(SubjectModel subject) async {
    Database db = await _dbHelper.database;
    return await db.update(
      DatabaseHelper.tableSubjects,
      subject.toMap(),
      where: 'id = ?',
      whereArgs: [subject.id],
    );
  }

  Future<int> delete(int id) async {
    Database db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.tableSubjects,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
