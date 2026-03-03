import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/teacher_model.dart';
import '../repositories/teacher_repository.dart';

final teacherRepositoryProvider = Provider<TeacherRepository>((ref) {
  return TeacherRepository();
});

class TeacherNotifier extends AsyncNotifier<List<TeacherModel>> {
  int? _currentSchoolId;

  @override
  FutureOr<List<TeacherModel>> build() async {
    return [];
  }

  Future<void> loadTeachersForSchool(int schoolId) async {
    _currentSchoolId = schoolId;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(teacherRepositoryProvider);
      return await repository.getTeachersBySchoolId(schoolId);
    });
  }

  Future<void> addTeacher(int schoolId, String name) async {
    if (_currentSchoolId == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(teacherRepositoryProvider);
      final newTeacher = TeacherModel(schoolId: schoolId, name: name);
      await repository.insert(newTeacher);
      return await repository.getTeachersBySchoolId(_currentSchoolId!);
    });
  }

  Future<void> updateTeacher(TeacherModel teacher) async {
    if (_currentSchoolId == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(teacherRepositoryProvider);
      await repository.update(teacher);
      return await repository.getTeachersBySchoolId(_currentSchoolId!);
    });
  }

  Future<void> deleteTeacher(int id) async {
    if (_currentSchoolId == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(teacherRepositoryProvider);
      await repository.delete(id);
      return await repository.getTeachersBySchoolId(_currentSchoolId!);
    });
  }
}

final teacherNotifierProvider =
    AsyncNotifierProvider<TeacherNotifier, List<TeacherModel>>(() {
      return TeacherNotifier();
    });
