import 'package:flutter_test/flutter_test.dart';
import 'package:trellis/features/gradebook/models/score_model.dart';

void main() {
  group('ScoreModel Tests', () {
    test('should map properties correctly toMap()', () {
      final score = ScoreModel(
        id: 1,
        studentId: 2,
        assignmentId: 3,
        pointsEarned: 85.5,
      );

      final map = score.toMap();

      expect(map['id'], 1);
      expect(map['student_id'], 2);
      expect(map['assignment_id'], 3);
      expect(map['points_earned'], 85.5);
    });

    test('should construct correctly fromMap()', () {
      final map = {
        'id': 3,
        'student_id': 1,
        'assignment_id': 4,
        'points_earned': 92.0,
      };

      final score = ScoreModel.fromMap(map);

      expect(score.id, 3);
      expect(score.studentId, 1);
      expect(score.assignmentId, 4);
      expect(score.pointsEarned, 92.0);
    });

    test('should create a copy with new values using copyWith()', () {
      final score = ScoreModel(
        id: 1,
        studentId: 2,
        assignmentId: 3,
        pointsEarned: 8.0,
      );

      final copiedScore = score.copyWith(pointsEarned: 9.0);

      expect(copiedScore.id, 1);
      expect(copiedScore.studentId, 2);
      expect(copiedScore.assignmentId, 3);
      expect(copiedScore.pointsEarned, 9.0);
    });
  });
}
