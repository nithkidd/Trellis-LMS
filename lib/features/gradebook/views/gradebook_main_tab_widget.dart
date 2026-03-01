import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/grade_calculation_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../students/providers/student_provider.dart';

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

  const GradebookMainTabWidget({Key? key, required this.classId})
    : super(key: key);

  @override
  ConsumerState<GradebookMainTabWidget> createState() =>
      _GradebookMainTabWidgetState();
}

class _GradebookMainTabWidgetState
    extends ConsumerState<GradebookMainTabWidget> {
  GradebookViewMode _viewMode = GradebookViewMode.classAdviser;
  int? _selectedSubjectId;

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

  Widget _buildControlPanel(GradeCalculationData data) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
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
                child: Text('ទិដ្ឋភាពគ្រូប្រឹក្សាថ្នាក់'),
              ),
              DropdownMenuItem(
                value: GradebookViewMode.subjectTeacher,
                child: Text('ទិដ្ឋភាពគ្រូមុខវិជ្ជា'),
              ),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _viewMode = val);
            },
          ),
          if (_viewMode == GradebookViewMode.subjectTeacher) ...[
            const SizedBox(width: AppSizes.paddingLg),
            const Text(
              'មុខវិជ្ជា៖',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: AppSizes.paddingSm),
            DropdownButton<int>(
              value: _selectedSubjectId,
              underline: const SizedBox(),
              items: data.subjects
                  .map(
                    (s) => DropdownMenuItem(value: s.id, child: Text(s.name)),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedSubjectId = val);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClassAdviserView(GradeCalculationData data) {
    if (data.adviserRows.isEmpty) {
      return const Center(child: Text('មិនមានសិស្សក្នុងថ្នាក់នេះ។'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
          columns: [
            const DataColumn(
              label: Text(
                'ចំណាត់ថ្នាក់',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
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
                'មធ្យមភាគ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const DataColumn(
              label: Text(
                'និទ្ទេស',
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
          rows: data.adviserRows.map((row) {
            return DataRow(
              cells: [
                DataCell(Text(row.rank > 0 ? row.rank.toString() : '-')),
                DataCell(
                  Text(
                    row.student.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                ...data.subjects.map((s) {
                  final avg = row.subjectYearlyAverages[s.id];
                  return DataCell(
                    Text(
                      avg != null && avg > 0
                          ? '${avg.toStringAsFixed(1)}%'
                          : '-',
                    ),
                  );
                }),
                DataCell(
                  Text(
                    row.overallPercentage > 0
                        ? '${row.overallPercentage.toStringAsFixed(1)}%'
                        : '-',
                  ),
                ),
                DataCell(
                  Text(
                    row.grade,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getGradeColor(row.grade),
                    ),
                  ),
                ),
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
                      onFieldSubmitted: (val) {
                        ref
                            .read(studentNotifierProvider.notifier)
                            .updateStudent(row.student.copyWith(remarks: val));
                      },
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

  Widget _buildSubjectTeacherView(GradeCalculationData data) {
    if (_selectedSubjectId == null ||
        !data.subjectTeacherRows.containsKey(_selectedSubjectId)) {
      return const Center(child: Text('សូមជ្រើសមុខវិជ្ជាត្រឹមត្រូវ'));
    }

    final rows = data.subjectTeacherRows[_selectedSubjectId]!;
    if (rows.isEmpty) {
      return const Center(child: Text('មិនមានសិស្សក្នុងថ្នាក់នេះ។'));
    }

    final months = [
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
          columnSpacing: 20,
          columns: [
            const DataColumn(
              label: Text(
                'ឈ្មោះពេញ',
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
            DataColumn(
              label: Text(
                'ឆមាសទី 1',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'ឆមាសទី 2',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'ប្រចាំឆ្នាំ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
          rows: rows.map((row) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    row.student.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                ...months.map((m) {
                  // We show percentages here since months can have different max points.
                  final pct = row.monthlyPercentages[m];
                  return DataCell(
                    Text(pct != null ? '${pct.toStringAsFixed(0)}%' : '-'),
                  );
                }),
                DataCell(
                  Text(
                    row.sem1Average > 0
                        ? '${row.sem1Average.toStringAsFixed(1)}%'
                        : '-',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    row.sem2Average > 0
                        ? '${row.sem2Average.toStringAsFixed(1)}%'
                        : '-',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    row.yearlyAverage > 0
                        ? '${row.yearlyAverage.toStringAsFixed(1)}%'
                        : '-',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
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

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A':
        return Colors.green.shade700;
      case 'B':
        return Colors.blue.shade700;
      case 'C':
        return Colors.orange.shade700;
      case 'D':
        return Colors.deepOrange;
      case 'F':
        return Colors.red;
      default:
        return Colors.black54;
    }
  }
}
