import '../../teachers/models/teacher_model.dart';
import '../../subjects/models/subject_model.dart';

class ClassTeacherSubjectModel {
  final int? id;
  final int classId;
  final int teacherId;
  final int subjectId;

  ClassTeacherSubjectModel({
    this.id,
    required this.classId,
    required this.teacherId,
    required this.subjectId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'class_id': classId,
      'teacher_id': teacherId,
      'subject_id': subjectId,
    };
  }

  factory ClassTeacherSubjectModel.fromMap(Map<String, dynamic> map) {
    return ClassTeacherSubjectModel(
      id: map['id'] != null ? map['id'] as int : null,
      classId: map['class_id'] as int,
      teacherId: map['teacher_id'] as int,
      subjectId: map['subject_id'] as int,
    );
  }

  ClassTeacherSubjectModel copyWith({
    int? id,
    int? classId,
    int? teacherId,
    int? subjectId,
  }) {
    return ClassTeacherSubjectModel(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      teacherId: teacherId ?? this.teacherId,
      subjectId: subjectId ?? this.subjectId,
    );
  }

  @override
  String toString() =>
      'ClassTeacherSubjectModel(id: $id, classId: $classId, teacherId: $teacherId, subjectId: $subjectId)';
}

// DTO for displaying with teacher and subject details
class ClassTeacherSubjectRow {
  final TeacherModel teacher;
  final SubjectModel subject;
  final int assignmentId;

  ClassTeacherSubjectRow({
    required this.teacher,
    required this.subject,
    required this.assignmentId,
  });
}
