import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../subjects/models/subject_model.dart';
import '../../teachers/providers/class_teacher_subject_provider.dart';
import '../../teachers/services/teacher_permission_service.dart';

/// Provides filtered subjects for gradebook based on teacher permissions
final gradebookVisibleSubjectsProvider =
    FutureProvider.family<
      List<SubjectModel>,
      (
        List<SubjectModel> allSubjects,
        int classId,
        int? teacherId,
        bool isAdviser,
      )
    >((ref, params) async {
      final (allSubjects, classId, teacherId, isAdviser) = params;

      if (teacherId == null) {
        // Admin view - show all subjects
        return allSubjects;
      }

      final taughtSubjects = await ref.watch(
        teacherSubjectsProvider((classId, teacherId)).future,
      );

      if (isAdviser) {
        // Adviser sees all subjects but will have restricted actions for some
        return allSubjects;
      } else {
        // Regular teacher - only sees subjects they teach
        return TeacherPermissionService.filterTeacherEditableSubjects(
          allSubjects: allSubjects,
          taughtSubjectIds: taughtSubjects,
        );
      }
    });

/// Provides subjects where an adviser can only add scores (not manage assignments)
final adviserScoreOnlySubjectsProvider =
    FutureProvider.family<
      List<SubjectModel>,
      (List<SubjectModel> allSubjects, int classId, int teacherId)
    >((ref, params) async {
      final (allSubjects, classId, teacherId) = params;

      final taughtSubjects = await ref.watch(
        teacherSubjectsProvider((classId, teacherId)).future,
      );

      return TeacherPermissionService.filterAdviserScoreOnlySubjects(
        allSubjects: allSubjects,
        taughtSubjectIds: taughtSubjects,
      );
    });
