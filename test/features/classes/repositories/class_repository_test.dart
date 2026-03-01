import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:trellis/core/database/database_helper.dart';
import 'package:trellis/features/schools/models/school_model.dart';
import 'package:trellis/features/schools/repositories/school_repository.dart';
import 'package:trellis/features/classes/models/class_model.dart';
import 'package:trellis/features/classes/repositories/class_repository.dart';

void main() {
  late SchoolRepository schoolRepo;
  late ClassRepository classRepo;
  int? testSchoolId;

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

    testSchoolId = await schoolRepo.insert(SchoolModel(name: 'Test School'));
  });

  tearDown(() async {
    await DatabaseHelper.instance.close();
  });

  group('ClassRepository Tests', () {
    test('should insert and retrieve a class', () async {
      final newClass = ClassModel(schoolId: testSchoolId!, name: 'Math', academicYear: '2023');
      final id = await classRepo.insert(newClass);

      expect(id, isNotNull);
      expect(id, isPositive);

      final retrievedClass = await classRepo.getById(id);
      expect(retrievedClass, isNotNull);
      expect(retrievedClass!.schoolId, testSchoolId!);
      expect(retrievedClass.name, 'Math');
    });

    test('should retrieve classes by schoolId', () async {
      await classRepo.insert(ClassModel(schoolId: testSchoolId!, name: 'Class A', academicYear: '2023'));
      await classRepo.insert(ClassModel(schoolId: testSchoolId!, name: 'Class B', academicYear: '2023'));

      final classes = await classRepo.getClassesBySchoolId(testSchoolId!);
      expect(classes.length, 2);
    });

    test('should update a class', () async {
      final id = await classRepo.insert(ClassModel(schoolId: testSchoolId!, name: 'Math', academicYear: '2023'));
      
      final updatedClass = ClassModel(id: id, schoolId: testSchoolId!, name: 'Advanced Math', academicYear: '2024');
      await classRepo.update(updatedClass);

      final retrievedClass = await classRepo.getById(id);
      expect(retrievedClass!.name, 'Advanced Math');
      expect(retrievedClass.academicYear, '2024');
    });

    test('should delete a class', () async {
      final id = await classRepo.insert(ClassModel(schoolId: testSchoolId!, name: 'History', academicYear: '2023'));
      
      await classRepo.delete(id);

      final retrievedClass = await classRepo.getById(id);
      expect(retrievedClass, isNull);
    });

    test('should cascade delete classes when school is deleted', () async {
      final classId = await classRepo.insert(ClassModel(schoolId: testSchoolId!, name: 'Physics', academicYear: '2023'));
      
      await schoolRepo.delete(testSchoolId!);
      
      final retrievedClass = await classRepo.getById(classId);
      expect(retrievedClass, isNull);
    });
  });
}
