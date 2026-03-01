import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:lms/core/database/database_helper.dart';
import 'package:lms/features/schools/models/school_model.dart';
import 'package:lms/features/schools/repositories/school_repository.dart';
import 'package:lms/features/classes/models/class_model.dart';
import 'package:lms/features/classes/repositories/class_repository.dart';
import 'package:lms/features/students/models/student_model.dart';
import 'package:lms/features/students/repositories/student_repository.dart';
import 'package:lms/features/assignments/models/assignment_model.dart';
import 'package:lms/features/assignments/repositories/assignment_repository.dart';
import 'package:lms/features/subjects/models/subject_model.dart';
import 'package:lms/features/subjects/repositories/subject_repository.dart';
import 'package:lms/features/gradebook/models/score_model.dart';
import 'package:lms/features/gradebook/repositories/score_repository.dart';

void main() {
  late ScoreRepository scoreRepo;
  late ClassRepository classRepo;
  late StudentRepository studentRepo;
  late AssignmentRepository assignmentRepo;
  int? testClassId;
  int? testStudentId;
  int? testAssignmentId1;
  int? testAssignmentId2;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    DatabaseHelper.resetDatabase();
    final dbPath = join(await getDatabasesPath(), "TeacherLMS.db");
    await databaseFactory.deleteDatabase(dbPath);
    
    scoreRepo = ScoreRepository();

    // Setup hierarchy
    final schoolRepo = SchoolRepository();
    final schoolId = await schoolRepo.insert(SchoolModel(name: 'Test School'));

    classRepo = ClassRepository();
    testClassId = await classRepo.insert(ClassModel(schoolId: schoolId, name: 'Math 101', academicYear: '2023'));

    studentRepo = StudentRepository();
    testStudentId = await studentRepo.insert(StudentModel(classId: testClassId!, name: 'Alice Smith'));

    final subjectRepo = SubjectRepository();
    final testSubjectId = await subjectRepo.insert(SubjectModel(classId: testClassId!, name: 'Math'));

    assignmentRepo = AssignmentRepository();
    testAssignmentId1 = await assignmentRepo.insert(AssignmentModel(classId: testClassId!, subjectId: testSubjectId, name: 'Midterm', month: 'Jan', year: '2023', maxPoints: 100));
    testAssignmentId2 = await assignmentRepo.insert(AssignmentModel(classId: testClassId!, subjectId: testSubjectId, name: 'Final', month: 'Feb', year: '2023', maxPoints: 200));
  });

  tearDown(() async {
    await DatabaseHelper.instance.close();
  });

  group('ScoreRepository Tests', () {
    test('should upsert and retrieve a score', () async {
      final newScore = ScoreModel(
        studentId: testStudentId!,
        assignmentId: testAssignmentId1!,
        pointsEarned: 85.0,
      );
      final id = await scoreRepo.upsert(newScore);

      expect(id, isNotNull);
      expect(id, isPositive);

      final scores = await scoreRepo.getScoresByStudentId(testStudentId!);
      expect(scores.length, 1);
      expect(scores.first.assignmentId, testAssignmentId1!);
      expect(scores.first.pointsEarned, 85.0);
    });

    test('upsert should overwrite existing score for the same assignment', () async {
      final score1 = ScoreModel(studentId: testStudentId!, assignmentId: testAssignmentId1!, pointsEarned: 50.0);
      await scoreRepo.upsert(score1);

      // Same assignment, different score
      final score2 = ScoreModel(studentId: testStudentId!, assignmentId: testAssignmentId1!, pointsEarned: 90.0);
      await scoreRepo.upsert(score2);

      final scores = await scoreRepo.getScoresByStudentId(testStudentId!);
      expect(scores.length, 1, reason: 'It should replace, not add a new row');
      expect(scores.first.pointsEarned, 90.0);
    });

    test('should calculate average score correctly across assignments', () async {
      await scoreRepo.upsert(ScoreModel(studentId: testStudentId!, assignmentId: testAssignmentId1!, pointsEarned: 80.0)); // 80 out of 100
      await scoreRepo.upsert(ScoreModel(studentId: testStudentId!, assignmentId: testAssignmentId2!, pointsEarned: 160.0)); // 160 out of 200

      // Total earned: 80 + 160 = 240
      // Total max: 100 + 200 = 300
      // Expected Average = 240 / 300 = 0.8 = 80.0%
      final average = await scoreRepo.getAverageScoreByStudentId(testStudentId!);
      expect(average, 80.0);
    });

    test('should cascade delete scores when student is deleted', () async {
      final scoreId = await scoreRepo.upsert(
        ScoreModel(studentId: testStudentId!, assignmentId: testAssignmentId1!, pointsEarned: 90)
      );
      
      await studentRepo.delete(testStudentId!);
      
      final retrievedScore = await scoreRepo.getById(scoreId);
      expect(retrievedScore, isNull);
    });
    
    test('should cascade delete scores when assignment is deleted', () async {
      final scoreId = await scoreRepo.upsert(
        ScoreModel(studentId: testStudentId!, assignmentId: testAssignmentId1!, pointsEarned: 90)
      );
      
      await assignmentRepo.delete(testAssignmentId1!);
      
      final retrievedScore = await scoreRepo.getById(scoreId);
      expect(retrievedScore, isNull);
    });
  });
}
