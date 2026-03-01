import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../utils/khmer_collator.dart';
import 'excel_preview_models.dart';

class GradebookImportSummary {
  final int createdSubjects;
  final int createdAssignments;
  final int createdStudents;
  final int upsertedScores;

  const GradebookImportSummary({
    required this.createdSubjects,
    required this.createdAssignments,
    required this.createdStudents,
    required this.upsertedScores,
  });
}

class ExcelTransferService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<Map<String, dynamic>> exportSubjects({
    required int classId,
    required String className,
  }) async {
    final db = await _dbHelper.database;
    final subjectsData = await db.query(
      DatabaseHelper.tableSubjects,
      where: 'class_id = ?',
      whereArgs: [classId],
    );

    if (subjectsData.isEmpty) {
      throw Exception(
        'មិនមានមុខវិជ្ជាសម្រាប់ Export។ សូមបន្ថែមមុខវិជ្ជាមុនសិន។',
      );
    }

    // Sort by Khmer alphabetical order
    final subjects = List<Map<String, dynamic>>.from(subjectsData);
    subjects.sort(
      (a, b) => KhmerCollator.compare(
        (a['name'] ?? '').toString(),
        (b['name'] ?? '').toString(),
      ),
    );

    final excel = Excel.createExcel();
    final sheet = excel['Subjects'];

    sheet.appendRow([TextCellValue('ឈ្មោះមុខវិជ្ជា')]);
    for (final subject in subjects) {
      final name = (subject['name'] ?? '').toString();
      sheet.appendRow([TextCellValue(name)]);
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('Unable to generate Excel file.');
    }

    final fileName = _safeFileName('${className}_subjects_export');
    final path = await FileSaver.instance.saveFile(
      name: fileName,
      bytes: Uint8List.fromList(bytes),
      fileExtension: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );

    return {'path': path, 'count': subjects.length};
  }

  Future<int> importSubjects({required int classId}) async {
    final bytes = await _pickExcelBytes();
    final excel = Excel.decodeBytes(bytes);

    final sheet = excel.tables['Subjects'] ?? excel.tables.values.firstOrNull;
    if (sheet == null) {
      throw Exception('No worksheet found in the selected file.');
    }

    final db = await _dbHelper.database;
    int imported = 0;

    await db.transaction((txn) async {
      final existingRows = await txn.query(
        DatabaseHelper.tableSubjects,
        where: 'class_id = ?',
        whereArgs: [classId],
      );

      final existingNames = <String>{
        for (final row in existingRows)
          _normalize((row['name'] ?? '').toString()),
      };

      for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
        final row = sheet.rows[rowIndex];
        final subjectName = _cellText(row, 0);
        if (subjectName.isEmpty) continue;

        final key = _normalize(subjectName);
        if (existingNames.contains(key)) continue;

        await txn.insert(DatabaseHelper.tableSubjects, {
          'class_id': classId,
          'name': subjectName,
        });
        existingNames.add(key);
        imported++;
      }
    });

    return imported;
  }

  Future<SubjectImportPreview> previewSubjectsImport({
    required int classId,
  }) async {
    final bytes = await _pickExcelBytes();
    final excel = Excel.decodeBytes(bytes);

    final sheet = excel.tables['Subjects'] ?? excel.tables.values.firstOrNull;
    if (sheet == null) {
      throw Exception('No worksheet found in the selected file.');
    }

    final db = await _dbHelper.database;
    final existingRows = await db.query(
      DatabaseHelper.tableSubjects,
      where: 'class_id = ?',
      whereArgs: [classId],
    );

    final existingNames = <String>{
      for (final row in existingRows)
        _normalize((row['name'] ?? '').toString()),
    };

    final rows = <SubjectImportRow>[];
    for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
      final row = sheet.rows[rowIndex];
      final subjectName = _cellText(row, 0);
      if (subjectName.isEmpty) continue;

      rows.add(
        SubjectImportRow(
          name: subjectName,
          shouldImport: !existingNames.contains(_normalize(subjectName)),
        ),
      );
    }

    return SubjectImportPreview(
      rows: rows,
      existingNames: existingNames.toList(),
    );
  }

  Future<int> importSubjectsFromPreview({
    required int classId,
    required List<SubjectImportRow> rows,
  }) async {
    final db = await _dbHelper.database;
    int imported = 0;

    await db.transaction((txn) async {
      final existingRows = await txn.query(
        DatabaseHelper.tableSubjects,
        where: 'class_id = ?',
        whereArgs: [classId],
      );

      final existingNames = <String>{
        for (final row in existingRows)
          _normalize((row['name'] ?? '').toString()),
      };

      for (final row in rows) {
        if (!row.shouldImport || row.name.isEmpty) continue;

        final key = _normalize(row.name);
        if (existingNames.contains(key)) continue;

        await txn.insert(DatabaseHelper.tableSubjects, {
          'class_id': classId,
          'name': row.name,
        });
        existingNames.add(key);
        imported++;
      }
    });

    return imported;
  }

  Future<Map<String, dynamic>> exportGradebook({
    required int classId,
    required String className,
  }) async {
    final db = await _dbHelper.database;

    final subjectsData = await db.query(
      DatabaseHelper.tableSubjects,
      where: 'class_id = ?',
      whereArgs: [classId],
    );

    // Sort subjects by Khmer alphabetical order
    final subjects = List<Map<String, dynamic>>.from(subjectsData);
    subjects.sort(
      (a, b) => KhmerCollator.compare(
        (a['name'] ?? '').toString(),
        (b['name'] ?? '').toString(),
      ),
    );

    final assignmentsData = await db.rawQuery(
      '''
      SELECT a.id, a.name, a.month, a.year, a.max_points, sub.name AS subject_name
      FROM ${DatabaseHelper.tableAssignments} a
      JOIN ${DatabaseHelper.tableSubjects} sub ON sub.id = a.subject_id
      WHERE a.class_id = ?
      ORDER BY a.year DESC, a.month DESC
    ''',
      [classId],
    );

    // Sort assignments by Khmer name after date sorting
    final assignments = List<Map<String, dynamic>>.from(assignmentsData);
    assignments.sort((a, b) {
      // First by year DESC
      final yearCmp = ((b['year'] ?? '').toString()).compareTo(
        (a['year'] ?? '').toString(),
      );
      if (yearCmp != 0) return yearCmp;

      // Then by month DESC
      final monthCmp = ((b['month'] ?? '').toString()).compareTo(
        (a['month'] ?? '').toString(),
      );
      if (monthCmp != 0) return monthCmp;

      // Finally by Khmer name
      return KhmerCollator.compare(
        (a['name'] ?? '').toString(),
        (b['name'] ?? '').toString(),
      );
    });

    final scoresData = await db.rawQuery(
      '''
      SELECT st.name AS student_name,
             st.remarks AS student_remarks,
             sub.name AS subject_name,
             a.name AS assignment_name,
             a.month,
             a.year,
             a.max_points,
             sc.points_earned
      FROM ${DatabaseHelper.tableScores} sc
      JOIN ${DatabaseHelper.tableAssignments} a ON a.id = sc.assignment_id
      JOIN ${DatabaseHelper.tableSubjects} sub ON sub.id = a.subject_id
      JOIN ${DatabaseHelper.tableStudents} st ON st.id = sc.student_id
      WHERE a.class_id = ?
    ''',
      [classId],
    );

    // Sort scores by Khmer student name, then subject name, then date
    final scores = List<Map<String, dynamic>>.from(scoresData);
    scores.sort((a, b) {
      // First by student name (Khmer)
      final studentCmp = KhmerCollator.compare(
        (a['student_name'] ?? '').toString(),
        (b['student_name'] ?? '').toString(),
      );
      if (studentCmp != 0) return studentCmp;

      // Then by subject name (Khmer)
      final subjectCmp = KhmerCollator.compare(
        (a['subject_name'] ?? '').toString(),
        (b['subject_name'] ?? '').toString(),
      );
      if (subjectCmp != 0) return subjectCmp;

      // Then by year DESC
      final yearCmp = ((b['year'] ?? '').toString()).compareTo(
        (a['year'] ?? '').toString(),
      );
      if (yearCmp != 0) return yearCmp;

      // Finally by month DESC
      return ((b['month'] ?? '').toString()).compareTo(
        (a['month'] ?? '').toString(),
      );
    });

    if (subjects.isEmpty) {
      throw Exception(
        'មិនមានទិន្នន័យសម្រាប់ Export។ សូមបន្ថែមមុខវិជ្ជា និងកិច្ចការមុនសិន។',
      );
    }

    final excel = Excel.createExcel();

    final subjectsSheet = excel['Subjects'];
    subjectsSheet.appendRow([TextCellValue('ឈ្មោះមុខវិជ្ជា')]);
    for (final subject in subjects) {
      subjectsSheet.appendRow([
        TextCellValue((subject['name'] ?? '').toString()),
      ]);
    }

    final assignmentsSheet = excel['Assignments'];
    assignmentsSheet.appendRow([
      TextCellValue('ឈ្មោះមុខវិជ្ជា'),
      TextCellValue('ឈ្មោះកិច្ចការ'),
      TextCellValue('ខែ'),
      TextCellValue('ឆ្នាំ'),
      TextCellValue('ពិន្ទុសរុប'),
    ]);
    for (final assignment in assignments) {
      assignmentsSheet.appendRow([
        TextCellValue((assignment['subject_name'] ?? '').toString()),
        TextCellValue((assignment['name'] ?? '').toString()),
        TextCellValue((assignment['month'] ?? '').toString()),
        TextCellValue((assignment['year'] ?? '').toString()),
        DoubleCellValue(_asDouble(assignment['max_points']) ?? 0),
      ]);
    }

    final scoresSheet = excel['Scores'];
    scoresSheet.appendRow([
      TextCellValue('នាម និង គោត្តនាម'),
      TextCellValue('កំណត់សម្គាល់'),
      TextCellValue('មុខវិជ្ជា'),
      TextCellValue('កិច្ចការ'),
      TextCellValue('ខែ'),
      TextCellValue('ឆ្នាំ'),
      TextCellValue('ពិន្ទុសរុប'),
      TextCellValue('ពិន្ទុទទួលបាន'),
    ]);

    for (final score in scores) {
      scoresSheet.appendRow([
        TextCellValue((score['student_name'] ?? '').toString()),
        TextCellValue((score['student_remarks'] ?? '').toString()),
        TextCellValue((score['subject_name'] ?? '').toString()),
        TextCellValue((score['assignment_name'] ?? '').toString()),
        TextCellValue((score['month'] ?? '').toString()),
        TextCellValue((score['year'] ?? '').toString()),
        DoubleCellValue(_asDouble(score['max_points']) ?? 0),
        DoubleCellValue(_asDouble(score['points_earned']) ?? 0),
      ]);
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('Unable to generate Excel file.');
    }

    final fileName = _safeFileName('${className}_gradebook_export');
    final path = await FileSaver.instance.saveFile(
      name: fileName,
      bytes: Uint8List.fromList(bytes),
      fileExtension: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );

    return {
      'path': path,
      'subjects': subjects.length,
      'assignments': assignments.length,
      'scores': scores.length,
    };
  }

  Future<GradebookImportSummary> importGradebook({required int classId}) async {
    final bytes = await _pickExcelBytes();
    final excel = Excel.decodeBytes(bytes);

    final subjectsSheet = excel.tables['Subjects'];
    final assignmentsSheet = excel.tables['Assignments'];
    final scoresSheet = excel.tables['Scores'];

    if (subjectsSheet == null &&
        assignmentsSheet == null &&
        scoresSheet == null) {
      throw Exception(
        'No valid worksheet found. Expected Subjects, Assignments, or Scores.',
      );
    }

    final db = await _dbHelper.database;
    int createdSubjects = 0;
    int createdAssignments = 0;
    int createdStudents = 0;
    int upsertedScores = 0;

    await db.transaction((txn) async {
      final subjectNameToId = <String, int>{};
      final studentNameToId = <String, int>{};
      final assignmentKeyToId = <String, int>{};

      final subjectRows = await txn.query(
        DatabaseHelper.tableSubjects,
        where: 'class_id = ?',
        whereArgs: [classId],
      );
      for (final row in subjectRows) {
        final name = _normalize((row['name'] ?? '').toString());
        final id = row['id'] as int?;
        if (name.isNotEmpty && id != null) {
          subjectNameToId[name] = id;
        }
      }

      final studentRows = await txn.query(
        DatabaseHelper.tableStudents,
        where: 'class_id = ?',
        whereArgs: [classId],
      );
      for (final row in studentRows) {
        final name = _normalize((row['name'] ?? '').toString());
        final id = row['id'] as int?;
        if (name.isNotEmpty && id != null) {
          studentNameToId[name] = id;
        }
      }

      final assignmentRows = await txn.query(
        DatabaseHelper.tableAssignments,
        where: 'class_id = ?',
        whereArgs: [classId],
      );
      for (final row in assignmentRows) {
        final assignmentId = row['id'] as int?;
        final subjectId = row['subject_id'] as int?;
        final name = (row['name'] ?? '').toString();
        final month = (row['month'] ?? '').toString();
        final year = (row['year'] ?? '').toString();
        if (assignmentId != null && subjectId != null) {
          assignmentKeyToId[_assignmentKey(subjectId, name, month, year)] =
              assignmentId;
        }
      }

      if (subjectsSheet != null) {
        for (int rowIndex = 1; rowIndex < subjectsSheet.maxRows; rowIndex++) {
          final row = subjectsSheet.rows[rowIndex];
          final subjectName = _cellText(row, 0);
          if (subjectName.isEmpty) continue;

          final key = _normalize(subjectName);
          if (subjectNameToId.containsKey(key)) continue;

          final subjectId = await txn.insert(DatabaseHelper.tableSubjects, {
            'class_id': classId,
            'name': subjectName,
          });
          subjectNameToId[key] = subjectId;
          createdSubjects++;
        }
      }

      if (assignmentsSheet != null) {
        for (
          int rowIndex = 1;
          rowIndex < assignmentsSheet.maxRows;
          rowIndex++
        ) {
          final row = assignmentsSheet.rows[rowIndex];

          final subjectName = _cellText(row, 0);
          final assignmentName = _cellText(row, 1);
          final month = _cellText(row, 2);
          final year = _cellText(row, 3);
          final maxPoints = _cellDouble(row, 4) ?? 0;

          if (subjectName.isEmpty ||
              assignmentName.isEmpty ||
              month.isEmpty ||
              year.isEmpty) {
            continue;
          }

          final subjectId = await _ensureSubject(
            txn: txn,
            classId: classId,
            subjectName: subjectName,
            subjectNameToId: subjectNameToId,
            onCreated: () => createdSubjects++,
          );

          final key = _assignmentKey(subjectId, assignmentName, month, year);
          if (assignmentKeyToId.containsKey(key)) continue;

          final assignmentId = await txn
              .insert(DatabaseHelper.tableAssignments, {
                'class_id': classId,
                'subject_id': subjectId,
                'name': assignmentName,
                'month': month,
                'year': year,
                'max_points': maxPoints,
              });

          assignmentKeyToId[key] = assignmentId;
          createdAssignments++;
        }
      }

      if (scoresSheet != null) {
        for (int rowIndex = 1; rowIndex < scoresSheet.maxRows; rowIndex++) {
          final row = scoresSheet.rows[rowIndex];

          final studentName = _cellText(row, 0);
          final studentRemarks = _cellText(row, 1);
          final subjectName = _cellText(row, 2);
          final assignmentName = _cellText(row, 3);
          final month = _cellText(row, 4);
          final year = _cellText(row, 5);
          final maxPoints = _cellDouble(row, 6) ?? 0;
          final pointsEarned = _cellDouble(row, 7);

          if (studentName.isEmpty ||
              subjectName.isEmpty ||
              assignmentName.isEmpty ||
              month.isEmpty ||
              year.isEmpty ||
              pointsEarned == null) {
            continue;
          }

          final subjectId = await _ensureSubject(
            txn: txn,
            classId: classId,
            subjectName: subjectName,
            subjectNameToId: subjectNameToId,
            onCreated: () => createdSubjects++,
          );

          final assignmentId = await _ensureAssignment(
            txn: txn,
            classId: classId,
            subjectId: subjectId,
            assignmentName: assignmentName,
            month: month,
            year: year,
            maxPoints: maxPoints,
            assignmentKeyToId: assignmentKeyToId,
            onCreated: () => createdAssignments++,
          );

          final studentId = await _ensureStudent(
            txn: txn,
            classId: classId,
            studentName: studentName,
            remarks: studentRemarks,
            studentNameToId: studentNameToId,
            onCreated: () => createdStudents++,
          );

          await txn.insert(
            DatabaseHelper.tableScores,
            {
              'student_id': studentId,
              'assignment_id': assignmentId,
              'points_earned': pointsEarned,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          upsertedScores++;
        }
      }
    });

    return GradebookImportSummary(
      createdSubjects: createdSubjects,
      createdAssignments: createdAssignments,
      createdStudents: createdStudents,
      upsertedScores: upsertedScores,
    );
  }

  Future<GradebookImportPreview> previewGradebookImport({
    required int classId,
  }) async {
    final bytes = await _pickExcelBytes();
    final excel = Excel.decodeBytes(bytes);

    final subjectsSheet = excel.tables['Subjects'];
    final scoresSheet = excel.tables['Scores'];

    if (subjectsSheet == null && scoresSheet == null) {
      throw Exception('No valid worksheet found. Expected Subjects or Scores.');
    }

    final db = await _dbHelper.database;

    final existingSubjectRows = await db.query(
      DatabaseHelper.tableSubjects,
      where: 'class_id = ?',
      whereArgs: [classId],
    );

    final existingSubjectNames = existingSubjectRows
        .map((row) => _normalize((row['name'] ?? '').toString()))
        .toList();

    final subjectRows = <SubjectImportRow>[];
    if (subjectsSheet != null) {
      for (int rowIndex = 1; rowIndex < subjectsSheet.maxRows; rowIndex++) {
        final row = subjectsSheet.rows[rowIndex];
        final subjectName = _cellText(row, 0);
        if (subjectName.isEmpty) continue;

        subjectRows.add(
          SubjectImportRow(
            name: subjectName,
            shouldImport: !existingSubjectNames.contains(
              _normalize(subjectName),
            ),
          ),
        );
      }
    }

    final scoreRows = <GradebookImportRow>[];
    if (scoresSheet != null) {
      for (int rowIndex = 1; rowIndex < scoresSheet.maxRows; rowIndex++) {
        final row = scoresSheet.rows[rowIndex];

        final studentName = _cellText(row, 0);
        final studentRemarks = _cellText(row, 1);
        final subjectName = _cellText(row, 2);
        final assignmentName = _cellText(row, 3);
        final month = _cellText(row, 4);
        final year = _cellText(row, 5);
        final maxPoints = _cellDouble(row, 6) ?? 0;
        final pointsEarned = _cellDouble(row, 7);

        if (studentName.isEmpty ||
            subjectName.isEmpty ||
            assignmentName.isEmpty ||
            month.isEmpty ||
            year.isEmpty ||
            pointsEarned == null) {
          continue;
        }

        scoreRows.add(
          GradebookImportRow(
            studentName: studentName,
            studentRemarks: studentRemarks,
            subjectName: subjectName,
            assignmentName: assignmentName,
            month: month,
            year: year,
            maxPoints: maxPoints,
            pointsEarned: pointsEarned,
          ),
        );
      }
    }

    return GradebookImportPreview(
      subjects: subjectRows,
      existingSubjects: existingSubjectNames,
      scores: scoreRows,
    );
  }

  Future<GradebookImportSummary> importGradebookFromPreview({
    required int classId,
    required List<SubjectImportRow> subjects,
    required List<GradebookImportRow> scores,
  }) async {
    final db = await _dbHelper.database;
    int createdSubjects = 0;
    int createdAssignments = 0;
    int createdStudents = 0;
    int upsertedScores = 0;

    await db.transaction((txn) async {
      final subjectNameToId = <String, int>{};
      final studentNameToId = <String, int>{};
      final assignmentKeyToId = <String, int>{};

      final subjectRows = await txn.query(
        DatabaseHelper.tableSubjects,
        where: 'class_id = ?',
        whereArgs: [classId],
      );
      for (final row in subjectRows) {
        final name = _normalize((row['name'] ?? '').toString());
        final id = row['id'] as int?;
        if (name.isNotEmpty && id != null) {
          subjectNameToId[name] = id;
        }
      }

      final studentRows = await txn.query(
        DatabaseHelper.tableStudents,
        where: 'class_id = ?',
        whereArgs: [classId],
      );
      for (final row in studentRows) {
        final name = _normalize((row['name'] ?? '').toString());
        final id = row['id'] as int?;
        if (name.isNotEmpty && id != null) {
          studentNameToId[name] = id;
        }
      }

      final assignmentRows = await txn.query(
        DatabaseHelper.tableAssignments,
        where: 'class_id = ?',
        whereArgs: [classId],
      );
      for (final row in assignmentRows) {
        final assignmentId = row['id'] as int?;
        final subjectId = row['subject_id'] as int?;
        final name = (row['name'] ?? '').toString();
        final month = (row['month'] ?? '').toString();
        final year = (row['year'] ?? '').toString();
        if (assignmentId != null && subjectId != null) {
          assignmentKeyToId[_assignmentKey(subjectId, name, month, year)] =
              assignmentId;
        }
      }

      for (final subject in subjects) {
        if (!subject.shouldImport || subject.name.isEmpty) continue;

        final key = _normalize(subject.name);
        if (subjectNameToId.containsKey(key)) continue;

        final subjectId = await txn.insert(DatabaseHelper.tableSubjects, {
          'class_id': classId,
          'name': subject.name,
        });
        subjectNameToId[key] = subjectId;
        createdSubjects++;
      }

      for (final score in scores) {
        if (!score.shouldImport) continue;

        final subjectId = await _ensureSubject(
          txn: txn,
          classId: classId,
          subjectName: score.subjectName,
          subjectNameToId: subjectNameToId,
          onCreated: () => createdSubjects++,
        );

        final assignmentId = await _ensureAssignment(
          txn: txn,
          classId: classId,
          subjectId: subjectId,
          assignmentName: score.assignmentName,
          month: score.month,
          year: score.year,
          maxPoints: score.maxPoints,
          assignmentKeyToId: assignmentKeyToId,
          onCreated: () => createdAssignments++,
        );

        final studentId = await _ensureStudent(
          txn: txn,
          classId: classId,
          studentName: score.studentName,
          remarks: score.studentRemarks,
          studentNameToId: studentNameToId,
          onCreated: () => createdStudents++,
        );

        await txn.insert(DatabaseHelper.tableScores, {
          'student_id': studentId,
          'assignment_id': assignmentId,
          'points_earned': score.pointsEarned,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        upsertedScores++;
      }
    });

    return GradebookImportSummary(
      createdSubjects: createdSubjects,
      createdAssignments: createdAssignments,
      createdStudents: createdStudents,
      upsertedScores: upsertedScores,
    );
  }

  Future<Uint8List> _pickExcelBytes() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      throw Exception('No file selected.');
    }

    final bytes = result.files.single.bytes;
    if (bytes == null) {
      throw Exception('Unable to read selected file data.');
    }

    return bytes;
  }

  Future<int> _ensureSubject({
    required DatabaseExecutor txn,
    required int classId,
    required String subjectName,
    required Map<String, int> subjectNameToId,
    required void Function() onCreated,
  }) async {
    final key = _normalize(subjectName);
    final existing = subjectNameToId[key];
    if (existing != null) return existing;

    final subjectId = await txn.insert(DatabaseHelper.tableSubjects, {
      'class_id': classId,
      'name': subjectName,
    });
    subjectNameToId[key] = subjectId;
    onCreated();
    return subjectId;
  }

  Future<int> _ensureAssignment({
    required DatabaseExecutor txn,
    required int classId,
    required int subjectId,
    required String assignmentName,
    required String month,
    required String year,
    required double maxPoints,
    required Map<String, int> assignmentKeyToId,
    required void Function() onCreated,
  }) async {
    final key = _assignmentKey(subjectId, assignmentName, month, year);
    final existing = assignmentKeyToId[key];
    if (existing != null) return existing;

    final assignmentId = await txn.insert(DatabaseHelper.tableAssignments, {
      'class_id': classId,
      'subject_id': subjectId,
      'name': assignmentName,
      'month': month,
      'year': year,
      'max_points': maxPoints,
    });
    assignmentKeyToId[key] = assignmentId;
    onCreated();
    return assignmentId;
  }

  Future<int> _ensureStudent({
    required DatabaseExecutor txn,
    required int classId,
    required String studentName,
    required String remarks,
    required Map<String, int> studentNameToId,
    required void Function() onCreated,
  }) async {
    final key = _normalize(studentName);
    final existing = studentNameToId[key];
    if (existing != null) return existing;

    final studentId = await txn.insert(DatabaseHelper.tableStudents, {
      'class_id': classId,
      'name': studentName,
      'remarks': remarks.isEmpty ? null : remarks,
    });
    studentNameToId[key] = studentId;
    onCreated();
    return studentId;
  }

  String _assignmentKey(int subjectId, String name, String month, String year) {
    return '$subjectId|${_normalize(name)}|${_normalize(month)}|${_normalize(year)}';
  }

  String _cellText(List<Data?> row, int columnIndex) {
    if (columnIndex >= row.length) return '';
    final value = row[columnIndex]?.value;
    return value?.toString().trim() ?? '';
  }

  double? _cellDouble(List<Data?> row, int columnIndex) {
    final raw = _cellText(row, columnIndex);
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  double? _asDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  String _normalize(String text) => text.trim().toLowerCase();

  String _safeFileName(String name) {
    final safe = name.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    return safe.replaceAll(RegExp(r'_+'), '_');
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
