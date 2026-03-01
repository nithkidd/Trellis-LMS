import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/assignment_provider.dart';
import '../../subjects/providers/subject_provider.dart';
import '../../subjects/models/subject_model.dart';
import 'assignment_list_tile_widget.dart';
import '../../../core/theme/app_theme.dart';

const List<String> kMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

class AssignmentsTabWidget extends ConsumerStatefulWidget {
  final int classId;

  const AssignmentsTabWidget({Key? key, required this.classId}) : super(key: key);

  @override
  ConsumerState<AssignmentsTabWidget> createState() => _AssignmentsTabWidgetState();
}

class _AssignmentsTabWidgetState extends ConsumerState<AssignmentsTabWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(assignmentNotifierProvider.notifier).loadAssignmentsForClass(widget.classId);
      ref.read(subjectNotifierProvider.notifier).loadSubjectsForClass(widget.classId);
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
              title: const Text('New Assignment'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (subjects.isEmpty)
                      const Text('Please add a Subject first in the Class options.', style: TextStyle(color: Colors.red))
                    else
                      DropdownButtonFormField<int>(
                        value: selectedSubjectId,
                        decoration: const InputDecoration(labelText: 'Subject'),
                        items: subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                        onChanged: (val) => setStateDialog(() => selectedSubjectId = val),
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Assignment name'),
                      autofocus: true,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: maxPointsController,
                      decoration: const InputDecoration(labelText: 'Max points'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedMonth,
                            decoration: const InputDecoration(labelText: 'Month'),
                            items: kMonths.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                            onChanged: (val) => setStateDialog(() => selectedMonth = val!),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedYear,
                            decoration: const InputDecoration(labelText: 'Year'),
                            items: ['2023', '2024', '2025', '2026'].map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                            onChanged: (val) => setStateDialog(() => selectedYear = val!),
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
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final maxPts = double.tryParse(maxPointsController.text.trim());
                    if (selectedSubjectId != null && name.isNotEmpty && maxPts != null && maxPts > 0) {
                      ref.read(assignmentNotifierProvider.notifier).addAssignment(
                        widget.classId, selectedSubjectId!, name, selectedMonth, selectedYear, maxPts,
                      );
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a subject, enter a valid name and max points')),
                      );
                    }
                  },
                  child: const Text('Add'),
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
                'No assignments yet.\nTap Add below to create one.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, height: 1.5),
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
                    ref.read(assignmentNotifierProvider.notifier).deleteAssignment(assignment.id!);
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error', style: TextStyle(color: AppColors.danger)),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAssignmentDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add', style: AppTextStyles.button),
      ),
    );
  }
}
