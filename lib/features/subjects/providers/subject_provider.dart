import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subject_model.dart';
import '../repositories/subject_repository.dart';

const List<String> kAdviserDefaultSubjects = [
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

  Future<void> reorderSubjects(
    int classId,
    List<SubjectModel> orderedSubjects,
  ) async {
    await _repository.reorderSubjects(
      classId: classId,
      orderedSubjects: orderedSubjects,
    );
    await loadSubjectsForClass(classId);
  }

  Future<int> syncMissingAdviserSubjects(int classId) async {
    final existing = await _repository.getByClassId(classId);
    final existingNames = existing
        .map((subject) => subject.name.trim())
        .where((name) => name.isNotEmpty)
        .toSet();

    int inserted = 0;
    for (final subjectName in kAdviserDefaultSubjects) {
      if (!existingNames.contains(subjectName)) {
        await _repository.insert(
          SubjectModel(classId: classId, name: subjectName),
        );
        inserted++;
      }
    }

    await loadSubjectsForClass(classId);
    return inserted;
  }
}
