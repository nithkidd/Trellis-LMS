import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/student_model.dart';
import '../repositories/student_repository.dart';

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepository();
});

class StudentNotifier extends AsyncNotifier<List<StudentModel>> {
  int? _currentClassId;

  @override
  FutureOr<List<StudentModel>> build() async {
    return [];
  }

  Future<void> loadStudentsForClass(int classId) async {
    _currentClassId = classId;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(studentRepositoryProvider);
      return await repository.getStudentsByClassId(classId);
    });
  }

  Future<void> addStudent(int classId, String name) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(studentRepositoryProvider);
      final newStudent = StudentModel(classId: classId, name: name);
      await repository.insert(newStudent);
      
      // Reload students for the current class
      return await repository.getStudentsByClassId(_currentClassId ?? classId);
    });
  }

  Future<void> deleteStudent(int id) async {
    if (_currentClassId == null) return;
    
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(studentRepositoryProvider);
      await repository.delete(id);
      
      // Reload students for the current class
      return await repository.getStudentsByClassId(_currentClassId!);
    });
  }

  Future<void> updateStudent(StudentModel updatedStudent) async {
    if (_currentClassId == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(studentRepositoryProvider);
      await repository.update(updatedStudent);
      return await repository.getStudentsByClassId(_currentClassId!);
    });
  }
}

final studentNotifierProvider = AsyncNotifierProvider<StudentNotifier, List<StudentModel>>(() {
  return StudentNotifier();
});
