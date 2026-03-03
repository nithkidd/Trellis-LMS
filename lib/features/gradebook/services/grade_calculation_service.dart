import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../students/models/student_model.dart';
import '../../subjects/models/subject_model.dart';
import '../../assignments/models/assignment_model.dart';

import '../../students/providers/student_provider.dart';
import '../../subjects/providers/subject_provider.dart';
import '../../assignments/providers/assignment_provider.dart';
import '../providers/score_provider.dart';

/// Represents a single assignment and the score a specific student has for it.
class AssignmentScoreEntry {
  final AssignmentModel assignment;
  final double? currentScore; // null = not yet graded

  const AssignmentScoreEntry({required this.assignment, this.currentScore});
}

class SubjectTeacherRow {
  final StudentModel student;
  final Map<String, double> monthlyPercentages; // 'Jan': 85.0
  final Map<String, double>
  monthlyRawScores; // 'Jan': 42.0 (total points earned)
  // 'Jan': [AssignmentScoreEntry, ...] – allows per-assignment grade editing
  final Map<String, List<AssignmentScoreEntry>> monthlyEntries;
  final double sem1Average;
  final double sem2Average;
  final double yearlyAverage;
  // Override entries – non-null when teacher manually set the semester/yearly score.
  // month tags: 'SEM1', 'SEM2', 'YEARLY'
  final AssignmentScoreEntry? sem1OverrideEntry;
  final AssignmentScoreEntry? sem2OverrideEntry;
  final AssignmentScoreEntry? yearlyOverrideEntry;

  SubjectTeacherRow({
    required this.student,
    required this.monthlyPercentages,
    required this.monthlyRawScores,
    required this.monthlyEntries,
    required this.sem1Average,
    required this.sem2Average,
    required this.yearlyAverage,
    this.sem1OverrideEntry,
    this.sem2OverrideEntry,
    this.yearlyOverrideEntry,
  });
}

class ClassAdviserRow {
  final StudentModel student;
  final Map<int, double> subjectYearlyAverages;
  final double overallPercentage;
  final String grade;
  final int rank;

  ClassAdviserRow({
    required this.student,
    required this.subjectYearlyAverages,
    required this.overallPercentage,
    required this.grade,
    required this.rank,
  });
}

class GradeCalculationData {
  final List<SubjectModel> subjects;
  final List<ClassAdviserRow> adviserRows;
  // Map of subjectId to Teacher rows
  final Map<int, List<SubjectTeacherRow>> subjectTeacherRows;

  GradeCalculationData({
    required this.subjects,
    required this.adviserRows,
    required this.subjectTeacherRows,
  });
}

