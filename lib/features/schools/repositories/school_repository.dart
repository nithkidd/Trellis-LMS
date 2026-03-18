import '../../../core/database/operational_firestore_service.dart';
import '../models/school_model.dart';

class SchoolRepository {
  SchoolRepository({OperationalFirestoreService? store})
    : _store = store ?? OperationalFirestoreService();

  final OperationalFirestoreService _store;

  Future<String> insert(SchoolModel school) async {
    return _store.createDocument(
      collectionName: OperationalFirestoreService.schoolsCollection,
      data: school.copyWith(
        createdAt: school.createdAt ?? DateTime.now().toIso8601String(),
      ).toDto(),
    );
  }

  Future<List<SchoolModel>> getAll() async {
    final rows = await _store.getAllDocuments(
      collectionName: OperationalFirestoreService.schoolsCollection,
    );

    final schools = rows
        .map((row) => SchoolModel.fromDto(row, row['id'].toString()))
        .toList();

    schools.sort((a, b) {
      final orderCompare = b.displayOrder.compareTo(a.displayOrder);
      if (orderCompare != 0) return orderCompare;
      return (b.createdAt ?? '').compareTo(a.createdAt ?? '');
    });

    return schools;
  }

  Future<void> updateDisplayOrder(String id, int displayOrder) async {
    await _store.setDocument(
      collectionName: OperationalFirestoreService.schoolsCollection,
      documentId: id,
      data: {'display_order': displayOrder},
    );
  }

  Future<SchoolModel?> getById(String id) async {
    final row = await _store.getDocument(
      collectionName: OperationalFirestoreService.schoolsCollection,
      documentId: id,
    );
    if (row == null) {
      return null;
    }
    return SchoolModel.fromDto(row, row['id'].toString());
  }

  Future<void> update(SchoolModel school) async {
    if (school.id == null) return;

    await _store.setDocument(
      collectionName: OperationalFirestoreService.schoolsCollection,
      documentId: school.id!,
      data: school.toDto(),
    );
  }

  Future<void> delete(String id) async {
    final classes = await _store.queryByField(
      collectionName: OperationalFirestoreService.classesCollection,
      field: 'school_id',
      isEqualTo: id,
    );
    final classIds = classes
        .map((row) => row['id']?.toString() ?? '')
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

    if (classIds.isNotEmpty) {
      final classSubjects = await _store.queryByFieldIn(
        collectionName: OperationalFirestoreService.subjectsCollection,
        field: 'class_id',
        values: classIds,
      );
      final classAssignments = await _store.queryByFieldIn(
        collectionName: OperationalFirestoreService.assignmentsCollection,
        field: 'class_id',
        values: classIds,
      );
      final classStudents = await _store.queryByFieldIn(
        collectionName: OperationalFirestoreService.studentsCollection,
        field: 'class_id',
        values: classIds,
      );
      final classTeacherSubjects = await _store.queryByFieldIn(
        collectionName: OperationalFirestoreService.classTeacherSubjectsCollection,
        field: 'class_id',
        values: classIds,
      );
      final assignmentIds = classAssignments
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
        documentIds: classTeacherSubjects
            .map((row) => row['id']?.toString() ?? ''),
      );
      await _store.deleteDocumentsByIds(
        collectionName: OperationalFirestoreService.assignmentsCollection,
        documentIds: assignmentIds,
      );
      await _store.deleteDocumentsByIds(
        collectionName: OperationalFirestoreService.studentsCollection,
        documentIds: classStudents
            .map((row) => row['id']?.toString() ?? ''),
      );
      await _store.deleteDocumentsByIds(
        collectionName: OperationalFirestoreService.subjectsCollection,
        documentIds: classSubjects
            .map((row) => row['id']?.toString() ?? ''),
      );
      await _store.deleteDocumentsByIds(
        collectionName: OperationalFirestoreService.classesCollection,
        documentIds: classIds,
      );
    }

    final teachers = await _store.queryByField(
      collectionName: OperationalFirestoreService.teachersCollection,
      field: 'school_id',
      isEqualTo: id,
    );
    final teacherIds = teachers
        .map((row) => row['id']?.toString() ?? '')
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

    if (teacherIds.isNotEmpty) {
      final teacherAssignments = await _store.queryByFieldIn(
        collectionName: OperationalFirestoreService.classTeacherSubjectsCollection,
        field: 'teacher_id',
        values: teacherIds,
      );
      await _store.deleteDocumentsByIds(
        collectionName: OperationalFirestoreService.classTeacherSubjectsCollection,
        documentIds: teacherAssignments
            .map((row) => row['id']?.toString() ?? ''),
      );
      await _store.deleteDocumentsByIds(
        collectionName: OperationalFirestoreService.teachersCollection,
        documentIds: teacherIds,
      );
    }

    await _store.deleteDocument(
      collectionName: OperationalFirestoreService.schoolsCollection,
      documentId: id,
    );
  }
}
