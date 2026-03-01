import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:trellis/core/database/database_helper.dart';
import 'package:trellis/features/schools/models/school_model.dart';
import 'package:trellis/features/schools/repositories/school_repository.dart';

void main() {
  late SchoolRepository repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    DatabaseHelper.resetDatabase();
    final dbPath = join(await getDatabasesPath(), "TeacherLMS.db");
    await databaseFactory.deleteDatabase(dbPath);
    
    repository = SchoolRepository();
  });

  tearDown(() async {
    await DatabaseHelper.instance.close();
  });

  group('SchoolRepository Tests', () {
    test('should insert and retrieve a school', () async {
      final newSchool = SchoolModel(name: 'Lincoln High');
      final id = await repository.insert(newSchool);

      expect(id, isNotNull);
      expect(id, isPositive);

      final retrievedSchool = await repository.getById(id);
      expect(retrievedSchool, isNotNull);
      expect(retrievedSchool!.name, 'Lincoln High');
    });

    test('should retrieve all schools', () async {
      await repository.insert(SchoolModel(name: 'School A'));
      await repository.insert(SchoolModel(name: 'School B'));

      final schools = await repository.getAll();
      expect(schools.length, 2);
    });

    test('should update a school', () async {
      final id = await repository.insert(SchoolModel(name: 'Lincoln High'));
      
      final updatedSchool = SchoolModel(id: id, name: 'Lincoln Academy');
      await repository.update(updatedSchool);

      final retrievedSchool = await repository.getById(id);
      expect(retrievedSchool!.name, 'Lincoln Academy');
    });

    test('should delete a school', () async {
      final id = await repository.insert(SchoolModel(name: 'Lincoln High'));
      
      await repository.delete(id);

      final retrievedSchool = await repository.getById(id);
      expect(retrievedSchool, isNull);
    });
  });
}