final gradeCalculationProvider = FutureProvider.family<GradeCalculationData, int>(
  (ref, classId) async {
    // Subscribe to dependencies so it auto-recalculates
    final studentsState = ref.watch(studentNotifierProvider);
    final subjectsState = ref.watch(subjectNotifierProvider);
    final assignmentsState = ref.watch(assignmentNotifierProvider);
    ref.watch(scoreNotifierProvider); // re-trigger on score change

    if (studentsState is! AsyncData ||
        subjectsState is! AsyncData ||
        assignmentsState is! AsyncData) {
      throw Exception('Loading dependencies...');
    }

    final students = studentsState.value ?? [];
    final subjects = subjectsState.value ?? [];
    final assignments = assignmentsState.value ?? [];

    final scoreRepo = ref.read(scoreRepositoryProvider);
    final allScores = await scoreRepo.getScoresByClassId(classId);

    // Group scores by assignmentId for quick lookup
    final Map<int, Map<int, double>> scoresByAssignmentAndStudent = {};
    for (var score in allScores) {
      if (!scoresByAssignmentAndStudent.containsKey(score.assignmentId)) {
        scoresByAssignmentAndStudent[score.assignmentId] = {};
      }
      scoresByAssignmentAndStudent[score.assignmentId]![score.studentId] =
          score.pointsEarned;
    }

    // 1. Calculate Subject Teacher Rows
    Map<int, List<SubjectTeacherRow>> subjectTeacherRows = {};
    Map<int, Map<int, double>> studentToSubjectYearlyAverage =
        {}; // studentId -> {subjectId -> yearlyAverage}

    final sem1Months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
    final sem2Months = ['Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    for (var subject in subjects) {
      List<SubjectTeacherRow> rows = [];
      final subjectAssignments = assignments
          .where((a) => a.subjectId == subject.id)
          .toList();

      for (var student in students) {
        studentToSubjectYearlyAverage.putIfAbsent(student.id!, () => {});

        Map<String, double> monthlyPercentages = {};
        Map<String, double> monthlyRawScores = {};
        Map<String, List<AssignmentScoreEntry>> monthlyEntries = {};

        double sem1Earned = 0, sem1Max = 0;
        double sem2Earned = 0, sem2Max = 0;

        // Compute raw aggregations per month first.
        // Special month tags 'SEM1', 'SEM2', 'YEARLY' are treated as overrides
        // and excluded from the regular monthly grid.
        const overrideMonths = {'SEM1', 'SEM2', 'YEARLY'};
        Map<String, double> monthlyMaxMap = {};

        AssignmentScoreEntry? sem1OverrideEntry;
        AssignmentScoreEntry? sem2OverrideEntry;
        AssignmentScoreEntry? yearlyOverrideEntry;

        for (var assignment in subjectAssignments) {
          final pointsEarned =
              scoresByAssignmentAndStudent[assignment.id!]?[student.id];

          // Handle override assignments (SEM1 / SEM2 / YEARLY)
          if (overrideMonths.contains(assignment.month)) {
            final entry = AssignmentScoreEntry(
              assignment: assignment,
              currentScore: pointsEarned,
            );
            if (assignment.month == 'SEM1') sem1OverrideEntry = entry;
            if (assignment.month == 'SEM2') sem2OverrideEntry = entry;
            if (assignment.month == 'YEARLY') yearlyOverrideEntry = entry;
            continue; // skip from regular month grid
          }

          // Build per-assignment entry for the monthly grid dialog
          monthlyEntries.putIfAbsent(assignment.month, () => []);
          monthlyEntries[assignment.month]!.add(
            AssignmentScoreEntry(
              assignment: assignment,
              currentScore: pointsEarned,
            ),
          );

          if (pointsEarned != null) {
            monthlyRawScores[assignment.month] =
                (monthlyRawScores[assignment.month] ?? 0) + pointsEarned;
            monthlyMaxMap[assignment.month] =
                (monthlyMaxMap[assignment.month] ?? 0) + assignment.maxPoints;
            if (sem1Months.contains(assignment.month)) {
              sem1Earned += pointsEarned;
              sem1Max += assignment.maxPoints;
            } else if (sem2Months.contains(assignment.month)) {
              sem2Earned += pointsEarned;
              sem2Max += assignment.maxPoints;
            }
          } else {
            monthlyMaxMap[assignment.month] =
                (monthlyMaxMap[assignment.month] ?? 0) + assignment.maxPoints;
            if (sem1Months.contains(assignment.month)) {
              sem1Max += assignment.maxPoints;
            } else if (sem2Months.contains(assignment.month)) {
              sem2Max += assignment.maxPoints;
            }
          }
        }

        // Compute monthly percentages
        monthlyRawScores.forEach((month, earned) {
          final max = monthlyMaxMap[month] ?? 0;
          if (max > 0) monthlyPercentages[month] = (earned / max) * 100;
        });

        // Base calculated averages
        double sem1Avg = sem1Max > 0 ? (sem1Earned / sem1Max) * 100 : 0.0;
        double sem2Avg = sem2Max > 0 ? (sem2Earned / sem2Max) * 100 : 0.0;
        double totalMax = sem1Max + sem2Max;
        double totalEarned = sem1Earned + sem2Earned;
        double yearlyAvg = totalMax > 0 ? (totalEarned / totalMax) * 100 : 0.0;

        // Apply overrides when the teacher manually set a semester/yearly score
        if (sem1OverrideEntry?.currentScore != null) {
          final e = sem1OverrideEntry!;
          sem1Avg = (e.currentScore! / e.assignment.maxPoints) * 100;
        }
        if (sem2OverrideEntry?.currentScore != null) {
          final e = sem2OverrideEntry!;
          sem2Avg = (e.currentScore! / e.assignment.maxPoints) * 100;
        }
        if (yearlyOverrideEntry?.currentScore != null) {
          final e = yearlyOverrideEntry!;
          yearlyAvg = (e.currentScore! / e.assignment.maxPoints) * 100;
        }

        studentToSubjectYearlyAverage[student.id!]![subject.id!] = yearlyAvg;

        rows.add(
          SubjectTeacherRow(
            student: student,
            monthlyPercentages: monthlyPercentages,
            monthlyRawScores: monthlyRawScores,
            monthlyEntries: monthlyEntries,
            sem1Average: sem1Avg,
            sem2Average: sem2Avg,
            yearlyAverage: yearlyAvg,
            sem1OverrideEntry: sem1OverrideEntry,
            sem2OverrideEntry: sem2OverrideEntry,
            yearlyOverrideEntry: yearlyOverrideEntry,
          ),
        );
      }
      subjectTeacherRows[subject.id!] = rows;
    }

    // 2. Calculate Class Adviser Rows
    List<ClassAdviserRow> unrankedAdviserRows = [];

    for (var student in students) {
      final subjectAverages = studentToSubjectYearlyAverage[student.id!] ?? {};

      double totalPercentages = 0;
      int subjectsCount = 0;

      subjectAverages.forEach((_, avg) {
        if (avg > 0) {
          // Or maybe just include all subjects if we require them
          totalPercentages += avg;
          subjectsCount++;
        }
      });

      double overall = subjectsCount > 0
          ? totalPercentages / subjectsCount
          : 0.0;

      String grade;
      if (overall >= 90) {
        grade = 'A';
      } else if (overall >= 80) {
        grade = 'B';
      } else if (overall >= 70) {
        grade = 'C';
      } else if (overall >= 60) {
        grade = 'D';
      } else if (overall > 0) {
        grade = 'F';
      } else {
        grade = '-';
      }

      unrankedAdviserRows.add(
        ClassAdviserRow(
          student: student,
          subjectYearlyAverages: subjectAverages,
          overallPercentage: overall,
          grade: grade,
          rank: 0, // placeholder
        ),
      );
    }

    // 3. Assign Ranks
    // Sort by overall descending
    unrankedAdviserRows.sort(
      (a, b) => b.overallPercentage.compareTo(a.overallPercentage),
    );

    List<ClassAdviserRow> rankedRows = [];
    int currentRank = 1;
    for (int i = 0; i < unrankedAdviserRows.length; i++) {
      if (i > 0 &&
          unrankedAdviserRows[i].overallPercentage <
              unrankedAdviserRows[i - 1].overallPercentage) {
        currentRank = i + 1;
      }
      // if equals, currentRank remains the same (e.g. 1, 1, 3)

      // Only assign actual rank if they have a non-zero overall
      final r = unrankedAdviserRows[i].overallPercentage > 0 ? currentRank : 0;

      rankedRows.add(
        ClassAdviserRow(
          student: unrankedAdviserRows[i].student,
          subjectYearlyAverages: unrankedAdviserRows[i].subjectYearlyAverages,
          overallPercentage: unrankedAdviserRows[i].overallPercentage,
          grade: unrankedAdviserRows[i].grade,
          rank: r,
        ),
      );
    }

    return GradeCalculationData(
      subjects: subjects,
      adviserRows: rankedRows,
      subjectTeacherRows: subjectTeacherRows,
    );
  },
);
