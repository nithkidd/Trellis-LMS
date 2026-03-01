import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/assignment_model.dart';
import '../repositories/assignment_repository.dart';

final assignmentRepositoryProvider = Provider<AssignmentRepository>((ref) {
  return AssignmentRepository();
});

class AssignmentNotifier extends AsyncNotifier<List<AssignmentModel>> {
  int? _currentClassId;

  @override
  FutureOr<List<AssignmentModel>> build() async {
    return [];
  }

  Future<void> loadAssignmentsForClass(int classId) async {
    _currentClassId = classId;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(assignmentRepositoryProvider);
      return await repository.getByClassId(classId);
    });
  }

  Future<void> addAssignment(int classId, int subjectId, String name, String month, String year, double maxPoints) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(assignmentRepositoryProvider);
      final newAssignment = AssignmentModel(
        classId: classId,
        subjectId: subjectId,
        name: name,
        month: month,
        year: year,
        maxPoints: maxPoints,
      );
      await repository.insert(newAssignment);
      
      return await repository.getByClassId(_currentClassId ?? classId);
    });
  }

  Future<void> deleteAssignment(int id) async {
    if (_currentClassId == null) return;
    
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(assignmentRepositoryProvider);
      await repository.delete(id);
      
      return await repository.getByClassId(_currentClassId!);
    });
  }

  Future<void> updateAssignment(AssignmentModel updated) async {
    if (_currentClassId == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(assignmentRepositoryProvider);
      await repository.update(updated);
      return await repository.getByClassId(_currentClassId!);
    });
  }
}

final assignmentNotifierProvider = AsyncNotifierProvider<AssignmentNotifier, List<AssignmentModel>>(() {
  return AssignmentNotifier();
});
