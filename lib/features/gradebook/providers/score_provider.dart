import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/score_model.dart';
import '../repositories/score_repository.dart';
import '../../assignments/models/assignment_model.dart';
import '../../assignments/providers/assignment_provider.dart';

final scoreRepositoryProvider = Provider<ScoreRepository>((ref) {
  return ScoreRepository();
});

class ScoreNotifier extends AsyncNotifier<List<ScoreModel>> {
  int? _currentAssignmentId;

  @override
  FutureOr<List<ScoreModel>> build() async {
    return [];
  }

  // Used by the Batch Grading UI to load all scores for an assignment column
  Future<void> loadScoresForAssignment(int assignmentId) async {
    _currentAssignmentId = assignmentId;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(scoreRepositoryProvider);
      return await repository.getScoresByAssignmentId(assignmentId);
    });
  }

  // Fast continuous upserts during batch grading
  Future<void> saveScoreForAssignment(int studentId, int assignmentId, double pointsEarned) async {
    final repository = ref.read(scoreRepositoryProvider);
    final newScore = ScoreModel(
      studentId: studentId,
      assignmentId: assignmentId,
      pointsEarned: pointsEarned,
    );
    await repository.upsert(newScore);
    
    // Refresh the column in the background seamlessly
    if (_currentAssignmentId == assignmentId) {
       final updatedScores = await repository.getScoresByAssignmentId(assignmentId);
       state = AsyncValue.data(updatedScores);
    }
  }

  Future<void> deleteScore(int id) async {
    if (_currentAssignmentId == null) return;
    
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(scoreRepositoryProvider);
      await repository.delete(id);
      
      return await repository.getScoresByAssignmentId(_currentAssignmentId!);
    });
  }
}

final scoreNotifierProvider = AsyncNotifierProvider<ScoreNotifier, List<ScoreModel>>(() {
  return ScoreNotifier();
});



// Composite class for the Student Profile Screen
class StudentProfileScore {
  final ScoreModel score;
  final AssignmentModel assignment;

  StudentProfileScore({required this.score, required this.assignment});

  double get percentage => (score.pointsEarned / assignment.maxPoints) * 100;
}

class StudentProfileData {
  final List<StudentProfileScore> scores;
  final double averagePercentage;

  StudentProfileData({required this.scores, required this.averagePercentage});
}

// A dedicated provider used by the Student Profile Page to fetch scores joined with assignments
final studentProfileDataProvider = FutureProvider.autoDispose.family<StudentProfileData, int>((ref, studentId) async {
  // Watch the global scoreNotifierProvider so this screen reacts to ANY score changes in real-time
  ref.watch(scoreNotifierProvider);
  
  final scoreRepo = ref.read(scoreRepositoryProvider);
  final assignmentRepo = ref.read(assignmentRepositoryProvider);
  
  final scores = await scoreRepo.getScoresByStudentId(studentId);
  final average = await scoreRepo.getAverageScoreByStudentId(studentId);
  
  List<StudentProfileScore> profileScores = [];
  for (var score in scores) {
    if (score.assignmentId != null) {
       final assignment = await assignmentRepo.getById(score.assignmentId);
       if (assignment != null) {
         profileScores.add(StudentProfileScore(score: score, assignment: assignment));
       }
    }
  }
  
  return StudentProfileData(
    scores: profileScores.reversed.toList(),
    averagePercentage: average
  );
});
