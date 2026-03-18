import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/auth/models/app_user_profile.dart';
import '../../../core/auth/models/app_user_role.dart';
import '../../../core/auth/services/auth_service.dart';
import '../../../core/database/operational_firestore_service.dart';
import '../../../core/utils/khmer_collator.dart';
import '../../assignments/data/khmer_months_list.dart';
import '../../assignments/models/assignment_model.dart';
import '../../classes/models/class_model.dart';
import '../../gradebook/models/score_model.dart';
import '../../schools/models/school_model.dart';
import '../../students/models/student_model.dart';
import '../../subjects/models/subject_model.dart';
import '../../teachers/models/class_teacher_subject_model.dart';
import '../../teachers/models/teacher_model.dart';
import '../models/dashboard_summary.dart';

class DashboardRepository {
  DashboardRepository({
    FirebaseFirestore? firestore,
    OperationalFirestoreService? operationalStore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _operationalStore =
           operationalStore ??
           OperationalFirestoreService(
             firestore: firestore ?? FirebaseFirestore.instance,
           );

  static const Duration _firestoreReadTimeout = Duration(seconds: 12);
  static const Duration _localSnapshotTimeout = Duration(seconds: 8);
  static const Duration _webLocalSnapshotTimeout = Duration(seconds: 3);

  final FirebaseFirestore _firestore;
  final OperationalFirestoreService _operationalStore;

  Future<SuperadminDashboardSummary> loadSuperadminSummary(
    AppUserProfile viewer,
  ) async {
    final profileFuture = _loadProfilesSafely();
    final localFuture = _loadLocalSnapshotSafely();
    final profileResult = await profileFuture;
    final localResult = await localFuture;
    final local = localResult.snapshot;

    final organizations = profileResult.profiles
        .map((profile) => profile.organizationId?.trim() ?? '')
        .where((value) => value.isNotEmpty)
        .toSet();
    final activeAdmins = profileResult.profiles
        .where(
          (profile) =>
              profile.role == AppUserRole.organizationAdmin && profile.isActive,
        )
        .length;
    final activeTeachers = profileResult.profiles
        .where(
          (profile) => profile.role == AppUserRole.teacher && profile.isActive,
        )
        .length;
    final inactiveAccounts = profileResult.profiles
        .where((profile) => !profile.isActive)
        .length;

    final teacherIds = local.teachers
        .map((teacher) => teacher.id)
        .whereType<String>()
        .toSet();
    final teacherProfileIds = profileResult.profiles
        .where((profile) => profile.role == AppUserRole.teacher)
        .map((profile) => profile.teacherId?.trim() ?? '')
        .where((value) => value.isNotEmpty)
        .toSet();

    final missingScopeProfiles = profileResult.profiles.where((profile) {
      if (profile.role == AppUserRole.superadmin) {
        return false;
      }
      return _isBlank(profile.organizationId);
    }).length;

    final orphanedTeacherProfiles = profileResult.profiles.where((profile) {
      if (profile.role != AppUserRole.teacher) {
        return false;
      }
      final teacherId = profile.teacherId?.trim();
      return teacherId == null ||
          teacherId.isEmpty ||
          !teacherIds.contains(teacherId);
    }).length;

    final localTeachersWithoutProfile = local.teachers.where((teacher) {
      final teacherId = teacher.id;
      return teacherId != null && !teacherProfileIds.contains(teacherId);
    }).length;

    final schoolsWithoutTeachers = local.schools.where((school) {
      final schoolId = school.id;
      return schoolId != null &&
          !local.teachers.any((teacher) => teacher.schoolId == schoolId);
    }).length;

    final classInsights = _buildClassInsights(
      classes: local.classes,
      subjects: local.subjects,
      assignments: local.assignments,
      scores: local.scores,
      students: local.students,
      teacherAssignments: local.teacherAssignments,
    );

    final classesMissingAssignments = classInsights
        .where((insight) => !insight.hasCurrentMonthAssignments)
        .length;
    final classesWithLowCompletion = classInsights
        .where((insight) => insight.hasLowGradebookCoverage)
        .length;
    final subjectsWithoutCoverage = local.subjects.where((subject) {
      final subjectId = subject.id;
      return subjectId != null &&
          !local.teacherAssignments.any(
            (assignment) => assignment.subjectId == subjectId,
          );
    }).length;

    final platformAlerts = <DashboardAlert>[
      if (profileResult.errorMessage != null)
        DashboardAlert(
          title: 'Access profiles unavailable',
          message: profileResult.errorMessage!,
          severity: DashboardAlertSeverity.warning,
        ),
      if (localResult.errorMessage != null)
        DashboardAlert(
          title: 'Operational snapshot unavailable',
          message: localResult.errorMessage!,
          severity: DashboardAlertSeverity.warning,
        ),
      if (profileResult.invalidDocumentCount > 0)
        DashboardAlert(
          title: 'Unsupported profile documents',
          message:
              '${profileResult.invalidDocumentCount} profile documents could not be parsed into supported Trellis roles.',
          severity: DashboardAlertSeverity.warning,
          count: profileResult.invalidDocumentCount,
        ),
      if (missingScopeProfiles > 0)
        DashboardAlert(
          title: 'Profiles missing scope',
          message:
              '$missingScopeProfiles non-superadmin accounts are missing organization scope.',
          severity: DashboardAlertSeverity.critical,
          count: missingScopeProfiles,
        ),
      if (orphanedTeacherProfiles > 0)
        DashboardAlert(
          title: 'Teacher profile mismatches',
          message:
              '$orphanedTeacherProfiles teacher accounts point to missing or blank teacher records.',
          severity: DashboardAlertSeverity.critical,
          count: orphanedTeacherProfiles,
        ),
      if (localTeachersWithoutProfile > 0)
        DashboardAlert(
          title: 'Local teachers without accounts',
          message:
              '$localTeachersWithoutProfile teacher records do not have a matching teacher profile yet.',
          severity: DashboardAlertSeverity.warning,
          count: localTeachersWithoutProfile,
        ),
    ];

    final schoolRows =
        local.schools
            .map((school) {
              final schoolId = school.id;
              final schoolClasses = local.classes
                  .where((classModel) => classModel.schoolId == schoolId)
                  .toList(growable: false);
              final schoolClassIds = schoolClasses
                  .map((classModel) => classModel.id)
                  .whereType<String>()
                  .toSet();
              final schoolTeachers = local.teachers
                  .where((teacher) => teacher.schoolId == schoolId)
                  .length;
              final schoolSubjects = local.subjects
                  .where((subject) => schoolClassIds.contains(subject.classId))
                  .length;

              final schoolInsights = classInsights
                  .where((insight) => schoolClassIds.contains(insight.classId))
                  .toList(growable: false);
              final issueScore =
                  schoolInsights.fold<int>(
                    0,
                    (total, item) => total + item.issueScore,
                  ) +
                  (schoolTeachers == 0 ? 2 : 0) +
                  (schoolSubjects == 0 && schoolClassIds.isNotEmpty ? 1 : 0);
              final classesNeedingAttention = schoolInsights
                  .where((insight) => insight.issueScore > 0)
                  .length;

              return DashboardRankingRow(
                title: school.name,
                detail:
                    '$classesNeedingAttention classes need attention / $schoolTeachers teachers / $schoolSubjects subjects',
                metricLabel: issueScore == 0 ? 'Stable' : '$issueScore issues',
                score: issueScore,
                schoolId: schoolId,
              );
            })
            .toList(growable: false)
          ..sort((a, b) {
            final scoreCompare = b.score.compareTo(a.score);
            if (scoreCompare != 0) {
              return scoreCompare;
            }
            return a.title.compareTo(b.title);
          });

    final accessRows = [
      DashboardRankingRow(
        title: 'Organization admins',
        detail:
            '$activeAdmins active / ${_countInactive(profileResult.profiles, AppUserRole.organizationAdmin)} inactive',
        metricLabel:
            '${_countRole(profileResult.profiles, AppUserRole.organizationAdmin)} accounts',
        score: _countRole(
          profileResult.profiles,
          AppUserRole.organizationAdmin,
        ),
      ),
      DashboardRankingRow(
        title: 'Teacher accounts',
        detail:
            '$activeTeachers active / ${_countInactive(profileResult.profiles, AppUserRole.teacher)} inactive',
        metricLabel:
            '${_countRole(profileResult.profiles, AppUserRole.teacher)} accounts',
        score: _countRole(profileResult.profiles, AppUserRole.teacher),
      ),
      DashboardRankingRow(
        title: 'Profiles missing scope',
        detail:
            'Accounts need an organization identifier before permissions are trustworthy.',
        metricLabel: '$missingScopeProfiles accounts',
        score: missingScopeProfiles,
      ),
      DashboardRankingRow(
        title: 'Teacher links to repair',
        detail: 'Teacher profiles with blank or missing `teacherId` mappings.',
        metricLabel: '$orphanedTeacherProfiles profiles',
        score: orphanedTeacherProfiles,
      ),
    ];

    final globalTrendRows = [
      DashboardRankingRow(
        title: 'Schools without teachers',
        detail: 'Schools that cannot operate staffing workflows yet.',
        metricLabel: '$schoolsWithoutTeachers schools',
        score: schoolsWithoutTeachers,
      ),
      DashboardRankingRow(
        title: 'Classes missing monthly assignments',
        detail: 'Classes with no assignment activity for the current month.',
        metricLabel: '$classesMissingAssignments classes',
        score: classesMissingAssignments,
      ),
      DashboardRankingRow(
        title: 'Classes with scoring backlog',
        detail: 'Classes with current-month score coverage below 65%.',
        metricLabel: '$classesWithLowCompletion classes',
        score: classesWithLowCompletion,
      ),
      DashboardRankingRow(
        title: 'Subjects without teacher coverage',
        detail: 'Subjects that have no teacher assignment yet.',
        metricLabel: '$subjectsWithoutCoverage subjects',
        score: subjectsWithoutCoverage,
      ),
    ];

    final scopeRows = [
      DashboardRankingRow(
        title: 'Viewer scope',
        detail: viewer.primaryScopeLabel ?? 'Global platform access',
        metricLabel: viewer.role.label,
        score: 0,
      ),
      DashboardRankingRow(
        title: 'Organizations represented',
        detail: organizations.isEmpty
            ? 'No organization scopes are present yet.'
            : organizations.take(3).join(' / '),
        metricLabel: '${organizations.length} organizations',
        score: organizations.length,
      ),
      DashboardRankingRow(
        title: 'Schools tracked locally',
        detail: local.schools.isEmpty
            ? 'No local schools have been created yet.'
            : '${local.classes.length} classes across ${local.schools.length} schools',
        metricLabel: '${local.schools.length} schools',
        score: local.schools.length,
      ),
    ];

    final actionItems = [
      DashboardActionItem(
        id: 'review_scope',
        title: 'Review scope mismatches',
        description: 'Start with accounts that are missing organization scope.',
        valueLabel: '$missingScopeProfiles accounts',
        isPrimary: true,
      ),
      DashboardActionItem(
        id: 'repair_teacher_links',
        title: 'Repair teacher mappings',
        description:
            'Resolve teacher profiles that cannot be matched to local teacher records.',
        valueLabel: '$orphanedTeacherProfiles profiles',
      ),
      DashboardActionItem(
        id: 'audit_inactive',
        title: 'Audit inactive access',
        description:
            'Confirm whether inactive admins and teachers should remain disabled.',
        valueLabel: '$inactiveAccounts inactive',
      ),
      DashboardActionItem(
        id: 'focus_school',
        title: 'Focus the riskiest school',
        description: schoolRows.isEmpty
            ? 'Create a school to begin cross-school governance.'
            : 'Begin with ${schoolRows.first.title} and its current issue queue.',
        valueLabel: schoolRows.isEmpty ? null : schoolRows.first.metricLabel,
        schoolId: schoolRows.isEmpty ? null : schoolRows.first.schoolId,
      ),
    ];

    final dataQualityAlerts = [
      if (classesMissingAssignments > 0)
        DashboardAlert(
          title: 'Assignment coverage gaps',
          message:
              '$classesMissingAssignments classes have no assignment activity for ${_currentMonthLabel()} ${DateTime.now().year}.',
          severity: DashboardAlertSeverity.warning,
          count: classesMissingAssignments,
        ),
      if (classesWithLowCompletion > 0)
        DashboardAlert(
          title: 'Gradebook backlog',
          message:
              '$classesWithLowCompletion classes are below 65% score completion for the current month.',
          severity: DashboardAlertSeverity.warning,
          count: classesWithLowCompletion,
        ),
      if (subjectsWithoutCoverage > 0)
        DashboardAlert(
          title: 'Uncovered subjects',
          message:
              '$subjectsWithoutCoverage subjects do not have a teacher assignment yet.',
          severity: DashboardAlertSeverity.warning,
          count: subjectsWithoutCoverage,
        ),
    ];

    final unresolvedIssueCount =
        platformAlerts.fold<int>(
          0,
          (total, alert) => total + (alert.count ?? 1),
        ) +
        dataQualityAlerts.fold<int>(
          0,
          (total, alert) => total + (alert.count ?? 1),
        );

    return SuperadminDashboardSummary(
      organizationCount: organizations.length,
      schoolCount: local.schools.length,
      activeAdminCount: activeAdmins,
      activeTeacherCount: activeTeachers,
      studentCount: local.students.length,
      inactiveAccountCount: inactiveAccounts,
      unresolvedIssueCount: unresolvedIssueCount,
      platformAlerts: platformAlerts,
      organizationWatchlist: schoolRows,
      accessRows: accessRows,
      globalTrendRows: globalTrendRows,
      actionItems: actionItems,
      dataQualityAlerts: dataQualityAlerts,
      scopeRows: scopeRows,
    );
  }

  Future<OrganizationAdminDashboardSummary> loadOrganizationAdminSummary(
    AppUserProfile viewer,
  ) async {
    final organizationId = viewer.organizationId?.trim();
    final profileFuture = _loadProfilesSafely();
    final profileResult = await profileFuture;

    if (organizationId == null || organizationId.isEmpty) {
      return OrganizationAdminDashboardSummary(
        scopeLabel: 'Unscoped admin access',
        classCount: 0,
        teacherCount: 0,
        studentCount: 0,
        adviserClassCount: 0,
        assignmentActivityCount: 0,
        attentionClassCount: 0,
        operationsAlerts: const [],
        classPriorityRows: const [],
        staffLoadRows: const [],
        rosterRows: const [],
        accessRows: const [],
        actionItems: const [
          DashboardActionItem(
            id: 'scope_required',
            title: 'Finish access scoping',
            description:
                'This admin account needs an `organizationId` before the dashboard can load organization operations safely.',
            valueLabel: 'Missing organizationId',
            isPrimary: true,
          ),
        ],
        accessAlerts: [
          const DashboardAlert(
            title: 'Missing organization scope',
            message:
                'This organization admin account is missing `organizationId`, so Trellis cannot safely scope organization data.',
            severity: DashboardAlertSeverity.critical,
            count: 1,
          ),
          if (profileResult.errorMessage != null)
            DashboardAlert(
              title: 'Access profiles unavailable',
              message: profileResult.errorMessage!,
              severity: DashboardAlertSeverity.warning,
            ),
        ],
      );
    }

    final localResult = await _loadLocalSnapshotSafely(
      organizationId: organizationId,
    );
    final local = localResult.snapshot;

    final classInsights = _buildClassInsights(
      classes: local.classes,
      subjects: local.subjects,
      assignments: local.assignments,
      scores: local.scores,
      students: local.students,
      teacherAssignments: local.teacherAssignments,
    );

    final classesWithoutTeachers = classInsights
        .where((insight) => !insight.hasTeacherCoverage)
        .length;
    final classesWithoutSubjects = classInsights
        .where((insight) => !insight.hasSubjects)
        .length;
    final underfilledRosters = classInsights
        .where((insight) => insight.isUnderfilled)
        .length;
    final classesMissingAssignments = classInsights
        .where((insight) => !insight.hasCurrentMonthAssignments)
        .length;
    final lowCompletionClasses = classInsights
        .where((insight) => insight.hasLowGradebookCoverage)
        .length;

    final classPriorityRows =
        classInsights
            .map((insight) {
              return DashboardRankingRow(
                title: insight.className,
                detail: insight.summaryLabel,
                metricLabel: insight.issueScore == 0
                    ? '${insight.completionPercentLabel} scored'
                    : '${insight.issueScore} issues',
                score: insight.issueScore,
                classId: insight.classId,
                isAdviser: insight.isAdviser,
              );
            })
            .toList(growable: false)
          ..sort((a, b) {
            final scoreCompare = b.score.compareTo(a.score);
            if (scoreCompare != 0) {
              return scoreCompare;
            }
            return a.title.compareTo(b.title);
          });

    final teacherAssignmentsByTeacher =
        <String, List<ClassTeacherSubjectModel>>{};
    for (final assignment in local.teacherAssignments) {
      teacherAssignmentsByTeacher.putIfAbsent(assignment.teacherId, () => []);
      teacherAssignmentsByTeacher[assignment.teacherId]!.add(assignment);
    }

    final staffLoadRows =
        local.teachers
            .map((teacher) {
              final teacherId = teacher.id;
              final assignments = teacherId == null
                  ? const <ClassTeacherSubjectModel>[]
                  : teacherAssignmentsByTeacher[teacherId] ??
                        const <ClassTeacherSubjectModel>[];
              final classIds = assignments.map((item) => item.classId).toSet();
              final subjectIds = assignments
                  .map((item) => item.subjectId)
                  .toSet();
              final loadScore = classIds.length + subjectIds.length;
              final label = loadScore >= 9
                  ? 'Heavy'
                  : loadScore >= 5
                  ? 'Balanced'
                  : 'Light';
              return DashboardRankingRow(
                title: teacher.name,
                detail:
                    '${classIds.length} classes / ${subjectIds.length} subjects assigned',
                metricLabel: '$label load',
                score: loadScore,
              );
            })
            .toList(growable: false)
          ..sort((a, b) {
            final scoreCompare = b.score.compareTo(a.score);
            if (scoreCompare != 0) {
              return scoreCompare;
            }
            return a.title.compareTo(b.title);
          });

    final rosterRows =
        local.classes
            .map((classModel) {
              final femaleShare = classModel.totalStudents == 0
                  ? 0
                  : ((classModel.femaleStudents / classModel.totalStudents) *
                            100)
                        .round();
              return DashboardRankingRow(
                title: classModel.name,
                detail:
                    '${classModel.totalStudents} students / $femaleShare% girls / ${classModel.academicYear}',
                metricLabel: classModel.totalStudents == 0
                    ? 'Empty roster'
                    : '${classModel.totalStudents} students',
                score: classModel.totalStudents,
                classId: classModel.id,
                isAdviser: classModel.isAdviser,
              );
            })
            .toList(growable: false)
          ..sort((a, b) {
            final scoreCompare = b.score.compareTo(a.score);
            if (scoreCompare != 0) {
              return scoreCompare;
            }
            return a.title.compareTo(b.title);
          });

    final scopedProfiles = profileResult.profiles
        .where((profile) {
          return (profile.organizationId?.trim() ?? '') == organizationId;
        })
        .toList(growable: false);

    final organizationTeacherIds = local.teachers
        .map((teacher) => teacher.id)
        .whereType<String>()
        .toSet();

    final activeScopedAdmins = scopedProfiles
        .where(
          (profile) =>
              profile.role == AppUserRole.organizationAdmin && profile.isActive,
        )
        .length;
    final activeScopedTeachers = scopedProfiles
        .where(
          (profile) => profile.role == AppUserRole.teacher && profile.isActive,
        )
        .length;
    final inactiveScopedAccounts = scopedProfiles
        .where((profile) => !profile.isActive)
        .length;
    final missingTeacherLinks = scopedProfiles.where((profile) {
      if (profile.role != AppUserRole.teacher) {
        return false;
      }
      final teacherId = profile.teacherId?.trim();
      return teacherId == null ||
          teacherId.isEmpty ||
          !organizationTeacherIds.contains(teacherId);
    }).length;

    final accessRows = [
      DashboardRankingRow(
        title: 'Scoped admins',
        detail: '$activeScopedAdmins active inside this organization scope.',
        metricLabel:
            '${scopedProfiles.where((profile) => profile.role == AppUserRole.organizationAdmin).length} admins',
        score: activeScopedAdmins,
      ),
      DashboardRankingRow(
        title: 'Teacher accounts',
        detail:
            '$activeScopedTeachers active teacher accounts are attached to this organization.',
        metricLabel:
            '${scopedProfiles.where((profile) => profile.role == AppUserRole.teacher).length} teachers',
        score: activeScopedTeachers,
      ),
      DashboardRankingRow(
        title: 'Inactive scoped accounts',
        detail: 'Accounts that may need reactivation or cleanup.',
        metricLabel: '$inactiveScopedAccounts inactive',
        score: inactiveScopedAccounts,
      ),
      DashboardRankingRow(
        title: 'Teacher links to repair',
        detail: 'Teacher accounts missing a valid local teacher mapping.',
        metricLabel: '$missingTeacherLinks profiles',
        score: missingTeacherLinks,
      ),
    ];

    final operationsAlerts = <DashboardAlert>[
      if (classesWithoutTeachers > 0)
        DashboardAlert(
          title: 'Classes without teacher coverage',
          message:
              '$classesWithoutTeachers classes still need at least one teacher assignment.',
          severity: DashboardAlertSeverity.critical,
          count: classesWithoutTeachers,
        ),
      if (classesWithoutSubjects > 0)
        DashboardAlert(
          title: 'Classes missing subjects',
          message:
              '$classesWithoutSubjects classes do not have subject structures yet.',
          severity: DashboardAlertSeverity.warning,
          count: classesWithoutSubjects,
        ),
      if (underfilledRosters > 0)
        DashboardAlert(
          title: 'Underfilled rosters',
          message:
              '$underfilledRosters classes have fewer than 10 students enrolled.',
          severity: DashboardAlertSeverity.warning,
          count: underfilledRosters,
        ),
      if (classesMissingAssignments > 0)
        DashboardAlert(
          title: 'Monthly assignment gaps',
          message:
              '$classesMissingAssignments classes have no assignments in ${_currentMonthLabel()} ${DateTime.now().year}.',
          severity: DashboardAlertSeverity.warning,
          count: classesMissingAssignments,
        ),
      if (lowCompletionClasses > 0)
        DashboardAlert(
          title: 'Scoring backlog',
          message:
              '$lowCompletionClasses classes are below 65% score completion for the current month.',
          severity: DashboardAlertSeverity.warning,
          count: lowCompletionClasses,
        ),
      if (local.teachers.isEmpty)
        const DashboardAlert(
          title: 'No teachers created yet',
          message:
              'Create teacher records before staffing and subject assignment workflows can work normally.',
          severity: DashboardAlertSeverity.critical,
          count: 1,
        ),
    ];

    final accessAlerts = <DashboardAlert>[
      if (profileResult.errorMessage != null)
        DashboardAlert(
          title: 'Access profiles unavailable',
          message: profileResult.errorMessage!,
          severity: DashboardAlertSeverity.warning,
        ),
      if (localResult.errorMessage != null)
        DashboardAlert(
          title: 'Operational snapshot unavailable',
          message: localResult.errorMessage!,
          severity: DashboardAlertSeverity.warning,
        ),
      if (missingTeacherLinks > 0)
        DashboardAlert(
          title: 'Teacher profile mismatches',
          message:
              '$missingTeacherLinks teacher accounts cannot be matched to a local teacher record in this organization.',
          severity: DashboardAlertSeverity.warning,
          count: missingTeacherLinks,
        ),
      if (_isBlank(viewer.organizationId))
        const DashboardAlert(
          title: 'Organization scope is missing',
          message:
              'This admin account does not have an organization identifier for cross-service alignment.',
          severity: DashboardAlertSeverity.warning,
          count: 1,
        ),
    ];

    final firstPriorityClass = classPriorityRows
        .cast<DashboardRankingRow?>()
        .firstWhere((row) => row?.classId != null, orElse: () => null);

    final actionItems = [
      DashboardActionItem(
        id: 'open_priority_class',
        title: 'Open priority class',
        description: firstPriorityClass == null
            ? 'Create classes to unlock operational drilldowns.'
            : 'Jump directly into ${firstPriorityClass.title} to resolve the highest-risk workflow.',
        valueLabel: firstPriorityClass?.metricLabel,
        classId: firstPriorityClass?.classId,
        isAdviser: firstPriorityClass?.isAdviser,
        isPrimary: true,
      ),
      DashboardActionItem(
        id: 'review_teacher_coverage',
        title: 'Review teacher coverage',
        description:
            'Focus on classes without teachers and subjects without ownership.',
        valueLabel: '$classesWithoutTeachers classes',
      ),
      DashboardActionItem(
        id: 'check_monthly_activity',
        title: 'Check monthly activity',
        description:
            'Confirm each class has fresh assignments and score entry movement.',
        valueLabel: '$classesMissingAssignments gaps',
      ),
      DashboardActionItem(
        id: 'audit_access',
        title: 'Audit access setup',
        description:
            'Resolve inactive accounts and broken teacher links in this organization scope.',
        valueLabel: '${inactiveScopedAccounts + missingTeacherLinks} issues',
      ),
    ];

    return OrganizationAdminDashboardSummary(
      scopeLabel: 'Organization: $organizationId',
      classCount: local.classes.length,
      teacherCount: local.teachers.length,
      studentCount: local.students.length,
      adviserClassCount: local.classes
          .where((classModel) => classModel.isAdviser)
          .length,
      assignmentActivityCount: local.assignments
          .where(_isCurrentMonthAssignment)
          .length,
      attentionClassCount: classInsights
          .where((insight) => insight.issueScore > 0)
          .length,
      operationsAlerts: operationsAlerts,
      classPriorityRows: classPriorityRows,
      staffLoadRows: staffLoadRows,
      rosterRows: rosterRows,
      accessRows: accessRows,
      actionItems: actionItems,
      accessAlerts: accessAlerts,
    );
  }

  Future<_ProfileLoadResult> _loadProfiles() async {
    try {
      final snapshot = await _firestore
          .collection(AuthService.userProfilesCollection)
          .get()
          .timeout(_firestoreReadTimeout);

      final profiles = <AppUserProfile>[];
      var invalidDocumentCount = 0;
      for (final document in snapshot.docs) {
        try {
          profiles.add(AppUserProfile.fromDocument(document));
        } catch (_) {
          invalidDocumentCount++;
        }
      }

      return _ProfileLoadResult(
        profiles: profiles,
        invalidDocumentCount: invalidDocumentCount,
      );
    } catch (error) {
      return _ProfileLoadResult(
        profiles: const [],
        errorMessage: 'Unable to query Firestore user profiles: $error',
      );
    }
  }

  Future<_ProfileLoadResult> _loadProfilesSafely() async {
    try {
      return await _loadProfiles();
    } on TimeoutException {
      return const _ProfileLoadResult(
        profiles: [],
        errorMessage:
            'Timed out while loading Firestore access profiles. Check hosted web Firebase connectivity and role claim propagation for this account.',
      );
    } catch (error) {
      return _ProfileLoadResult(
        profiles: const [],
        errorMessage: 'Unable to load Firestore access profiles: $error',
      );
    }
  }

  Future<_LocalDashboardSnapshot> _loadLocalSnapshot({
    String? schoolId,
    String? organizationId,
  }) async {
    late final List<SchoolModel> schools;
    late final List<Map<String, dynamic>> classRows;
    late final List<TeacherModel> teachers;

    if (schoolId != null && schoolId.isNotEmpty) {
      final results = await Future.wait<dynamic>([
        _loadSchools(schoolId: schoolId),
        _loadClassRows(schoolId: schoolId),
        _loadTeachers(schoolId: schoolId),
      ]);
      schools = results[0] as List<SchoolModel>;
      classRows = results[1] as List<Map<String, dynamic>>;
      teachers = results[2] as List<TeacherModel>;
    } else if (organizationId != null && organizationId.isNotEmpty) {
      schools = await _loadSchools(organizationId: organizationId);
      final schoolIds = schools
          .map((school) => school.id)
          .whereType<String>()
          .toList(growable: false);
      final results = await Future.wait<dynamic>([
        _loadClassRows(schoolIds: schoolIds),
        _loadTeachers(schoolIds: schoolIds),
      ]);
      classRows = results[0] as List<Map<String, dynamic>>;
      teachers = results[1] as List<TeacherModel>;
    } else {
      final results = await Future.wait<dynamic>([
        _loadSchools(),
        _loadClassRows(),
        _loadTeachers(),
      ]);
      schools = results[0] as List<SchoolModel>;
      classRows = results[1] as List<Map<String, dynamic>>;
      teachers = results[2] as List<TeacherModel>;
    }
    final classIds = classRows
        .map((row) => row['id']?.toString() ?? '')
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

    final relatedResults = await Future.wait<dynamic>([
      _loadStudents(classIds: classIds),
      _loadSubjects(classIds: classIds),
      _loadAssignments(classIds: classIds),
      _loadTeacherAssignments(classIds: classIds),
    ]);

    final students = relatedResults[0] as List<StudentModel>;
    final subjects = relatedResults[1] as List<SubjectModel>;
    final assignments = relatedResults[2] as List<AssignmentModel>;
    final teacherAssignments =
        relatedResults[3] as List<ClassTeacherSubjectModel>;
    final assignmentIds = assignments
        .map((assignment) => assignment.id)
        .whereType<String>()
        .toList(growable: false);
    final scores = await _loadScores(assignmentIds: assignmentIds);
    final classes = _mapClassesWithStudentStats(classRows, students);

    return _LocalDashboardSnapshot(
      schools: schools,
      classes: classes,
      teachers: teachers,
      students: students,
      subjects: subjects,
      assignments: assignments,
      scores: scores,
      teacherAssignments: teacherAssignments,
    );
  }

  Future<_LocalSnapshotLoadResult> _loadLocalSnapshotSafely({
    String? schoolId,
    String? organizationId,
  }) async {
    final timeout = kIsWeb ? _webLocalSnapshotTimeout : _localSnapshotTimeout;

    try {
      final snapshot = await _loadLocalSnapshot(
        schoolId: schoolId,
        organizationId: organizationId,
      ).timeout(timeout);
      return _LocalSnapshotLoadResult(snapshot: snapshot);
    } on TimeoutException {
      return _LocalSnapshotLoadResult(
        snapshot: _LocalDashboardSnapshot.empty,
        errorMessage: kIsWeb
            ? 'Firestore operational data took too long to respond on web, so Trellis continued without live school, class, and roster metrics.'
            : 'Firestore operational data took too long to load, so Trellis continued without live school, class, and roster metrics.',
      );
    } catch (error) {
      return _LocalSnapshotLoadResult(
        snapshot: _LocalDashboardSnapshot.empty,
        errorMessage: kIsWeb
            ? 'Firestore operational data is unavailable on web right now: $error'
            : 'Firestore operational data is unavailable right now: $error',
      );
    }
  }

  Future<List<SchoolModel>> _loadSchools({
    String? schoolId,
    String? organizationId,
  }) async {
    late final List<Map<String, dynamic>> rows;
    if (schoolId != null && schoolId.isNotEmpty) {
      rows = await _operationalStore.queryByIds(
        collectionName: OperationalFirestoreService.schoolsCollection,
        ids: [schoolId],
      );
    } else if (organizationId != null && organizationId.isNotEmpty) {
      rows = await _operationalStore.queryByField(
        collectionName: OperationalFirestoreService.schoolsCollection,
        field: 'organization_id',
        isEqualTo: organizationId,
      );
    } else {
      rows = await _operationalStore.getAllDocuments(
        collectionName: OperationalFirestoreService.schoolsCollection,
      );
    }

    final schools = rows
        .map((row) => SchoolModel.fromDto(row, row['id'].toString()))
        .toList();
    KhmerCollator.sortBy(schools, (school) => school.name);
    return schools;
  }

  Future<List<Map<String, dynamic>>> _loadClassRows({
    String? schoolId,
    List<String>? schoolIds,
  }) async {
    if (schoolId != null && schoolId.isNotEmpty) {
      return _operationalStore.queryByField(
        collectionName: OperationalFirestoreService.classesCollection,
        field: 'school_id',
        isEqualTo: schoolId,
      );
    }
    if (schoolIds != null) {
      return _operationalStore.queryByFieldIn(
        collectionName: OperationalFirestoreService.classesCollection,
        field: 'school_id',
        values: schoolIds,
      );
    }
    return _operationalStore.getAllDocuments(
      collectionName: OperationalFirestoreService.classesCollection,
    );
  }

  Future<List<TeacherModel>> _loadTeachers({
    String? schoolId,
    List<String>? schoolIds,
  }) async {
    late final List<Map<String, dynamic>> rows;
    if (schoolId != null && schoolId.isNotEmpty) {
      rows = await _operationalStore.queryByField(
        collectionName: OperationalFirestoreService.teachersCollection,
        field: 'school_id',
        isEqualTo: schoolId,
      );
    } else if (schoolIds != null) {
      rows = await _operationalStore.queryByFieldIn(
        collectionName: OperationalFirestoreService.teachersCollection,
        field: 'school_id',
        values: schoolIds,
      );
    } else {
      rows = await _operationalStore.getAllDocuments(
        collectionName: OperationalFirestoreService.teachersCollection,
      );
    }

    final teachers = rows
        .map((row) => TeacherModel.fromDto(row, row['id'].toString()))
        .toList();
    KhmerCollator.sortBy(teachers, (teacher) => teacher.name);
    return teachers;
  }

  Future<List<StudentModel>> _loadStudents({
    required List<String> classIds,
  }) async {
    final rows = await _operationalStore.queryByFieldIn(
      collectionName: OperationalFirestoreService.studentsCollection,
      field: 'class_id',
      values: classIds,
    );
    return rows
        .map((row) => StudentModel.fromDto(row, row['id'].toString()))
        .toList();
  }

  Future<List<SubjectModel>> _loadSubjects({
    required List<String> classIds,
  }) async {
    final rows = await _operationalStore.queryByFieldIn(
      collectionName: OperationalFirestoreService.subjectsCollection,
      field: 'class_id',
      values: classIds,
    );
    final subjects = rows
        .map((row) => SubjectModel.fromDto(row, row['id'].toString()))
        .toList(growable: false);
    subjects.sort((a, b) {
      final orderCompare = (a.displayOrder ?? 0).compareTo(b.displayOrder ?? 0);
      if (orderCompare != 0) {
        return orderCompare;
      }
      return (a.id ?? '').compareTo(b.id ?? '');
    });
    return subjects;
  }

  Future<List<AssignmentModel>> _loadAssignments({
    required List<String> classIds,
  }) async {
    final rows = await _operationalStore.queryByFieldIn(
      collectionName: OperationalFirestoreService.assignmentsCollection,
      field: 'class_id',
      values: classIds,
    );
    final assignments = rows
        .map((row) => AssignmentModel.fromDto(row, row['id'].toString()))
        .toList(growable: false);
    assignments.sort((a, b) {
      final yearCompare = b.year.compareTo(a.year);
      if (yearCompare != 0) {
        return yearCompare;
      }
      return b.month.compareTo(a.month);
    });
    return assignments;
  }

  Future<List<ScoreModel>> _loadScores({
    required List<String> assignmentIds,
  }) async {
    final rows = await _operationalStore.queryByFieldIn(
      collectionName: OperationalFirestoreService.scoresCollection,
      field: 'assignment_id',
      values: assignmentIds,
    );
    return rows
        .map((row) => ScoreModel.fromDto(row, row['id'].toString()))
        .toList();
  }

  Future<List<ClassTeacherSubjectModel>> _loadTeacherAssignments({
    required List<String> classIds,
  }) async {
    final rows = await _operationalStore.queryByFieldIn(
      collectionName:
          OperationalFirestoreService.classTeacherSubjectsCollection,
      field: 'class_id',
      values: classIds,
    );
    return rows
        .map(
          (row) => ClassTeacherSubjectModel.fromDto(row, row['id'].toString()),
        )
        .toList();
  }

  List<ClassModel> _mapClassesWithStudentStats(
    List<Map<String, dynamic>> rows,
    List<StudentModel> students,
  ) {
    final totalByClassId = <String, int>{};
    final femaleByClassId = <String, int>{};
    for (final student in students) {
      totalByClassId[student.classId] =
          (totalByClassId[student.classId] ?? 0) + 1;
      if ((student.sex ?? '').trim().toUpperCase() == 'F') {
        femaleByClassId[student.classId] =
            (femaleByClassId[student.classId] ?? 0) + 1;
      }
    }

    final classes = rows
        .map((row) {
          final classId = row['id'].toString();
          return ClassModel.fromDto({
            ...row,
            'total_students': totalByClassId[classId] ?? 0,
            'female_students': femaleByClassId[classId] ?? 0,
          }, classId);
        })
        .toList(growable: false);
    KhmerCollator.sortBy(classes, (classModel) => classModel.name);
    return classes;
  }

  List<_ClassInsight> _buildClassInsights({
    required List<ClassModel> classes,
    required List<SubjectModel> subjects,
    required List<AssignmentModel> assignments,
    required List<ScoreModel> scores,
    required List<StudentModel> students,
    required List<ClassTeacherSubjectModel> teacherAssignments,
  }) {
    final subjectsByClassId = <String, List<SubjectModel>>{};
    for (final subject in subjects) {
      subjectsByClassId.putIfAbsent(subject.classId, () => []);
      subjectsByClassId[subject.classId]!.add(subject);
    }

    final assignmentsByClassId = <String, List<AssignmentModel>>{};
    for (final assignment in assignments) {
      assignmentsByClassId.putIfAbsent(assignment.classId, () => []);
      assignmentsByClassId[assignment.classId]!.add(assignment);
    }

    final scoresByAssignmentId = <String, List<ScoreModel>>{};
    for (final score in scores) {
      scoresByAssignmentId.putIfAbsent(score.assignmentId, () => []);
      scoresByAssignmentId[score.assignmentId]!.add(score);
    }

    final studentsByClassId = <String, List<StudentModel>>{};
    for (final student in students) {
      studentsByClassId.putIfAbsent(student.classId, () => []);
      studentsByClassId[student.classId]!.add(student);
    }

    final teacherAssignmentsByClassId =
        <String, List<ClassTeacherSubjectModel>>{};
    for (final assignment in teacherAssignments) {
      teacherAssignmentsByClassId.putIfAbsent(assignment.classId, () => []);
      teacherAssignmentsByClassId[assignment.classId]!.add(assignment);
    }

    final currentYear = DateTime.now().year.toString();
    final currentMonth = kMonths[DateTime.now().month - 1];

    return classes
        .map((classModel) {
          final classId = classModel.id ?? '';
          final classSubjects =
              subjectsByClassId[classId] ?? const <SubjectModel>[];
          final classAssignments =
              assignmentsByClassId[classId] ?? const <AssignmentModel>[];
          final classTeacherAssignments =
              teacherAssignmentsByClassId[classId] ??
              const <ClassTeacherSubjectModel>[];
          final currentAssignments = classAssignments
              .where(
                (assignment) =>
                    assignment.year == currentYear &&
                    assignment.month == currentMonth,
              )
              .toList(growable: false);
          final rosterSize =
              studentsByClassId[classId]?.length ?? classModel.totalStudents;

          var actualScoreCount = 0;
          for (final assignment in currentAssignments) {
            final assignmentId = assignment.id;
            if (assignmentId == null) {
              continue;
            }
            actualScoreCount += scoresByAssignmentId[assignmentId]?.length ?? 0;
          }

          final expectedScoreCount = currentAssignments.length * rosterSize;
          final completionPercent = expectedScoreCount == 0
              ? 0
              : ((actualScoreCount / expectedScoreCount) * 100).round();

          var issueScore = 0;
          final concerns = <String>[];
          if (classTeacherAssignments.isEmpty) {
            issueScore += 2;
            concerns.add('no teacher coverage');
          }
          if (classSubjects.isEmpty) {
            issueScore += 2;
            concerns.add('no subjects');
          }
          if (currentAssignments.isEmpty) {
            issueScore += 2;
            concerns.add('no monthly assignments');
          }
          if (rosterSize < 10) {
            issueScore += 1;
            concerns.add(
              rosterSize == 0 ? 'empty roster' : 'underfilled roster',
            );
          }
          if (expectedScoreCount > 0 && completionPercent < 65) {
            issueScore += 1;
            concerns.add('$completionPercent% scored');
          }

          return _ClassInsight(
            classId: classId,
            className: classModel.name,
            isAdviser: classModel.isAdviser,
            issueScore: issueScore,
            hasTeacherCoverage: classTeacherAssignments.isNotEmpty,
            hasSubjects: classSubjects.isNotEmpty,
            hasCurrentMonthAssignments: currentAssignments.isNotEmpty,
            hasLowGradebookCoverage:
                expectedScoreCount > 0 && completionPercent < 65,
            isUnderfilled: rosterSize < 10,
            completionPercent: completionPercent,
            summaryLabel: concerns.isEmpty
                ? 'Teacher coverage, subjects, and current-month scoring are healthy.'
                : concerns.join(' / '),
          );
        })
        .toList(growable: false);
  }

  int _countRole(List<AppUserProfile> profiles, AppUserRole role) {
    return profiles.where((profile) => profile.role == role).length;
  }

  int _countInactive(List<AppUserProfile> profiles, AppUserRole role) {
    return profiles
        .where((profile) => profile.role == role && !profile.isActive)
        .length;
  }

  bool _isCurrentMonthAssignment(AssignmentModel assignment) {
    return assignment.year == DateTime.now().year.toString() &&
        assignment.month == kMonths[DateTime.now().month - 1];
  }

  String _currentMonthLabel() {
    return kMonths[DateTime.now().month - 1];
  }
}

class _ProfileLoadResult {
  const _ProfileLoadResult({
    required this.profiles,
    this.invalidDocumentCount = 0,
    this.errorMessage,
  });

  final List<AppUserProfile> profiles;
  final int invalidDocumentCount;
  final String? errorMessage;
}

class _LocalDashboardSnapshot {
  const _LocalDashboardSnapshot({
    required this.schools,
    required this.classes,
    required this.teachers,
    required this.students,
    required this.subjects,
    required this.assignments,
    required this.scores,
    required this.teacherAssignments,
  });

  static const empty = _LocalDashboardSnapshot(
    schools: [],
    classes: [],
    teachers: [],
    students: [],
    subjects: [],
    assignments: [],
    scores: [],
    teacherAssignments: [],
  );

  final List<SchoolModel> schools;
  final List<ClassModel> classes;
  final List<TeacherModel> teachers;
  final List<StudentModel> students;
  final List<SubjectModel> subjects;
  final List<AssignmentModel> assignments;
  final List<ScoreModel> scores;
  final List<ClassTeacherSubjectModel> teacherAssignments;
}

class _LocalSnapshotLoadResult {
  const _LocalSnapshotLoadResult({required this.snapshot, this.errorMessage});

  final _LocalDashboardSnapshot snapshot;
  final String? errorMessage;
}

class _ClassInsight {
  const _ClassInsight({
    required this.classId,
    required this.className,
    required this.isAdviser,
    required this.issueScore,
    required this.hasTeacherCoverage,
    required this.hasSubjects,
    required this.hasCurrentMonthAssignments,
    required this.hasLowGradebookCoverage,
    required this.isUnderfilled,
    required this.completionPercent,
    required this.summaryLabel,
  });

  final String classId;
  final String className;
  final bool isAdviser;
  final int issueScore;
  final bool hasTeacherCoverage;
  final bool hasSubjects;
  final bool hasCurrentMonthAssignments;
  final bool hasLowGradebookCoverage;
  final bool isUnderfilled;
  final int completionPercent;
  final String summaryLabel;

  String get completionPercentLabel => '$completionPercent%';
}

bool _isBlank(String? value) => value == null || value.trim().isEmpty;
