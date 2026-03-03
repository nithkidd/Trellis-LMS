import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/grade_calculation_service.dart';
import '../providers/score_provider.dart';
import '../providers/gradebook_permission_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../students/providers/student_provider.dart';
import '../../assignments/models/assignment_model.dart';
import '../../assignments/providers/assignment_provider.dart';
import '../models/score_model.dart';

enum GradebookViewMode { classAdviser, subjectTeacher }

const Map<String, String> kMonthLabels = {
  'Jan': 'មករា',
  'Feb': 'កុម្ភៈ',
  'Mar': 'មីនា',
  'Apr': 'មេសា',
  'May': 'ឧសភា',
  'Jun': 'មិថុនា',
  'Jul': 'កក្កដា',
  'Aug': 'សីហា',
  'Sep': 'កញ្ញា',
  'Oct': 'តុលា',
  'Nov': 'វិច្ឆិកា',
  'Dec': 'ធ្នូ',
};

class GradebookMainTabWidget extends ConsumerStatefulWidget {
  final int classId;
  final int? teacherId; // null = admin, non-null = teacher view
  final bool isAdviser;

  const GradebookMainTabWidget({
    super.key,
    required this.classId,
    this.teacherId,
    this.isAdviser = false,
  });

  @override
  ConsumerState<GradebookMainTabWidget> createState() =>
      _GradebookMainTabWidgetState();
}

