import '../../../core/database/operational_firestore_service.dart';
import '../../../core/utils/khmer_collator.dart';
import '../models/student_model.dart';

class StudentRepository {
  StudentRepository({OperationalFirestoreService? store})
    : _store = store ?? OperationalFirestoreService();

  final OperationalFirestoreService _store;

  Future<String> insert(StudentModel student) async {
    return _store.createDocument(
      collectionName: OperationalFirestoreService.studentsCollection,
      data: student.toDto(),
    );
  }

  Future<List<StudentModel>> getStudentsByClassId(String classId) async {
    final rows = await _store.queryByField(
      collectionName: OperationalFirestoreService.studentsCollection,
      field: 'class_id',
      isEqualTo: classId,
    );

    final students = rows
        .map((row) => StudentModel.fromDto(row, row['id'].toString()))
        .toList();

    KhmerCollator.sortBy(students, (student) => student.name);
    return students;
  }

  Future<StudentModel?> getById(String id) async {
    final row = await _store.getDocument(
      collectionName: OperationalFirestoreService.studentsCollection,
      documentId: id,
    );
    if (row == null) return null;
    return StudentModel.fromDto(row, row['id'].toString());
  }

  Future<void> update(StudentModel student) async {
    if (student.id == null) return;

    await _store.setDocument(
      collectionName: OperationalFirestoreService.studentsCollection,
      documentId: student.id!,
      data: student.toDto(),
    );
  }

  Future<void> delete(String id) async {
    final scores = await _store.queryByField(
      collectionName: OperationalFirestoreService.scoresCollection,
      field: 'student_id',
      isEqualTo: id,
    );
    await _store.deleteDocumentsByIds(
      collectionName: OperationalFirestoreService.scoresCollection,
      documentIds: scores.map((row) => row['id']?.toString() ?? ''),
    );
    await _store.deleteDocument(
      collectionName: OperationalFirestoreService.studentsCollection,
      documentId: id,
    );
  }
}
