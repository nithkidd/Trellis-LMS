import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../students/providers/student_provider.dart';
import 'student_list_tile_widget.dart';
import '../../../core/theme/app_theme.dart';

class RosterTabWidget extends ConsumerStatefulWidget {
  final int classId;

  const RosterTabWidget({Key? key, required this.classId}) : super(key: key);

  @override
  ConsumerState<RosterTabWidget> createState() => _RosterTabWidgetState();
}

class _RosterTabWidgetState extends ConsumerState<RosterTabWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studentNotifierProvider.notifier).loadStudentsForClass(widget.classId);
    });
  }

  void _showAddStudentDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Student'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Student full name'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  ref.read(studentNotifierProvider.notifier).addStudent(widget.classId, name);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid name')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentsState = ref.watch(studentNotifierProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingMd),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
              ),
              onPressed: () => _showAddStudentDialog(context),
              icon: const Icon(Icons.add, size: AppSizes.iconLg),
              label: const Text('Add', style: AppTextStyles.button),
            ),
          ),
        ),
        Expanded(
          child: studentsState.when(
            data: (students) {
              if (students.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingLg),
                    child: Text(
                      'This class roster is empty.\nTap Add above to begin.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingMd,
                  vertical: AppSizes.paddingSm,
                ),
                itemCount: students.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSizes.paddingSm),
                itemBuilder: (context, index) {
                  final student = students[index];
                  return StudentListTileWidget(
                    student: student,
                    onDelete: () {
                      if (student.id != null) {
                        ref.read(studentNotifierProvider.notifier).deleteStudent(student.id!);
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
        ),
      ],
    );
  }
}