class _GradebookMainTabWidgetState
    extends ConsumerState<GradebookMainTabWidget> {
  late GradebookViewMode _viewMode;
  int? _selectedSubjectId;

  bool get _canAccessAdviserView => widget.isAdviser;

  @override
  void initState() {
    super.initState();
    // Only advisers can access class adviser view.
    _viewMode = _canAccessAdviserView
        ? GradebookViewMode.classAdviser
        : GradebookViewMode.subjectTeacher;
  }

  @override
  Widget build(BuildContext context) {
    final gradeDataState = ref.watch(gradeCalculationProvider(widget.classId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: gradeDataState.when(
        data: (data) {
          if (data.subjects.isEmpty) {
            return Center(
              child: Text(
                'សូមបន្ថែមមុខវិជ្ជាយ៉ាងតិចមួយនៅផ្ទាំងមុខវិជ្ជា\nដើម្បីមើលតារាងពិន្ទុ។',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }

          if (_viewMode == GradebookViewMode.subjectTeacher &&
              _selectedSubjectId == null) {
            _selectedSubjectId = data.subjects.first.id;
          }

          // Safety guard: never allow non-advisers to remain in adviser mode.
          if (!_canAccessAdviserView &&
              _viewMode == GradebookViewMode.classAdviser) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _viewMode = GradebookViewMode.subjectTeacher;
                });
              }
            });
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildControlPanel(data),
              Expanded(
                child: _viewMode == GradebookViewMode.classAdviser
                    ? _buildClassAdviserView(data)
                    : _buildSubjectTeacherView(data),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Text('កំហុស៖ $err', style: TextStyle(color: AppColors.danger)),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  //  Control Panel
  // ---------------------------------------------------------------------------

  Widget _buildControlPanel(GradeCalculationData data) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 800;

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: isSmallScreen
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Only advisers can switch to class adviser view.
                if (_canAccessAdviserView) ...[
                  const Text(
                    'របៀបបង្ហាញ៖',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSizes.paddingSm),
                  DropdownButton<GradebookViewMode>(
                    value: _viewMode,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: GradebookViewMode.classAdviser,
                        child: Text('គ្រូបន្ទុកថ្នាក់'),
                      ),
                      DropdownMenuItem(
                        value: GradebookViewMode.subjectTeacher,
                        child: Text('គ្រូមុខវិជ្ជា'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _viewMode = val);
                    },
                  ),
                ] else ...[
                  // Non-adviser teachers see a static label
                  const Text(
                    'តារាងពិន្ទុ - មុខវិជ្ជារបស់អ្នក',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
                if (_viewMode == GradebookViewMode.subjectTeacher) ...[
                  const SizedBox(height: AppSizes.paddingMd),
                  const Text(
                    'មុខវិជ្ជា៖',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSizes.paddingSm),
                  // Filter subjects based on teacher permissions
                  Builder(
                    builder: (context) {
                      // Get visible subjects for this teacher
                      final visibleSubjectsAsync = ref.watch(
                        gradebookVisibleSubjectsProvider((
                          data.subjects,
                          widget.classId,
                          widget.teacherId,
                          widget.isAdviser,
                        )),
                      );

                      return visibleSubjectsAsync.when(
                        data: (visibleSubjects) {
                          // Ensure selected subject is valid
                          if (_selectedSubjectId == null ||
                              !visibleSubjects.any(
                                (s) => s.id == _selectedSubjectId,
                              )) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (visibleSubjects.isNotEmpty) {
                                setState(
                                  () => _selectedSubjectId =
                                      visibleSubjects.first.id,
                                );
                              }
                            });
                          }

                          return DropdownButton<int>(
                            value: _selectedSubjectId,
                            underline: const SizedBox(),
                            items: visibleSubjects
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s.id,
                                    child: Text(s.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedSubjectId = val);
                              }
                            },
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (err, st) => Text('Error: $err'),
                      );
                    },
                  ),
                ],
              ],
            )
          : Row(
              children: [
                // Only advisers can switch to class adviser view.
                if (_canAccessAdviserView) ...[
                  const Text(
                    'របៀបបង្ហាញ៖',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: AppSizes.paddingSm),
                  DropdownButton<GradebookViewMode>(
                    value: _viewMode,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: GradebookViewMode.classAdviser,
                        child: Text('គ្រូបន្ទុកថ្នាក់'),
                      ),
                      DropdownMenuItem(
                        value: GradebookViewMode.subjectTeacher,
                        child: Text('គ្រូមុខវិជ្ជា'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _viewMode = val);
                    },
                  ),
                ] else ...[
                  // Non-adviser teachers see a static label
                  const Text(
                    'តារាងពិន្ទុ - មុខវិជ្ជារបស់អ្នក',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
                if (_viewMode == GradebookViewMode.subjectTeacher) ...[
                  const SizedBox(width: AppSizes.paddingLg),
                  const Text(
                    'មុខវិជ្ជា៖',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: AppSizes.paddingSm),
                  // Filter subjects based on teacher permissions
                  Builder(
                    builder: (context) {
                      // Get visible subjects for this teacher
                      final visibleSubjectsAsync = ref.watch(
                        gradebookVisibleSubjectsProvider((
                          data.subjects,
                          widget.classId,
                          widget.teacherId,
                          widget.isAdviser,
                        )),
                      );

                      return visibleSubjectsAsync.when(
                        data: (visibleSubjects) {
                          // Ensure selected subject is valid
                          if (_selectedSubjectId == null ||
                              !visibleSubjects.any(
                                (s) => s.id == _selectedSubjectId,
                              )) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (visibleSubjects.isNotEmpty) {
                                setState(
                                  () => _selectedSubjectId =
                                      visibleSubjects.first.id,
                                );
                              }
                            });
                          }

                          return DropdownButton<int>(
                            value: _selectedSubjectId,
                            underline: const SizedBox(),
                            items: visibleSubjects
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s.id,
                                    child: Text(s.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedSubjectId = val);
                              }
                            },
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (err, st) => Text('Error: $err'),
                      );
                    },
                  ),
                ],
              ],
            ),
    );
  }

  // ---------------------------------------------------------------------------
  //  Class Adviser View
  // ---------------------------------------------------------------------------

  Widget _buildClassAdviserView(GradeCalculationData data) {
    if (data.adviserRows.isEmpty) {
      return const Center(child: Text('មិនមានសិស្សក្នុងថ្នាក់នេះ។'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width,
        ),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
          columnSpacing: 8,
          horizontalMargin: 8,
          columns: [
            const DataColumn(
              label: Text('ល.រ', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const DataColumn(
              label: Text(
                'នាម និង គោត្តនាម',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ...data.subjects.map(
              (s) => DataColumn(
                label: Text(
                  s.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const DataColumn(
              label: Text(
                'ពិន្ទុសរុប',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const DataColumn(
              label: Text(
                'មធ្យមភាគ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const DataColumn(
              label: Text(
                'ចំណាត់ថ្នាក់',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const DataColumn(
              label: Text(
                'ផ្សេងៗ (កំណត់សម្គាល់)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: data.adviserRows.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            final totalScore = data.subjects
                .map((s) => row.subjectYearlyAverages[s.id] ?? 0)
                .fold<double>(0, (sum, value) => sum + value);
            return DataRow(
              cells: [
                DataCell(Text('${index + 1}')),
                DataCell(
                  Text(
                    row.student.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                ...data.subjects.map((s) {
                  final avg = row.subjectYearlyAverages[s.id];
                  return DataCell(
                    Text(avg != null && avg > 0 ? avg.toStringAsFixed(0) : '-'),
                  );
                }),
                DataCell(
                  Text(totalScore > 0 ? totalScore.toStringAsFixed(0) : '-'),
                ),
                DataCell(
                  Text(
                    row.overallPercentage > 0
                        ? '${row.overallPercentage.toStringAsFixed(1)}%'
                        : '-',
                  ),
                ),
                DataCell(Text(row.rank > 0 ? row.rank.toString() : '-')),
                DataCell(
                  SizedBox(
                    width: 150,
                    child: TextFormField(
                      initialValue: row.student.remarks ?? '',
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'បន្ថែមកំណត់សម្គាល់...',
                        isDense: true,
                      ),
                      onFieldSubmitted: (val) => ref
                          .read(studentNotifierProvider.notifier)
                          .updateStudent(row.student.copyWith(remarks: val)),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  //  Subject Teacher View
  // ---------------------------------------------------------------------------

  Widget _buildSubjectTeacherView(GradeCalculationData data) {
    if (_selectedSubjectId == null ||
        !data.subjectTeacherRows.containsKey(_selectedSubjectId)) {
      return const Center(child: Text('សូមជ្រើសមុខវិជ្ជាត្រឹមត្រូវ'));
    }

    final rows = data.subjectTeacherRows[_selectedSubjectId]!;
    if (rows.isEmpty) {
      return const Center(child: Text('មិនមានសិស្សក្នុងថ្នាក់នេះ។'));
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final sem1Sorted = rows.where((r) => r.sem1Average > 0).toList()
      ..sort((a, b) => b.sem1Average.compareTo(a.sem1Average));
    final sem2Sorted = rows.where((r) => r.sem2Average > 0).toList()
      ..sort((a, b) => b.sem2Average.compareTo(a.sem2Average));

    final sem1Ranks = <int, int>{};
    final sem2Ranks = <int, int>{};

    int currentSem1Rank = 1;
    for (int i = 0; i < sem1Sorted.length; i++) {
      if (i > 0 && sem1Sorted[i].sem1Average < sem1Sorted[i - 1].sem1Average) {
        currentSem1Rank = i + 1;
      }
      final studentId = sem1Sorted[i].student.id;
      if (studentId != null) {
        sem1Ranks[studentId] = currentSem1Rank;
      }
    }

    int currentSem2Rank = 1;
    for (int i = 0; i < sem2Sorted.length; i++) {
      if (i > 0 && sem2Sorted[i].sem2Average < sem2Sorted[i - 1].sem2Average) {
        currentSem2Rank = i + 1;
      }
      final studentId = sem2Sorted[i].student.id;
      if (studentId != null) {
        sem2Ranks[studentId] = currentSem2Rank;
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width,
        ),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
          columnSpacing: 8,
          horizontalMargin: 8,
          columns: [
            const DataColumn(
              label: Text('ល.រ', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const DataColumn(
              label: Text(
                'នាម និង គោត្តនាម',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ...months.map(
              (m) => DataColumn(
                label: Text(
                  kMonthLabels[m] ?? m,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const DataColumn(
              label: Text(
                'ឆ-ទី1',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'ចំ-ឆ1',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const DataColumn(
              label: Text(
                'ឆ-ទី2',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'ចំ-ឆ2',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
          rows: rows.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            final studentId = row.student.id;
            return DataRow(
              cells: [
                DataCell(Text('${index + 1}')),
                DataCell(
                  Text(
                    row.student.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                ...months.map((m) => _buildMonthCell(row, m)),
                _buildSemesterCell(
                  row,
                  'SEM1',
                  'ឆមាសទី 1',
                  row.sem1Average,
                  row.sem1OverrideEntry,
                ),
                DataCell(
                  Text(
                    studentId != null && sem1Ranks.containsKey(studentId)
                        ? sem1Ranks[studentId].toString()
                        : '-',
                  ),
                ),
                _buildSemesterCell(
                  row,
                  'SEM2',
                  'ឆមាសទី 2',
                  row.sem2Average,
                  row.sem2OverrideEntry,
                ),
                DataCell(
                  Text(
                    studentId != null && sem2Ranks.containsKey(studentId)
                        ? sem2Ranks[studentId].toString()
                        : '-',
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  //  Month Cell — always tappable
  // ---------------------------------------------------------------------------

  DataCell _buildMonthCell(SubjectTeacherRow row, String month) {
    final entries = row.monthlyEntries[month] ?? [];
    final raw = row.monthlyRawScores[month];

    final hasAssignments = entries.isNotEmpty;
    final hasScore = raw != null && hasAssignments;

    String displayText = '-';
    if (hasScore) {
      final totalMax = entries.fold<double>(
        0,
        (s, e) => s + e.assignment.maxPoints,
      );
      displayText = '${raw.toStringAsFixed(0)}/${totalMax.toStringAsFixed(0)}';
    }

    return DataCell(
      InkWell(
        onTap: () => _showScoreEntryDialog(row, month, entries),
        borderRadius: BorderRadius.circular(6),
        child: _scorePill(
          displayText,
          hasScore,
          Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  //  Semester / Yearly Cell — tappable, supports manual override
  // ---------------------------------------------------------------------------

  DataCell _buildSemesterCell(
    SubjectTeacherRow row,
    String periodTag, // 'SEM1', 'SEM2', 'YEARLY'
    String label,
    double calculatedValue,
    AssignmentScoreEntry? overrideEntry,
  ) {
    final isOverride = overrideEntry?.currentScore != null;
    final hasValue = calculatedValue > 0;

    String displayText;
    if (isOverride) {
      final e = overrideEntry!;
      displayText =
          '${e.currentScore!.toStringAsFixed(0)}/${e.assignment.maxPoints.toStringAsFixed(0)}';
    } else if (hasValue) {
      displayText = calculatedValue.toStringAsFixed(1);
    } else {
      displayText = '-';
    }

    final accent = _semesterColor(periodTag);

    return DataCell(
      InkWell(
        onTap: () =>
            _showSemesterEntryDialog(row, periodTag, label, overrideEntry),
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _scorePill(displayText, hasValue, accent),
            // Small "auto" badge when value is calculated (not overridden)
            if (hasValue && !isOverride)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: accent.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'auto',
                    style: TextStyle(
                      fontSize: 7,
                      color: accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _semesterColor(String tag) {
    switch (tag) {
      case 'SEM1':
        return Colors.indigo;
      case 'SEM2':
        return Colors.teal;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  /// Shared pill widget used by both month and semester cells.
  Widget _scorePill(String text, bool active, Color accent) {
    return Container(
      constraints: const BoxConstraints(minWidth: 50),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active ? accent.withValues(alpha: 0.08) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: active ? accent.withValues(alpha: 0.3) : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              color: active ? accent : Colors.black45,
            ),
          ),
          const SizedBox(width: 3),
          Icon(
            Icons.edit_rounded,
            size: 10,
            color: active ? accent.withValues(alpha: 0.6) : Colors.black26,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  //  Dialogs
  // ---------------------------------------------------------------------------

  /// Score entry dialog for monthly cells.
  Future<void> _showScoreEntryDialog(
    SubjectTeacherRow row,
    String month,
    List<AssignmentScoreEntry> entries,
  ) async {
    final subjectId = _selectedSubjectId!;
    final year = DateTime.now().year.toString();

    await showDialog(
      context: context,
      builder: (ctx) => _ScoreEntryDialog(
        studentName: row.student.name,
        titleLabel: kMonthLabels[month] ?? month,
        entries: entries,
        onSave: (Map<int, double?> newScores) async {
          final notifier = ref.read(scoreNotifierProvider.notifier);
          for (final e in newScores.entries) {
            if (e.value != null) {
              await notifier.saveScoreForAssignment(
                row.student.id!,
                e.key,
                e.value!,
              );
            }
          }
          ref.invalidate(gradeCalculationProvider(widget.classId));
        },
        onSaveFreeForm: (double score, double maxPoints, String name) async {
          final assignmentRepo = ref.read(assignmentRepositoryProvider);
          final scoreRepo = ref.read(scoreRepositoryProvider);
          final id = await assignmentRepo.insert(
            AssignmentModel(
              classId: widget.classId,
              subjectId: subjectId,
              name: name,
              month: month,
              year: year,
              maxPoints: maxPoints,
            ),
          );
          await scoreRepo.upsert(
            ScoreModel(
              studentId: row.student.id!,
              assignmentId: id,
              pointsEarned: score.clamp(0, maxPoints),
            ),
          );
          ref.invalidate(gradeCalculationProvider(widget.classId));
          ref.invalidate(assignmentNotifierProvider);
        },
      ),
    );
  }

  /// Score entry dialog for Semester / Yearly cells.
  Future<void> _showSemesterEntryDialog(
    SubjectTeacherRow row,
    String periodTag, // 'SEM1', 'SEM2', 'YEARLY'
    String label,
    AssignmentScoreEntry? existing,
  ) async {
    final subjectId = _selectedSubjectId!;
    final year = DateTime.now().year.toString();

    // Pre-build a single-entry list if an override already exists,
    // otherwise pass empty so the free-form UI shows up.
    final entries = existing != null ? [existing] : <AssignmentScoreEntry>[];

    final Map<String, String> periodNames = {
      'SEM1': 'ពិន្ទុឆមាសទី 1',
      'SEM2': 'ពិន្ទុឆមាសទី 2',
      'YEARLY': 'ពិន្ទុប្រចាំឆ្នាំ',
    };

    await showDialog(
      context: context,
      builder: (ctx) => _ScoreEntryDialog(
        studentName: row.student.name,
        titleLabel: label,
        entries: entries,
        isSemesterMode: true,
        onSave: (Map<int, double?> newScores) async {
          // Update existing override assignment score
          final notifier = ref.read(scoreNotifierProvider.notifier);
          for (final e in newScores.entries) {
            if (e.value != null) {
              await notifier.saveScoreForAssignment(
                row.student.id!,
                e.key,
                e.value!,
              );
            }
          }
          ref.invalidate(gradeCalculationProvider(widget.classId));
        },
        onSaveFreeForm: (double score, double maxPoints, String name) async {
          // Create override assignment if it doesn't exist yet
          final assignmentRepo = ref.read(assignmentRepositoryProvider);
          final scoreRepo = ref.read(scoreRepositoryProvider);
          final id = await assignmentRepo.insert(
            AssignmentModel(
              classId: widget.classId,
              subjectId: subjectId,
              name: periodNames[periodTag] ?? name,
              month: periodTag, // 'SEM1', 'SEM2', or 'YEARLY'
              year: year,
              maxPoints: maxPoints,
            ),
          );
          await scoreRepo.upsert(
            ScoreModel(
              studentId: row.student.id!,
              assignmentId: id,
              pointsEarned: score.clamp(0, maxPoints),
            ),
          );
          ref.invalidate(gradeCalculationProvider(widget.classId));
          ref.invalidate(assignmentNotifierProvider);
        },
      ),
    );
  }
}

// =============================================================================
//  Score Entry Dialog
// =============================================================================

class _ScoreEntryDialog extends StatefulWidget {
  final String studentName;
  final String titleLabel;
  final List<AssignmentScoreEntry> entries;
  final bool isSemesterMode; // tweaks wording for SEM/YEARLY overrides
  final Future<void> Function(Map<int, double?> scores) onSave;
  final Future<void> Function(double score, double maxPoints, String name)
  onSaveFreeForm;

  const _ScoreEntryDialog({
    required this.studentName,
    required this.titleLabel,
    required this.entries,
    required this.onSave,
    required this.onSaveFreeForm,
    this.isSemesterMode = false,
  });

  @override
  State<_ScoreEntryDialog> createState() => _ScoreEntryDialogState();
}

class _ScoreEntryDialogState extends State<_ScoreEntryDialog> {
  late Map<int, String?> _dropdownValues;
  late Map<int, TextEditingController> _controllers;

  final _freeScoreCtrl = TextEditingController();
  final _freeMaxCtrl = TextEditingController(text: '100');
  final _freeNameCtrl = TextEditingController(text: 'ពិន្ទុប្រចាំខែ');

  bool _isSaving = false;
  bool get _hasEntries => widget.entries.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _dropdownValues = {};
    _controllers = {};

    for (final entry in widget.entries) {
      final id = entry.assignment.id!;
      if (entry.currentScore != null) {
        final score = entry.currentScore!;
        final presets = _buildPresets(entry.assignment.maxPoints);
        final scoreStr = _fmt(score);
        _dropdownValues[id] = presets.contains(scoreStr) ? scoreStr : 'custom';
        _controllers[id] = TextEditingController(text: scoreStr);
      } else {
        _dropdownValues[id] = 'custom';
        _controllers[id] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _freeScoreCtrl.dispose();
    _freeMaxCtrl.dispose();
    _freeNameCtrl.dispose();
    super.dispose();
  }

  String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  List<String> _buildPresets(double maxPoints) {
    if (maxPoints <= 0) return ['0'];
    final max = maxPoints.toInt();
    final Set<int> vals = {0, max};
    for (final pct in [0.25, 0.5, 0.75]) {
      final v = (maxPoints * pct).round();
      if (v > 0 && v < max) vals.add(v);
    }
    return (vals.toList()..sort()).map((v) => v.toString()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'បញ្ចូលពិន្ទុ',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 2),
          Text(
            '${widget.studentName}  •  ${widget.titleLabel}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: _hasEntries
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.entries.map(_buildAssignmentRow).toList(),
                )
              : _buildFreeFormEntry(),
        ),
      ),
      actions: [
        const Divider(height: 1),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
              child: const Text('បោះបង់'),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded, size: 16),
              label: const Text('រក្សាទុក'),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  //  Free-form entry (no existing assignments)
  // ---------------------------------------------------------------------------

  Widget _buildFreeFormEntry() {
    final bannerText = widget.isSemesterMode
        ? 'ពិន្ទុដែលបញ្ចូលនឹងជំនួសតម្លៃដែលគណនាដោយស្វ័យប្រវត្តិ។'
        : 'ខែនេះមិនទាន់មានកិច្ចការ។ ពិន្ទុដែលបញ្ចូលនឹងបង្កើតកិច្ចការថ្មីដោយស្វ័យប្រវត្តិ។';

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    bannerText,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.amber.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Show name field only for monthly mode (sem/yearly name is fixed)
          if (!widget.isSemesterMode) ...[
            Text(
              'ឈ្មោះកិច្ចការ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _freeNameCtrl,
              decoration: InputDecoration(
                hintText: 'ពិន្ទុប្រចាំខែ',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Score + Max row
          Row(
            children: [
              Expanded(
                child: _numField(
                  'ពិន្ទុដែលបាន',
                  _freeScoreCtrl,
                  autofocus: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 22, left: 10, right: 10),
                child: Text(
                  '/',
                  style: TextStyle(fontSize: 22, color: Colors.grey.shade400),
                ),
              ),
              Expanded(child: _numField('ពិន្ទុសរុប', _freeMaxCtrl)),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _numField(
    String label,
    TextEditingController ctrl, {
    bool autofocus = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          autofocus: autofocus,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          decoration: InputDecoration(
            hintText: '0',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  //  Existing-assignment row
  // ---------------------------------------------------------------------------

  Widget _buildAssignmentRow(AssignmentScoreEntry entry) {
    final id = entry.assignment.id!;
    final maxPts = entry.assignment.maxPoints;
    final presets = _buildPresets(maxPts);
    final isCustom = _dropdownValues[id] == 'custom';
    final maxStr = _fmt(maxPts);

    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.assignment.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  'ពិន្ទុ: $maxStr',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _dropdownValues[id],
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    isDense: true,
                  ),
                  hint: const Text('ជ្រើសរើស...'),
                  items: [
                    ...presets.map(
                      (v) => DropdownMenuItem(
                        value: v,
                        child: Text('$v / $maxStr'),
                      ),
                    ),
                    const DropdownMenuItem(
                      enabled: false,
                      value: '__sep__',
                      child: Divider(height: 1),
                    ),
                    const DropdownMenuItem(
                      value: 'custom',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 14),
                          SizedBox(width: 6),
                          Text('បញ្ចូលដោយខ្លួនឯង'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    if (val == null || val == '__sep__') return;
                    setState(() {
                      _dropdownValues[id] = val;
                      if (val != 'custom') _controllers[id]!.text = val;
                    });
                  },
                ),
              ),
              if (isCustom) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 88,
                  child: TextFormField(
                    controller: _controllers[id],
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: InputDecoration(
                      hintText: '0',
                      suffixText: '/$maxStr',
                      suffixStyle: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 9,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      isDense: true,
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: Colors.grey.shade100, height: 1),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  //  Save
  // ---------------------------------------------------------------------------

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      if (!_hasEntries) {
        final score = double.tryParse(_freeScoreCtrl.text.trim());
        final maxPts = double.tryParse(_freeMaxCtrl.text.trim());
        final name = _freeNameCtrl.text.trim().isEmpty
            ? 'ពិន្ទុប្រចាំខែ'
            : _freeNameCtrl.text.trim();
        if (score != null && maxPts != null && maxPts > 0) {
          // Close dialog before saving to prevent state disposal issues
          if (mounted) Navigator.of(context).pop();
          await widget.onSaveFreeForm(score, maxPts, name);
        }
      } else {
        final Map<int, double?> result = {};
        for (final entry in widget.entries) {
          final id = entry.assignment.id!;
          final maxPts = entry.assignment.maxPoints;
          final raw = _controllers[id]!.text.trim();
          if (raw.isEmpty) {
            result[id] = null;
            continue;
          }
          final parsed = double.tryParse(raw);
          result[id] = parsed?.clamp(0, maxPts).toDouble();
        }
        // Close dialog before saving to prevent state disposal issues
        if (mounted) Navigator.of(context).pop();
        await widget.onSave(result);
      }
    } catch (e) {
      // If there was an error and dialog wasn't closed, update state
      if (mounted) {
        setState(() => _isSaving = false);
      }
      rethrow;
    }
  }
}
