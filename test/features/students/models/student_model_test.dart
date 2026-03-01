import 'package:flutter_test/flutter_test.dart';
import 'package:trellis/features/students/models/student_model.dart';

void main() {
  group('StudentModel Tests', () {
    test('should map properties correctly toMap()', () {
      final student = StudentModel(
        id: 1,
        classId: 2,
        name: 'John Doe',
      );

      final map = student.toMap();

      expect(map['id'], 1);
      expect(map['class_id'], 2);
      expect(map['name'], 'John Doe');
    });

    test('should construct correctly fromMap()', () {
      final map = {
        'id': 3,
        'class_id': 1,
        'name': 'Jane Doe',
      };

      final student = StudentModel.fromMap(map);

      expect(student.id, 3);
      expect(student.classId, 1);
      expect(student.name, 'Jane Doe');
    });

    test('should create a copy with new values using copyWith()', () {
      final student = StudentModel(
        id: 1,
        classId: 2,
        name: 'John',
      );

      final copiedStudent = student.copyWith(classId: 3);

      expect(copiedStudent.id, 1);
      expect(copiedStudent.classId, 3);
      expect(copiedStudent.name, 'John');
    });
  });
}
