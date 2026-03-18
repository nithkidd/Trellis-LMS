import '../../../core/database/operational_firestore_service.dart';
import '../models/subject_model.dart';

class SubjectRepository {
  SubjectRepository({OperationalFirestoreService? store})
    : _store = store ?? OperationalFirestoreService();

  final OperationalFirestoreService _store;

  Future<String> insert(SubjectModel subject) async {
    var nextOrder = subject.displayOrder;

    if (nextOrder == null) {
      final existing = await getByClassId(subject.classId);
      final currentOrders = existing
          .map((item) => item.displayOrder ?? -1)
          .toList(growable: false);
      final maxOrder = currentOrders.isEmpty
          ? -1
          : currentOrders.reduce((a, b) => a > b ? a : b);
      nextOrder = maxOrder + 1;
    }

    return _store.createDocument(
      collectionName: OperationalFirestoreService.subjectsCollection,
      data: subject.copyWith(displayOrder: nextOrder).toDto(),
    );
  }

  Future<List<SubjectModel>> getByClassId(String classId) async {
    final rows = await _store.queryByField(
      collectionName: OperationalFirestoreService.subjectsCollection,
      field: 'class_id',
      isEqualTo: classId,
    );

    final subjects = rows
        .map((row) => SubjectModel.fromDto(row, row['id'].toString()))
        .toList(growable: false);
    subjects.sort((a, b) {
      final orderCompare = (a.displayOrder ?? 0).compareTo(b.displayOrder ?? 0);
      if (orderCompare != 0) {
        return orderCompare;
      }
      return (a.id ?? '').compareTo(b.id ?? '');
    });
    return subjects;
  }

  Future<SubjectModel?> getById(String id) async {
    final row = await _store.getDocument(
      collectionName: OperationalFirestoreService.subjectsCollection,
      documentId: id,
    );
    if (row == null) return null;
    return SubjectModel.fromDto(row, row['id'].toString());
  }

  Future<void> update(SubjectModel subject) async {
    if (subject.id == null) return;

    await _store.setDocument(
      collectionName: OperationalFirestoreService.subjectsCollection,
      documentId: subject.id!,
      data: subject.toDto(),
    );
  }

  Future<void> delete(String id) async {
    final assignments = await _store.queryByField(
      collectionName: OperationalFirestoreService.assignmentsCollection,
      field: 'subject_id',
      isEqualTo: id,
    );
    final assignmentIds = assignments
        .map((row) => row['id']?.toString() ?? '')
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    final scores = assignmentIds.isEmpty
        ? const <Map<String, dynamic>>[]
        : await _store.queryByFieldIn(
            collectionName: OperationalFirestoreService.scoresCollection,
            field: 'assignment_id',
            values: assignmentIds,
          );
    final teacherAssignments = await _store.queryByField(
      collectionName: OperationalFirestoreService.classTeacherSubjectsCollection,
      field: 'subject_id',
      isEqualTo: id,
    );

    await _store.deleteDocumentsByIds(
      collectionName: OperationalFirestoreService.scoresCollection,
      documentIds: scores.map((row) => row['id']?.toString() ?? ''),
    );
    await _store.deleteDocumentsByIds(
      collectionName: OperationalFirestoreService.classTeacherSubjectsCollection,
      documentIds: teacherAssignments.map((row) => row['id']?.toString() ?? ''),
    );
    await _store.deleteDocumentsByIds(
      collectionName: OperationalFirestoreService.assignmentsCollection,
      documentIds: assignmentIds,
    );
    await _store.deleteDocument(
      collectionName: OperationalFirestoreService.subjectsCollection,
      documentId: id,
    );
  }

  Future<void> reorderSubjects({
    required String classId,
    required List<SubjectModel> orderedSubjects,
  }) async {
    for (var index = 0; index < orderedSubjects.length; index++) {
      final subjectId = orderedSubjects[index].id;
      if (subjectId == null) continue;

      await _store.setDocument(
        collectionName: OperationalFirestoreService.subjectsCollection,
        documentId: subjectId,
        data: {'class_id': classId, 'display_order': index},
      );
    }
  }
}
