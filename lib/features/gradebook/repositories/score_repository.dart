import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../models/score_model.dart';

class ScoreRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> upsert(ScoreModel score) async {
    Database db = await _dbHelper.database;
    // Uses the UNIQUE constraint on (student_id, assignment_id) to overwrite existing scores
    return await db.insert(
      DatabaseHelper.tableScores,
      score.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ScoreModel>> getScoresByStudentId(int studentId) async {
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableScores,
      where: 'student_id = ?',
      whereArgs: [studentId],
    );
    return maps.map((map) => ScoreModel.fromMap(map)).toList();
  }

  Future<List<ScoreModel>> getScoresByAssignmentId(int assignmentId) async {
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableScores,
      where: 'assignment_id = ?',
      whereArgs: [assignmentId],
    );
    return maps.map((map) => ScoreModel.fromMap(map)).toList();
  }

  Future<ScoreModel?> getById(int id) async {
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableScores,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return ScoreModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> update(ScoreModel score) async {
    Database db = await _dbHelper.database;
    return await db.update(
      DatabaseHelper.tableScores,
      score.toMap(),
      where: 'id = ?',
      whereArgs: [score.id],
    );
  }

  Future<int> delete(int id) async {
    Database db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.tableScores,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<ScoreModel>> getScoresByClassId(int classId) async {
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT s.*
      FROM ${DatabaseHelper.tableScores} s
      JOIN ${DatabaseHelper.tableAssignments} a ON s.assignment_id = a.id
      WHERE a.class_id = ?
    ''', [classId]);
    return maps.map((map) => ScoreModel.fromMap(map)).toList();
  }


  /// Calculates the average grade percentage for a student across all their scores.
  /// Needs to JOIN with assignments table to get max_points.
  Future<double> getAverageScoreByStudentId(int studentId) async {
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT SUM(s.points_earned) as total_earned, SUM(a.max_points) as total_max
      FROM ${DatabaseHelper.tableScores} s
      JOIN ${DatabaseHelper.tableAssignments} a ON s.assignment_id = a.id
      WHERE s.student_id = ?
    ''', [studentId]);

    if (result.isNotEmpty) {
      final earned = result.first['total_earned'];
      final max = result.first['total_max'];

      if (earned != null && max != null && max > 0) {
        return ((earned as num) / (max as num)) * 100;
      }
    }
    return 0.0;
  }
}
