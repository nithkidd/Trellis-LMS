import '../../../core/database/operational_firestore_service.dart';
import '../../../core/utils/khmer_collator.dart';
import '../models/teacher_model.dart';

class TeacherRepository {
  TeacherRepository({OperationalFirestoreService? store})
    : _store = store ?? OperationalFirestoreService();

  final OperationalFirestoreService _store;

  Future<String> insert(TeacherModel teacher) async {
    return _store.createDocument(
      collectionName: OperationalFirestoreService.teachersCollection,
      data: teacher.copyWith(
        createdAt: teacher.createdAt ?? DateTime.now().toIso8601String(),
      ).toDto(),
    );
  }

  Future<List<TeacherModel>> getTeachersBySchoolId(String schoolId) async {
    final rows = await _store.queryByField(
      collectionName: OperationalFirestoreService.teachersCollection,
      field: 'school_id',
      isEqualTo: schoolId,
    );

    final teachers = rows
        .map((row) => TeacherModel.fromDto(row, row['id'].toString()))
        .toList();

    KhmerCollator.sortBy(teachers, (teacher) => teacher.name);
    return teachers;
  }

  Future<List<TeacherModel>> getAll() async {
    final rows = await _store.getAllDocuments(
      collectionName: OperationalFirestoreService.teachersCollection,
    );
    final teachers = rows
        .map((row) => TeacherModel.fromDto(row, row['id'].toString()))
        .toList(growable: false);
    KhmerCollator.sortBy(teachers, (teacher) => teacher.name);
    return teachers;
  }

  Future<TeacherModel?> getById(String id) async {
    final row = await _store.getDocument(
      collectionName: OperationalFirestoreService.teachersCollection,
      documentId: id,
    );
    if (row == null) return null;
    return TeacherModel.fromDto(row, row['id'].toString());
  }

  Future<void> update(TeacherModel teacher) async {
    if (teacher.id == null) return;

    await _store.setDocument(
      collectionName: OperationalFirestoreService.teachersCollection,
      documentId: teacher.id!,
      data: teacher.toDto(),
    );
  }

  Future<void> delete(String id) async {
    final assignments = await _store.queryByField(
      collectionName: OperationalFirestoreService.classTeacherSubjectsCollection,
      field: 'teacher_id',
      isEqualTo: id,
    );
    await _store.deleteDocumentsByIds(
      collectionName: OperationalFirestoreService.classTeacherSubjectsCollection,
      documentIds: assignments.map((row) => row['id']?.toString() ?? ''),
    );
    await _store.deleteDocument(
      collectionName: OperationalFirestoreService.teachersCollection,
      documentId: id,
    );
  }
}
