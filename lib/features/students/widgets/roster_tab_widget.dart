import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../students/providers/student_provider.dart';
import 'student_list_tile_widget.dart';
import 'student_form_dialog.dart';
import '../../../core/theme/app_theme.dart';

class RosterTabWidget extends ConsumerStatefulWidget {
  final int classId;

  const RosterTabWidget({super.key, required this.classId});

  @override
  ConsumerState<RosterTabWidget> createState() => RosterTabWidgetState();
}

class RosterTabWidgetState extends ConsumerState<RosterTabWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(studentNotifierProvider.notifier)
          .loadStudentsForClass(widget.classId);
    });
  }

  /// Called externally via GlobalKey from the parent Scaffold's FAB.
  void showAddStudentDialog() => _showAddStudentDialog(context);

  void _showAddStudentDialog(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StudentFormDialog(classId: widget.classId),
    );

    if (result != null && mounted) {
      ref
          .read(studentNotifierProvider.notifier)
          .addStudent(
            widget.classId,
            result['name'] as String,
            sex: result['sex'] as String?,
            dateOfBirth: result['dateOfBirth'] as String?,
            address: result['address'] as String?,
            remarks: result['remarks'] as String?,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsState = ref.watch(studentNotifierProvider);

    return Column(
      children: [
        Expanded(
          child: studentsState.when(
            data: (students) {
              if (students.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingLg),
                    child: Text(
                      'បញ្ជីសិស្សក្នុងថ្នាក់នេះនៅទទេ។\nចុចបន្ថែមខាងលើដើម្បីចាប់ផ្តើម។',
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
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSizes.paddingSm),
                itemBuilder: (context, index) {
                  final student = students[index];
                  return StudentListTileWidget(
                    student: student,
                    onDelete: () {
                      if (student.id != null) {
                        ref
                            .read(studentNotifierProvider.notifier)
                            .deleteStudent(student.id!);
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
        ),
      ],
    );
  }
}
