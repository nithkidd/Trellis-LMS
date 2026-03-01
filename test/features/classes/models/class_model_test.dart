import 'package:flutter_test/flutter_test.dart';
import 'package:trellis/features/classes/models/class_model.dart';

void main() {
  group('ClassModel Tests', () {
    test('should map properties correctly toMap()', () {
      final classModel = ClassModel(
        id: 1,
        name: 'Math 101',
        academicYear: '2023-2024',
      );

      final map = classModel.toMap();

      expect(map['id'], 1);
      expect(map['name'], 'Math 101');
      expect(map['academic_year'], '2023-2024');
    });

    test('should construct correctly fromMap()', () {
      final map = {
        'id': 2,
        'name': 'Science 101',
        'academic_year': '2024-2025',
      };

      final classModel = ClassModel.fromMap(map);

      expect(classModel.id, 2);
      expect(classModel.name, 'Science 101');
      expect(classModel.academicYear, '2024-2025');
    });

    test('should create a copy with new values using copyWith()', () {
      final classModel = ClassModel(
        id: 1,
        name: 'Math',
        academicYear: '2023',
      );

      final copiedModel = classModel.copyWith(name: 'Advanced Math');

      expect(copiedModel.id, 1);
      expect(copiedModel.name, 'Advanced Math');
      expect(copiedModel.academicYear, '2023');
    });
  });
}
