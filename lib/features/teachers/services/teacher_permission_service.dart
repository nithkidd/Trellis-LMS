import '../../subjects/models/subject_model.dart';

/// Service class for managing teacher permissions and filtering access to subjects and assignments
class TeacherPermissionService {
  /// Filters subjects to show only those the teacher can edit
  ///
  /// - If no taughtSubjectIds provided, returns all subjects (for advisers)
  /// - Otherwise, returns only subjects the teacher teaches
  static List<SubjectModel> filterTeacherEditableSubjects({
    required List<SubjectModel> allSubjects,
    required List<int> taughtSubjectIds,
  }) {
    if (taughtSubjectIds.isEmpty) {
      // Adviser or teacher with no assigned subjects gets access to all
      return allSubjects;
    }

    // Filter to only subjects the teacher teaches
    return allSubjects
        .where((subject) => taughtSubjectIds.contains(subject.id))
        .toList();
  }

  /// Filters assignments to show only those the teacher can view/edit
  ///
  /// A teacher can only see assignments for subjects they teach
  static List<dynamic> filterAssignmentsByTeacherPermission({
    required List<dynamic> allAssignments,
    required List<int> taughtSubjectIds,
  }) {
    if (taughtSubjectIds.isEmpty) {
      // No taught subjects means show all assignments
      return allAssignments;
    }

    // Filter assignments to only those for subjects the teacher teaches
    return allAssignments
        .where((assignment) => taughtSubjectIds.contains(assignment.subjectId))
        .toList();
  }

  /// Checks if a teacher can delete an assignment
  ///
  /// A teacher can only delete assignments for subjects they teach
  static bool canDeleteAssignment({
    required int assignmentSubjectId,
    required List<int> taughtSubjectIds,
  }) {
    // Teacher can delete if they teach the subject or if they teach all subjects (adviser)
    return taughtSubjectIds.isEmpty ||
        taughtSubjectIds.contains(assignmentSubjectId);
  }

  /// Checks if a teacher can view assignments in the given subject
  static bool canViewAssignmentsForSubject({
    required int subjectId,
    required List<int> taughtSubjectIds,
  }) {
    // Can view if no restricted subjects or if they teach this subject
    return taughtSubjectIds.isEmpty || taughtSubjectIds.contains(subjectId);
  }

  /// Checks if a teacher can create assignments
  ///
  /// Teachers can create assignments if they teach at least one subject
  static bool canCreateAssignments({
    required List<int> taughtSubjectIds,
    required bool isAdviser,
  }) {
    // Regular teachers with taught subjects can create assignments
    // Advisers typically cannot create assignments (they just supervise)
    return !isAdviser && taughtSubjectIds.isNotEmpty;
  }

  /// Checks if a teacher can edit an assignment
  static bool canEditAssignment({
    required int assignmentSubjectId,
    required List<int> taughtSubjectIds,
    required bool isAdviser,
  }) {
    // Advisers cannot edit assignments
    if (isAdviser) return false;

    // Teachers can edit assignments for subjects they teach
    return taughtSubjectIds.isEmpty ||
        taughtSubjectIds.contains(assignmentSubjectId);
  }

  /// For advisers: subjects they do NOT directly teach.
  /// These can be treated as score-only subjects in UI logic.
  static List<SubjectModel> filterAdviserScoreOnlySubjects({
    required List<SubjectModel> allSubjects,
    required List<int> taughtSubjectIds,
  }) {
    return allSubjects
        .where((subject) => !taughtSubjectIds.contains(subject.id))
        .toList();
  }
}
