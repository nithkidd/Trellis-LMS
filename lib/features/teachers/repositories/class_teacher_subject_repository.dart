import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../../teachers/models/teacher_model.dart';
import '../../subjects/models/subject_model.dart';
import '../models/class_teacher_subject_model.dart';

class ClassTeacherSubjectRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insert(ClassTeacherSubjectModel model) async {
    Database db = await _dbHelper.database;
    return await db.insert(
      DatabaseHelper.tableClassTeacherSubject,
      model.toMap(),
    );
  }

  Future<int> delete(int id) async {
    Database db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.tableClassTeacherSubject,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteByClassAndTeacherAndSubject({
    required int classId,
    required int teacherId,
    required int subjectId,
  }) async {
    Database db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.tableClassTeacherSubject,
      where: 'class_id = ? AND teacher_id = ? AND subject_id = ?',
      whereArgs: [classId, teacherId, subjectId],
    );
  }

  /// Get all subject assignments for a teacher in a class
  Future<List<ClassTeacherSubjectModel>> getByClassAndTeacher({
    required int classId,
    required int teacherId,
  }) async {
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableClassTeacherSubject,
      where: 'class_id = ? AND teacher_id = ?',
      whereArgs: [classId, teacherId],
    );
    return maps.map((map) => ClassTeacherSubjectModel.fromMap(map)).toList();
  }

  /// Get all subject IDs assigned to a teacher in a class
  Future<List<int>> getAssignedSubjectIds({
    required int classId,
    required int teacherId,
  }) async {
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableClassTeacherSubject,
      columns: ['subject_id'],
      where: 'class_id = ? AND teacher_id = ?',
      whereArgs: [classId, teacherId],
    );
    return maps.map((map) => map['subject_id'] as int).toList();
  }

  /// Get all teachers assigned to a subject in a class
  Future<List<ClassTeacherSubjectRow>> getTeachersByClassAndSubject({
    required int classId,
    required int subjectId,
  }) async {
    Database db = await _dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT 
        cts.id,
        t.id as teacher_id,
        t.school_id,
        t.name as teacher_name,
        t.created_at,
        s.id as subject_id,
        s.class_id,
        s.name as subject_name
      FROM ${DatabaseHelper.tableClassTeacherSubject} cts
      JOIN ${DatabaseHelper.tableTeachers} t ON cts.teacher_id = t.id
      JOIN ${DatabaseHelper.tableSubjects} s ON cts.subject_id = s.id
      WHERE cts.class_id = ? AND cts.subject_id = ?
    ''',
      [classId, subjectId],
    );

    return result.map((map) {
      final teacher = TeacherModel.fromMap({
        'id': map['teacher_id'],
        'school_id': map['school_id'],
        'name': map['teacher_name'],
        'created_at': map['created_at'],
      });
      final subject = SubjectModel.fromMap({
        'id': map['subject_id'],
        'class_id': map['class_id'],
        'name': map['subject_name'],
      });
      return ClassTeacherSubjectRow(
        teacher: teacher,
        subject: subject,
        assignmentId: map['id'] as int,
      );
    }).toList();
  }

  /// Get all subjects with their assigned teachers for a class
  Future<List<ClassTeacherSubjectRow>> getSubjectsWithTeachers({
    required int classId,
  }) async {
    Database db = await _dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT 
        cts.id,
        t.id as teacher_id,
        t.school_id,
        t.name as teacher_name,
        t.created_at,
        s.id as subject_id,
        s.class_id,
        s.name as subject_name
      FROM ${DatabaseHelper.tableClassTeacherSubject} cts
      JOIN ${DatabaseHelper.tableTeachers} t ON cts.teacher_id = t.id
      JOIN ${DatabaseHelper.tableSubjects} s ON cts.subject_id = s.id
      WHERE cts.class_id = ?
      ORDER BY s.name, t.name
    ''',
      [classId],
    );

    return result.map((map) {
      final teacher = TeacherModel.fromMap({
        'id': map['teacher_id'],
        'school_id': map['school_id'],
        'name': map['teacher_name'],
        'created_at': map['created_at'],
      });
      final subject = SubjectModel.fromMap({
        'id': map['subject_id'],
        'class_id': map['class_id'],
        'name': map['subject_name'],
      });
      return ClassTeacherSubjectRow(
        teacher: teacher,
        subject: subject,
        assignmentId: map['id'] as int,
      );
    }).toList();
  }
}
