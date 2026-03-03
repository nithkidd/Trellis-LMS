import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/teacher_provider.dart';
import '../providers/class_teacher_subject_provider.dart';
import '../../subjects/providers/subject_provider.dart';

class SubjectAssignmentWidget extends ConsumerStatefulWidget {
  final int classId;
  final int? schoolId;

  const SubjectAssignmentWidget({
    super.key,
    required this.classId,
    this.schoolId,
  });

  @override
  ConsumerState<SubjectAssignmentWidget> createState() =>
      _SubjectAssignmentWidgetState();
}

class _SubjectAssignmentWidgetState
    extends ConsumerState<SubjectAssignmentWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.schoolId != null) {
        ref
            .read(teacherNotifierProvider.notifier)
            .loadTeachersForSchool(widget.schoolId!);
      }
      ref
          .read(subjectNotifierProvider.notifier)
          .loadSubjectsForClass(widget.classId);
    });
  }

  void _showAssignmentDialog() {
    final teachersState = ref.watch(teacherNotifierProvider);
    final subjectsState = ref.watch(subjectNotifierProvider);

    if (teachersState is! AsyncData || subjectsState is! AsyncData) {
      return;
    }

    final teachers = teachersState.value ?? [];
    final subjects = subjectsState.value ?? [];

    int? selectedTeacherId;
    int? selectedSubjectId;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'ចាត់តែងអ្នកបង្រៀនចំពោះមុខវិជ្ជា',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'រើសយក្សរាង្គ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<int>(
                      hint: const Text('ជ្រើសរើសអ្នកបង្រៀន...'),
                      value: selectedTeacherId,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: teachers
                          .map(
                            (t) => DropdownMenuItem(
                              value: t.id,
                              child: Text(t.name),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() => selectedTeacherId = val);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'រើសមុខវិជ្ជា',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<int>(
                      hint: const Text('ជ្រើសរើសមុខវិជ្ជា...'),
                      value: selectedSubjectId,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: subjects
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() => selectedSubjectId = val);
                      },
                    ),
                  ),
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
                        selectedTeacherId != null && selectedSubjectId != null
                        ? () {
                            ref
                                .read(
                                  classTeacherSubjectNotifierProvider.notifier,
                                )
                                .assignSubjectToTeacher(
                                  classId: widget.classId,
                                  teacherId: selectedTeacherId!,
                                  subjectId: selectedSubjectId!,
                                );
                            Navigator.pop(context);
                          }
                        : null,
                    child: const Text('ចាត់តែង'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final assignmentsState = ref.watch(
      classSubjectTeachersProvider(widget.classId),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('ចាត់តែងអ្នកបង្រៀនចំពោះមុខវិជ្ជា'),
        elevation: 1,
      ),
      body: assignmentsState.when(
        data: (assignments) {
          if (assignments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_ind_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'មិនមានការចាត់តែង',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _showAssignmentDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('បន្ថែមការចាត់តែង'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: assignments.length,
            itemBuilder: (context, index) {
              final assignment = assignments[index];
              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  title: Text(
                    assignment.subject.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    assignment.teacher.name,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.red.shade400,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('លុបការចាត់តែង'),
                          content: const Text(
                            'តើ​អ្នក​ប្រាកដ​ថា​ចង់​លុប​ការ​ចាត់​តែង​នេះ​ដែរ​ឬ​ទេ?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('ដោះស្រាយ'),
                            ),
                            FilledButton(
                              onPressed: () {
                                ref
                                    .read(
                                      classTeacherSubjectNotifierProvider
                                          .notifier,
                                    )
                                    .unassignSubjectFromTeacher(
                                      classId: widget.classId,
                                      teacherId: assignment.teacher.id!,
                                      subjectId: assignment.subject.id!,
                                    );
                                Navigator.pop(ctx);
                              },
                              child: const Text('លុប'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
              const SizedBox(height: 16),
              Text('ត្រូវកំហុស: $err'),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAssignmentDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
