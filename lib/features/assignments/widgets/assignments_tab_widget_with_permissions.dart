import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/assignment_provider.dart';
import '../../subjects/providers/subject_provider.dart';
import '../../subjects/models/subject_model.dart';
import '../../teachers/providers/class_teacher_subject_provider.dart';
import '../../teachers/services/teacher_permission_service.dart';
import 'assignment_list_tile_widget.dart';

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
  'Jan': 'មकरា',
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

class AssignmentsTabWidgetWithPermissions extends ConsumerStatefulWidget {
  final int classId;
  final int? teacherId; // null if viewing as admin, non-null for teacher view
  final bool isAdviser; // true if teacher is class adviser

  const AssignmentsTabWidgetWithPermissions({
    super.key,
    required this.classId,
    this.teacherId,
    this.isAdviser = false,
  });

  @override
  ConsumerState<AssignmentsTabWidgetWithPermissions> createState() =>
      _AssignmentsTabWidgetWithPermissionsState();
}

class _AssignmentsTabWidgetWithPermissionsState
    extends ConsumerState<AssignmentsTabWidgetWithPermissions> {
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
    final teacherSubjectsState = widget.teacherId != null
        ? ref.watch(
            teacherSubjectsProvider((widget.classId, widget.teacherId!)),
          )
        : const AsyncValue.data([]);

    List<SubjectModel> availableSubjects = [];
    if (subjectsState is AsyncData && teacherSubjectsState is AsyncData) {
      final allSubjects = subjectsState.value ?? [];
      final taughtSubjectIds = (teacherSubjectsState.value ?? []).cast<int>();

      // Filter based on permission
      if (widget.teacherId == null) {
        // Admin mode - show all subjects
        availableSubjects = allSubjects;
      } else if (widget.isAdviser) {
        // Adviser cannot create assignments, only for their taught subjects
        availableSubjects =
            TeacherPermissionService.filterTeacherEditableSubjects(
              allSubjects: allSubjects,
              taughtSubjectIds: taughtSubjectIds,
            );
      } else {
        // Regular teacher - only their subjects
        availableSubjects =
            TeacherPermissionService.filterTeacherEditableSubjects(
              allSubjects: allSubjects,
              taughtSubjectIds: taughtSubjectIds,
            );
      }
    }

    if (availableSubjects.isNotEmpty) {
      selectedSubjectId = availableSubjects.first.id;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('កិច្ចការថ្មី'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (availableSubjects.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          widget.isAdviser
                              ? 'អ្នកមិនបាននិយាយបង្រៀនលើមុខវិជ្ជាមួយណាក្នុងថ្នាក់នេះទេ។'
                              : 'សូមបន្ថែមមុខវិជ្ជាជាមុនសិននៅការកំណត់ថ្នាក់។',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    else ...[
                      DropdownButtonFormField<int>(
                        initialValue: selectedSubjectId,
                        decoration: const InputDecoration(
                          labelText: 'មុខវិជ្ជា',
                        ),
                        items: availableSubjects
                            .map(
                              (subject) => DropdownMenuItem(
                                value: subject.id,
                                child: Text(subject.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setStateDialog(() {
                              selectedSubjectId = value;
                            });
                          }
                        },
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
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedMonth,
                        decoration: const InputDecoration(labelText: 'ខែ'),
                        items: kMonths
                            .map(
                              (month) => DropdownMenuItem(
                                value: month,
                                child: Text(kMonthLabels[month] ?? month),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setStateDialog(() {
                              selectedMonth = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: TextEditingController(text: selectedYear),
                        decoration: const InputDecoration(labelText: 'ឆ្នាំ'),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          selectedYear = value;
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                const Divider(height: 1),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('បោះបង់'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed:
                          (availableSubjects.isEmpty ||
                              selectedSubjectId == null ||
                              nameController.text.isEmpty)
                          ? null
                          : () {
                              final maxPts = double.tryParse(
                                maxPointsController.text,
                              );
                              if (maxPts != null && maxPts > 0) {
                                ref
                                    .read(assignmentNotifierProvider.notifier)
                                    .addAssignment(
                                      widget.classId,
                                      selectedSubjectId!,
                                      nameController.text,
                                      selectedMonth,
                                      selectedYear,
                                      maxPts,
                                    );
                                Navigator.pop(context);
                              }
                            },
                      child: const Text('បន្ថែម'),
                    ),
                  ],
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
    final subjectsState = ref.watch(subjectNotifierProvider);

    final teacherSubjectsState = widget.teacherId != null
        ? ref.watch(
            teacherSubjectsProvider((widget.classId, widget.teacherId!)),
          )
        : const AsyncValue.data([]);

    return assignmentsState.when(
      data: (allAssignments) {
        return subjectsState.when(
          data: (subjects) {
            return teacherSubjectsState.when(
              data: (rawTaughtSubjectIds) {
                final taughtSubjectIds = rawTaughtSubjectIds.cast<int>();
                // Filter assignments based on permissions
                List<dynamic> visibleAssignments = allAssignments;
                if (widget.teacherId != null && !widget.isAdviser) {
                  visibleAssignments =
                      TeacherPermissionService.filterAssignmentsByTeacherPermission(
                        allAssignments: allAssignments,
                        taughtSubjectIds: taughtSubjectIds,
                      );
                }

                if (visibleAssignments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.isAdviser
                              ? 'មិនមានកិច្ចការសម្រាប់មុខវិជ្ជាដែលអ្នកបង្រៀន'
                              : 'មិនមានកិច្ចការក្នុងរដូវកាលនេះ',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed:
                              (widget.isAdviser && widget.teacherId != null)
                              ? null
                              : () => _showAddAssignmentDialog(context, ref),
                          icon: const Icon(Icons.add),
                          label: const Text('បន្ថែមកិច្ចការ'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: visibleAssignments.length,
                  itemBuilder: (context, index) {
                    final assignment = visibleAssignments[index];
                    final canDelete =
                        widget.teacherId == null ||
                        TeacherPermissionService.canDeleteAssignment(
                          assignmentSubjectId: assignment.subjectId,
                          taughtSubjectIds: rawTaughtSubjectIds.cast<int>(),
                        );

                    return AssignmentListTileWidget(
                      assignment: assignment,
                      onDelete: canDelete
                          ? () {
                              ref
                                  .read(assignmentNotifierProvider.notifier)
                                  .deleteAssignment(assignment.id!);
                            }
                          : null,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(child: Text('Error: $err')),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => Center(child: Text('Error: $err')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(child: Text('Error: $err')),
      skipLoadingOnReload: false,
    );
  }
}
