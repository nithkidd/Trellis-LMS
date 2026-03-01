import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subject_model.dart';
import '../repositories/subject_repository.dart';

final subjectRepositoryProvider = Provider((ref) => SubjectRepository());

final subjectNotifierProvider =
    AsyncNotifierProvider<SubjectNotifier, List<SubjectModel>>(() {
      return SubjectNotifier();
    });

class SubjectNotifier extends AsyncNotifier<List<SubjectModel>> {
  SubjectRepository get _repository => ref.read(subjectRepositoryProvider);

  @override
  Future<List<SubjectModel>> build() async {
    return [];
  }

  Future<void> loadSubjectsForClass(int classId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _repository.getByClassId(classId);
    });
  }

  Future<void> addSubject(int classId, String name) async {
    final newSubject = SubjectModel(classId: classId, name: name);
    await _repository.insert(newSubject);
    await loadSubjectsForClass(classId);
  }

  Future<void> updateSubject(SubjectModel subject) async {
    await _repository.update(subject);
    await loadSubjectsForClass(subject.classId);
  }

  Future<void> deleteSubject(int id, int classId) async {
    await _repository.delete(id);
    await loadSubjectsForClass(classId);
  }
}
