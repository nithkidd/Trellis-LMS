import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:trellis/core/database/database_helper.dart';
import 'package:trellis/features/schools/models/school_model.dart';
import 'package:trellis/features/schools/repositories/school_repository.dart';
import 'package:trellis/features/classes/models/class_model.dart';
import 'package:trellis/features/classes/repositories/class_repository.dart';
import 'package:trellis/features/students/models/student_model.dart';
import 'package:trellis/features/students/repositories/student_repository.dart';

void main() {
  late SchoolRepository schoolRepo;
  late ClassRepository classRepo;
  late StudentRepository studentRepo;
  int? testSchoolId;
  int? testClassId;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    DatabaseHelper.resetDatabase();
    final dbPath = join(await getDatabasesPath(), "TeacherLMS.db");
    await databaseFactory.deleteDatabase(dbPath);
    
    schoolRepo = SchoolRepository();
    classRepo = ClassRepository();
    studentRepo = StudentRepository();

    // Create hierarchy for foreign key constraints
    testSchoolId = await schoolRepo.insert(SchoolModel(name: 'Test School'));
    testClassId = await classRepo.insert(ClassModel(schoolId: testSchoolId!, name: 'Science', academicYear: '2023'));
  });

  tearDown(() async {
    await DatabaseHelper.instance.close();
  });

  group('StudentRepository Tests', () {
    test('should insert and retrieve a student', () async {
      final student = StudentModel(classId: testClassId!, name: 'Alice');
      final id = await studentRepo.insert(student);

      final retrievedStudent = await studentRepo.getById(id);
      expect(retrievedStudent, isNotNull);
      expect(retrievedStudent!.name, 'Alice');
      expect(retrievedStudent.classId, testClassId!);
    });

    test('should get students by classId', () async {
      await studentRepo.insert(StudentModel(classId: testClassId!, name: 'Alice'));
      await studentRepo.insert(StudentModel(classId: testClassId!, name: 'Bob'));

      final students = await studentRepo.getStudentsByClassId(testClassId!);
      expect(students.length, 2);
    });

    test('should update a student', () async {
      final id = await studentRepo.insert(StudentModel(classId: testClassId!, name: 'Charlie'));
      
      final updatedStudent = StudentModel(id: id, classId: testClassId!, name: 'Charlie Updated');
      await studentRepo.update(updatedStudent);

      final retrievedStudent = await studentRepo.getById(id);
      expect(retrievedStudent!.name, 'Charlie Updated');
    });

    test('should delete a student', () async {
      final id = await studentRepo.insert(StudentModel(classId: testClassId!, name: 'Dave'));
      
      await studentRepo.delete(id);

      final retrievedStudent = await studentRepo.getById(id);
      expect(retrievedStudent, isNull);
    });
    
    test('should cascade delete students when class is deleted', () async {
      final studentId = await studentRepo.insert(StudentModel(classId: testClassId!, name: 'Eve'));
      
      // Delete the class
      await classRepo.delete(testClassId!);
      
      // The student should be automatically removed due to CASCADE DELETE
      final retrievedStudent = await studentRepo.getById(studentId);
      expect(retrievedStudent, isNull);
    });
  });
}
