import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../models/subject_model.dart';

class SubjectRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insert(SubjectModel subject) async {
    Database db = await _dbHelper.database;

    int? nextOrder = subject.displayOrder;
    if (nextOrder == null) {
      final maxOrderResult = await db.rawQuery(
        '''
        SELECT COALESCE(MAX(display_order), -1) AS max_order
        FROM ${DatabaseHelper.tableSubjects}
        WHERE class_id = ?
        ''',
        [subject.classId],
      );
      final maxOrder =
          (maxOrderResult.first['max_order'] as num?)?.toInt() ?? -1;
      nextOrder = maxOrder + 1;
    }

    return await db.insert(
      DatabaseHelper.tableSubjects,
      subject.copyWith(displayOrder: nextOrder).toMap(),
    );
  }

  Future<List<SubjectModel>> getByClassId(int classId) async {
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableSubjects,
      where: 'class_id = ?',
      whereArgs: [classId],
      orderBy: 'display_order ASC, id ASC',
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

  Future<void> reorderSubjects({
    required int classId,
    required List<SubjectModel> orderedSubjects,
  }) async {
    Database db = await _dbHelper.database;
    await db.transaction((txn) async {
      for (int index = 0; index < orderedSubjects.length; index++) {
        final subjectId = orderedSubjects[index].id;
        if (subjectId == null) continue;

        await txn.update(
          DatabaseHelper.tableSubjects,
          {'display_order': index},
          where: 'id = ? AND class_id = ?',
          whereArgs: [subjectId, classId],
        );
      }
    });
  }
}
