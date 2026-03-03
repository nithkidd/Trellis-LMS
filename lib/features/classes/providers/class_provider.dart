import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/class_model.dart';
import '../repositories/class_repository.dart';
import '../../subjects/models/subject_model.dart';
import '../../subjects/repositories/subject_repository.dart';

// Provider for the ClassRepository
final classRepositoryProvider = Provider<ClassRepository>((ref) {
  return ClassRepository();
});

// Provider for the SubjectRepository
final _subjectRepositoryProvider = Provider<SubjectRepository>((ref) {
  return SubjectRepository();
});

// Predefined Khmer subjects to be added when a class is created
const _khmerSubjects = [
  'ភាសាខ្មែរ',
  'សីលធម៏័-ពលរដ្ធវិជ្ជា',
  'ប្រវត្តិវិទ្យា',
  'ភូមិវិទ្យា',
  'គណិតវិទ្យា',
  'រូបវិទ្យា',
  'គីមីវិទ្យា',
  'ជីវិទ្យា',
  'ផែនដីវិទ្យា',
  'ភាសាបរទេស',
  'បច្ចេកវិទ្យា',
  'គេហវិទ្យា',
  'អប់រំសិល្បៈ',
  'អប់រំកាយ កីឡា',
];

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

  Future<void> addClass(
    int schoolId,
    String name,
    String academicYear, {
    bool isAdviser = false,
    List<String>? subjects,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(classRepositoryProvider);
      final newClass = ClassModel(
        schoolId: schoolId,
        name: name,
        academicYear: academicYear,
        isAdviser: isAdviser,
      );
      final classId = await repository.insert(newClass);

      // For adviser classes, always create all subject fields for gradebook.
      // For non-adviser classes, create only selected subjects.
      final selectedSubjects = (subjects ?? [])
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList();
      final subjectsToAdd = isAdviser ? _khmerSubjects : selectedSubjects;
      if (subjectsToAdd.isNotEmpty) {
        final subjectRepository = ref.read(_subjectRepositoryProvider);

        for (final subject in subjectsToAdd) {
          final subjectModel = SubjectModel(classId: classId, name: subject);
          await subjectRepository.insert(subjectModel);
        }
      }

      return await repository.getClassesBySchoolId(
        _currentSchoolId ?? schoolId,
      );
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

      // We should ideally fetch current to preserve isAdviser but updateClassDetailed handles that now
      await repository.update(
        ClassModel(
          id: id,
          schoolId: _currentSchoolId!,
          name: name,
          academicYear: academicYear,
          isAdviser: false, // Legacy overwrite without data context
        ),
      );
      return await repository.getClassesBySchoolId(_currentSchoolId!);
    });
  }

  Future<void> updateClassDetailed(ClassModel classModel) async {
    if (_currentSchoolId == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(classRepositoryProvider);
      await repository.update(classModel);
      return await repository.getClassesBySchoolId(_currentSchoolId!);
    });
  }
}

final classNotifierProvider =
    AsyncNotifierProvider<ClassNotifier, List<ClassModel>>(() {
      return ClassNotifier();
    });
