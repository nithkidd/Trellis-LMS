import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/class_model.dart';
import '../repositories/class_repository.dart';

// Provider for the ClassRepository
final classRepositoryProvider = Provider<ClassRepository>((ref) {
  return ClassRepository();
});

class ClassNotifier extends AsyncNotifier<List<ClassModel>> {
  int? _currentSchoolId;

  @override
  FutureOr<List<ClassModel>> build() async {
    return [];
  }

  Future<void> loadClassesForSchool(int schoolId) async {
    _currentSchoolId = schoolId;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(classRepositoryProvider);
      return await repository.getClassesBySchoolId(schoolId);
    });
  }

  Future<void> addClass(int schoolId, String name, String academicYear) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(classRepositoryProvider);
      final newClass = ClassModel(schoolId: schoolId, name: name, academicYear: academicYear);
      await repository.insert(newClass);
      
      return await repository.getClassesBySchoolId(_currentSchoolId ?? schoolId);
    });
  }

  Future<void> deleteClass(int id) async {
    if (_currentSchoolId == null) return;
    
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(classRepositoryProvider);
      await repository.delete(id);
      
      return await repository.getClassesBySchoolId(_currentSchoolId!);
    });
  }

  Future<void> updateClass(int id, String name, String academicYear) async {
    if (_currentSchoolId == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(classRepositoryProvider);
      await repository.update(ClassModel(
        id: id,
        schoolId: _currentSchoolId!,
        name: name,
        academicYear: academicYear,
      ));
      return await repository.getClassesBySchoolId(_currentSchoolId!);
    });
  }
}

final classNotifierProvider = AsyncNotifierProvider<ClassNotifier, List<ClassModel>>(() {
  return ClassNotifier();
});
