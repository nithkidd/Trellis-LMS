import '../../../core/database/operational_firestore_service.dart';
import '../../subjects/models/subject_model.dart';
import '../../teachers/models/teacher_model.dart';
import '../models/class_teacher_subject_model.dart';

class ClassTeacherSubjectRepository {
  ClassTeacherSubjectRepository({OperationalFirestoreService? store})
    : _store = store ?? OperationalFirestoreService();

  final OperationalFirestoreService _store;

  Future<String> insert(ClassTeacherSubjectModel model) async {
    final documentId = _documentId(
      classId: model.classId,
      teacherId: model.teacherId,
      subjectId: model.subjectId,
    );
    await _store.setDocument(
      collectionName: OperationalFirestoreService.classTeacherSubjectsCollection,
      documentId: documentId,
      data: model.toDto(),
      merge: false,
    );
    return documentId;
  }

  Future<void> delete(String id) async {
    await _store.deleteDocument(
      collectionName: OperationalFirestoreService.classTeacherSubjectsCollection,
      documentId: id,
    );
  }

  Future<void> deleteByClassAndTeacherAndSubject({
    required String classId,
    required String teacherId,
    required String subjectId,
  }) async {
    await _store.deleteDocument(
      collectionName: OperationalFirestoreService.classTeacherSubjectsCollection,
      documentId: _documentId(
        classId: classId,
        teacherId: teacherId,
        subjectId: subjectId,
      ),
    );
  }

  Future<List<ClassTeacherSubjectModel>> getByClassAndTeacher({
    required String classId,
    required String teacherId,
  }) async {
    final classRows = await _store.queryByField(
      collectionName: OperationalFirestoreService.classTeacherSubjectsCollection,
      field: 'class_id',
      isEqualTo: classId,
    );
    final rows = classRows
        .where((row) => row['teacher_id']?.toString() == teacherId)
        .toList(growable: false);

    return rows
        .map(
          (row) => ClassTeacherSubjectModel.fromDto(row, row['id'].toString()),
        )
        .toList();
  }

  Future<List<String>> getAssignedSubjectIds({
    required String classId,
    required String teacherId,
  }) async {
    final assignments = await getByClassAndTeacher(
      classId: classId,
      teacherId: teacherId,
    );
    return assignments.map((assignment) => assignment.subjectId).toList();
  }

  Future<List<ClassTeacherSubjectRow>> getTeachersByClassAndSubject({
    required String classId,
    required String subjectId,
  }) async {
    final classRows = await _store.queryByField(
      collectionName: OperationalFirestoreService.classTeacherSubjectsCollection,
      field: 'class_id',
      isEqualTo: classId,
    );
    final rows = classRows
        .where((row) => row['subject_id']?.toString() == subjectId)
        .toList(growable: false);
    return _loadJoinedRows(rows);
  }

  Future<List<ClassTeacherSubjectRow>> getSubjectsWithTeachers({
    required String classId,
  }) async {
    final rows = await _store.queryByField(
      collectionName: OperationalFirestoreService.classTeacherSubjectsCollection,
      field: 'class_id',
      isEqualTo: classId,
    );

    final assignments = await _loadJoinedRows(rows);
    assignments.sort((a, b) {
      final subjectCompare = a.subject.name.compareTo(b.subject.name);
      if (subjectCompare != 0) return subjectCompare;
      return a.teacher.name.compareTo(b.teacher.name);
    });
    return assignments;
  }

  Future<List<ClassTeacherSubjectRow>> _loadJoinedRows(
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) {
      return const [];
    }

    final teacherIds = rows
        .map((row) => row['teacher_id']?.toString() ?? '')
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    final subjectIds = rows
        .map((row) => row['subject_id']?.toString() ?? '')
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

    final teacherRows = await _store.queryByIds(
      collectionName: OperationalFirestoreService.teachersCollection,
      ids: teacherIds,
    );
    final subjectRows = await _store.queryByIds(
      collectionName: OperationalFirestoreService.subjectsCollection,
      ids: subjectIds,
    );

    final teachersById = {
      for (final teacher in teacherRows)
        teacher['id'].toString(): TeacherModel.fromDto(
          teacher,
          teacher['id'].toString(),
        ),
    };
    final subjectsById = {
      for (final subject in subjectRows)
        subject['id'].toString(): SubjectModel.fromDto(
          subject,
          subject['id'].toString(),
        ),
    };

    return rows
        .map((row) {
          final teacher = teachersById[row['teacher_id']?.toString()];
          final subject = subjectsById[row['subject_id']?.toString()];
          if (teacher == null || subject == null) {
            return null;
          }
          return ClassTeacherSubjectRow(
            teacher: teacher,
            subject: subject,
            assignmentId: row['id'].toString(),
          );
        })
        .whereType<ClassTeacherSubjectRow>()
        .toList(growable: false);
  }

  String _documentId({
    required String classId,
    required String teacherId,
    required String subjectId,
  }) {
    return '${classId}_${teacherId}_$subjectId';
  }
}
