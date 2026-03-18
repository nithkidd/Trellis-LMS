import '../../../core/database/operational_firestore_service.dart';
import '../models/assignment_model.dart';

class AssignmentRepository {
  AssignmentRepository({OperationalFirestoreService? store})
    : _store = store ?? OperationalFirestoreService();

  final OperationalFirestoreService _store;

  Future<String> insert(AssignmentModel assignment) async {
    return _store.createDocument(
      collectionName: OperationalFirestoreService.assignmentsCollection,
      data: assignment.toDto(),
    );
  }

  Future<List<AssignmentModel>> getByClassId(String classId) async {
    final rows = await _store.queryByField(
      collectionName: OperationalFirestoreService.assignmentsCollection,
      field: 'class_id',
      isEqualTo: classId,
    );

    final assignments = rows
        .map((row) => AssignmentModel.fromDto(row, row['id'].toString()))
        .toList();

    assignments.sort((a, b) {
      final yearCompare = b.year.compareTo(a.year);
      if (yearCompare != 0) return yearCompare;
      return b.month.compareTo(a.month);
    });

    return assignments;
  }

  Future<AssignmentModel?> getById(String id) async {
    final row = await _store.getDocument(
      collectionName: OperationalFirestoreService.assignmentsCollection,
      documentId: id,
    );
    if (row == null) return null;
    return AssignmentModel.fromDto(row, row['id'].toString());
  }

  Future<void> update(AssignmentModel assignment) async {
    if (assignment.id == null) return;

    await _store.setDocument(
      collectionName: OperationalFirestoreService.assignmentsCollection,
      documentId: assignment.id!,
      data: assignment.toDto(),
    );
  }

  Future<void> delete(String id) async {
    final scores = await _store.queryByField(
      collectionName: OperationalFirestoreService.scoresCollection,
      field: 'assignment_id',
      isEqualTo: id,
    );
    await _store.deleteDocumentsByIds(
      collectionName: OperationalFirestoreService.scoresCollection,
      documentIds: scores.map((row) => row['id']?.toString() ?? ''),
    );
    await _store.deleteDocument(
      collectionName: OperationalFirestoreService.assignmentsCollection,
      documentId: id,
    );
  }
}
