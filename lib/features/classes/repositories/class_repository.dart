import '../../../core/database/operational_firestore_service.dart';
import '../../../core/utils/khmer_collator.dart';
import '../models/class_model.dart';

class ClassRepository {
  ClassRepository({OperationalFirestoreService? store})
    : _store = store ?? OperationalFirestoreService();

  final OperationalFirestoreService _store;

  Future<String> insert(ClassModel classModel) async {
    final data = classModel.toDto()
      ..['is_adviser'] = classModel.isAdviser;
    return _store.createDocument(
      collectionName: OperationalFirestoreService.classesCollection,
      data: data,
    );
  }

  Future<List<ClassModel>> getClassesBySchoolId(String schoolId) async {
    final rows = await _store.queryByField(
      collectionName: OperationalFirestoreService.classesCollection,
      field: 'school_id',
      isEqualTo: schoolId,
    );
    return _mapClassesWithStudentStats(rows);
  }

  Future<List<ClassModel>> getAllClasses() async {
    final rows = await _store.getAllDocuments(
      collectionName: OperationalFirestoreService.classesCollection,
    );
    return _mapClassesWithStudentStats(rows);
  }

  Future<ClassModel?> getById(String id) async {
    final row = await _store.getDocument(
      collectionName: OperationalFirestoreService.classesCollection,
      documentId: id,
    );
    if (row == null) return null;
    return ClassModel.fromDto(row, row['id'].toString());
  }

  Future<void> update(ClassModel classModel) async {
    if (classModel.id == null) return;

    final data = classModel.toDto()
      ..['is_adviser'] = classModel.isAdviser;
    await _store.setDocument(
      collectionName: OperationalFirestoreService.classesCollection,
      documentId: classModel.id!,
      data: data,
    );
  }

  Future<void> delete(String id) async {
    final subjects = await _store.queryByField(
      collectionName: OperationalFirestoreService.subjectsCollection,
      field: 'class_id',
      isEqualTo: id,
    );
    final students = await _store.queryByField(
      collectionName: OperationalFirestoreService.studentsCollection,
      field: 'class_id',
      isEqualTo: id,
    );
    final assignments = await _store.queryByField(
      collectionName: OperationalFirestoreService.assignmentsCollection,
      field: 'class_id',
      isEqualTo: id,
    );
    final teacherAssignments = await _store.queryByField(
      collectionName: OperationalFirestoreService.classTeacherSubjectsCollection,
      field: 'class_id',
      isEqualTo: id,
    );
    final assignmentIds = assignments
        .map((row) => row['id']?.toString() ?? '')
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    final scoreIds = assignmentIds.isEmpty
        ? const <String>[]
        : (await _store.queryByFieldIn(
            collectionName: OperationalFirestoreService.scoresCollection,
            field: 'assignment_id',
            values: assignmentIds,
          ))
              .map((row) => row['id']?.toString() ?? '')
              .where((value) => value.isNotEmpty)
              .toList(growable: false);

    await _store.deleteDocumentsByIds(
      collectionName: OperationalFirestoreService.scoresCollection,
      documentIds: scoreIds,
    );
    await _store.deleteDocumentsByIds(
      collectionName: OperationalFirestoreService.classTeacherSubjectsCollection,
      documentIds: teacherAssignments.map((row) => row['id']?.toString() ?? ''),
    );
    await _store.deleteDocumentsByIds(
      collectionName: OperationalFirestoreService.assignmentsCollection,
      documentIds: assignmentIds,
    );
    await _store.deleteDocumentsByIds(
      collectionName: OperationalFirestoreService.studentsCollection,
      documentIds: students.map((row) => row['id']?.toString() ?? ''),
    );
    await _store.deleteDocumentsByIds(
      collectionName: OperationalFirestoreService.subjectsCollection,
      documentIds: subjects.map((row) => row['id']?.toString() ?? ''),
    );
    await _store.deleteDocument(
      collectionName: OperationalFirestoreService.classesCollection,
      documentId: id,
    );
  }

  Future<List<ClassModel>> _mapClassesWithStudentStats(
    List<Map<String, dynamic>> rows,
  ) async {
    final classIds = rows
        .map((row) => row['id']?.toString() ?? '')
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    final students = await _store.queryByFieldIn(
      collectionName: OperationalFirestoreService.studentsCollection,
      field: 'class_id',
      values: classIds,
    );

    final totalByClassId = <String, int>{};
    final femaleByClassId = <String, int>{};
    for (final student in students) {
      final classId = student['class_id']?.toString() ?? '';
      if (classId.isEmpty) {
        continue;
      }
      totalByClassId[classId] = (totalByClassId[classId] ?? 0) + 1;
      if ((student['sex']?.toString() ?? '').trim().toUpperCase() == 'F') {
        femaleByClassId[classId] = (femaleByClassId[classId] ?? 0) + 1;
      }
    }

    final classes = rows
        .map((row) {
          final classId = row['id'].toString();
          return ClassModel.fromDto({
            ...row,
            'total_students': totalByClassId[classId] ?? 0,
            'female_students': femaleByClassId[classId] ?? 0,
          }, classId);
        })
        .toList(growable: false);

    KhmerCollator.sortBy(classes, (classModel) => classModel.name);
    return classes;
  }
}
