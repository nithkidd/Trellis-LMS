import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/assignment_provider.dart';
import '../../subjects/providers/subject_provider.dart';
import '../../subjects/models/subject_model.dart';
import 'assignment_list_tile_widget.dart';
import '../../../core/theme/app_theme.dart';

const List<String> kMonths = [
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

class AssignmentsTabWidget extends ConsumerStatefulWidget {
  final int classId;

  const AssignmentsTabWidget({super.key, required this.classId});

  @override
  ConsumerState<AssignmentsTabWidget> createState() =>
      _AssignmentsTabWidgetState();
}

class _AssignmentsTabWidgetState extends ConsumerState<AssignmentsTabWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(assignmentNotifierProvider.notifier)
          .loadAssignmentsForClass(widget.classId);
      ref
          .read(subjectNotifierProvider.notifier)
          .loadSubjectsForClass(widget.classId);
    });
  }

  void _showAddAssignmentDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final maxPointsController = TextEditingController(text: '100');
    String selectedMonth = kMonths[DateTime.now().month - 1];
    String selectedYear = DateTime.now().year.toString();
    int? selectedSubjectId;

    final subjectsState = ref.watch(subjectNotifierProvider);
    List<SubjectModel> subjects = [];
    if (subjectsState is AsyncData) {
      subjects = subjectsState.value!;
    }

    if (subjects.isNotEmpty) {
      selectedSubjectId = subjects.first.id;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('កិច្ចការថ្មី'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (subjects.isEmpty)
                      const Text(
                        'សូមបន្ថែមមុខវិជ្ជាជាមុនសិននៅក្នុងជម្រើសថ្នាក់។',
                        style: TextStyle(color: Colors.red),
                      )
                    else
                      DropdownButtonFormField<int>(
                        initialValue: selectedSubjectId,
                        decoration: const InputDecoration(
                          labelText: 'មុខវិជ្ជា',
                        ),
                        items: subjects
                            .map(
                              (s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(s.name),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setStateDialog(() => selectedSubjectId = val),
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'ឈ្មោះកិច្ចការ',
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: maxPointsController,
                      decoration: const InputDecoration(
                        labelText: 'ពិន្ទុអតិបរមា',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedMonth,
                            decoration: const InputDecoration(labelText: 'ខែ'),
                            items: kMonths
                                .map(
                                  (m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(kMonthLabels[m] ?? m),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setStateDialog(() => selectedMonth = val!),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedYear,
                            decoration: const InputDecoration(
                              labelText: 'ឆ្នាំ',
                            ),
                            items: ['2023', '2024', '2025', '2026']
                                .map(
                                  (y) => DropdownMenuItem(
                                    value: y,
                                    child: Text(y),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setStateDialog(() => selectedYear = val!),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('បោះបង់'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final maxPts = double.tryParse(
                      maxPointsController.text.trim(),
                    );
                    if (selectedSubjectId != null &&
                        name.isNotEmpty &&
                        maxPts != null &&
                        maxPts > 0) {
                      ref
                          .read(assignmentNotifierProvider.notifier)
                          .addAssignment(
                            widget.classId,
                            selectedSubjectId!,
                            name,
                            selectedMonth,
                            selectedYear,
                            maxPts,
                          );
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'សូមជ្រើសមុខវិជ្ជា បញ្ចូលឈ្មោះត្រឹមត្រូវ និងពិន្ទុអតិបរមា',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('បន្ថែម'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final assignmentsState = ref.watch(assignmentNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: assignmentsState.when(
        data: (assignments) {
          if (assignments.isEmpty) {
            return Center(
              child: Text(
                'មិនទាន់មានកិច្ចការ។\nចុចបន្ថែមខាងក្រោមដើម្បីបង្កើត។',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSizes.paddingMd),
            itemCount: assignments.length,
            itemBuilder: (context, index) {
              final assignment = assignments[index];
              return AssignmentListTileWidget(
                assignment: assignment,
                onDelete: () {
                  if (assignment.id != null) {
                    ref
                        .read(assignmentNotifierProvider.notifier)
                        .deleteAssignment(assignment.id!);
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'កំហុស៖ $error',
            style: TextStyle(color: AppColors.danger),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'assignments_fab',
        onPressed: () => _showAddAssignmentDialog(context, ref),
        tooltip: 'បន្ថែមកិច្ចការ',
        child: const Icon(Icons.add),
      ),
    );
  }
}
