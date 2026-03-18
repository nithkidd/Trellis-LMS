import '../../../core/database/operational_firestore_service.dart';
import '../../assignments/models/assignment_model.dart';
import '../../assignments/repositories/assignment_repository.dart';
import '../models/score_model.dart';

class ScoreRepository {
  ScoreRepository({
    OperationalFirestoreService? store,
    AssignmentRepository? assignmentRepository,
  }) : _store = store ?? OperationalFirestoreService(),
       _assignmentRepository = assignmentRepository ?? AssignmentRepository();

  final OperationalFirestoreService _store;
  final AssignmentRepository _assignmentRepository;

  Future<String> upsert(ScoreModel score) async {
    final documentId = _scoreDocumentId(
      studentId: score.studentId,
      assignmentId: score.assignmentId,
    );
    await _store.setDocument(
      collectionName: OperationalFirestoreService.scoresCollection,
      documentId: documentId,
      data: score.toDto(),
      merge: false,
    );
    return documentId;
  }

  Future<List<ScoreModel>> getScoresByStudentId(String studentId) async {
    final rows = await _store.queryByField(
      collectionName: OperationalFirestoreService.scoresCollection,
      field: 'student_id',
      isEqualTo: studentId,
    );
    return rows
        .map((row) => ScoreModel.fromDto(row, row['id'].toString()))
        .toList();
  }

  Future<List<ScoreModel>> getScoresByAssignmentId(String assignmentId) async {
    final rows = await _store.queryByField(
      collectionName: OperationalFirestoreService.scoresCollection,
      field: 'assignment_id',
      isEqualTo: assignmentId,
    );
    return rows
        .map((row) => ScoreModel.fromDto(row, row['id'].toString()))
        .toList();
  }

  Future<ScoreModel?> getById(String id) async {
    final row = await _store.getDocument(
      collectionName: OperationalFirestoreService.scoresCollection,
      documentId: id,
    );
    if (row == null) return null;
    return ScoreModel.fromDto(row, row['id'].toString());
  }

  Future<void> update(ScoreModel score) async {
    if (score.id == null) return;

    await _store.setDocument(
      collectionName: OperationalFirestoreService.scoresCollection,
      documentId: score.id!,
      data: score.toDto(),
      merge: false,
    );
  }

  Future<void> delete(String id) async {
    await _store.deleteDocument(
      collectionName: OperationalFirestoreService.scoresCollection,
      documentId: id,
    );
  }

  Future<List<ScoreModel>> getScoresByClassId(String classId) async {
    final assignments = await _assignmentRepository.getByClassId(classId);
    final assignmentIds = assignments
        .map((assignment) => assignment.id)
        .whereType<String>()
        .toList(growable: false);
    final rows = await _store.queryByFieldIn(
      collectionName: OperationalFirestoreService.scoresCollection,
      field: 'assignment_id',
      values: assignmentIds,
    );
    return rows
        .map((row) => ScoreModel.fromDto(row, row['id'].toString()))
        .toList();
  }

  Future<double> getAverageScoreByStudentId(String studentId) async {
    final scores = await getScoresByStudentId(studentId);
    if (scores.isEmpty) return 0.0;

    final assignments = await Future.wait(
      scores.map((score) => _assignmentRepository.getById(score.assignmentId)),
    );
    final assignmentsById = {
      for (final assignment in assignments.whereType<AssignmentModel>())
        if (assignment.id != null) assignment.id!: assignment,
    };

    final rows = scores
        .map((score) {
          final assignment = assignmentsById[score.assignmentId];
          if (assignment == null) {
            return null;
          }
          return {
            'points_earned': score.pointsEarned,
            'max_points': assignment.maxPoints,
          };
        })
        .whereType<Map<String, Object?>>()
        .toList(growable: false);
    if (rows.isEmpty) return 0.0;

    double totalEarned = 0;
    double totalMax = 0;
    for (final row in rows) {
      totalEarned += double.tryParse(row['points_earned'].toString()) ?? 0.0;
      totalMax += double.tryParse(row['max_points'].toString()) ?? 0.0;
    }

    return totalMax > 0 ? (totalEarned / totalMax) * 100 : 0.0;
  }

  String _scoreDocumentId({
    required String studentId,
    required String assignmentId,
  }) {
    return '${assignmentId}_$studentId';
  }
}
