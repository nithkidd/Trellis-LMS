import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/student_model.dart';
import '../providers/student_provider.dart';
import '../views/student_profile_screen.dart';
import '../views/student_details_screen.dart';
import 'student_form_dialog.dart';
import '../../../core/theme/app_theme.dart';

class StudentListTileWidget extends ConsumerWidget {
  final StudentModel student;
  final VoidCallback? onDelete;

  const StudentListTileWidget({Key? key, required this.student, this.onDelete})
    : super(key: key);

  void _showEditDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) =>
          StudentFormDialog(student: student, classId: student.classId),
    );

    if (result != null && student.id != null) {
      ref
          .read(studentNotifierProvider.notifier)
          .updateStudent(
            student.copyWith(
              name: result['name'] as String,
              sex: result['sex'] as String?,
              dateOfBirth: result['dateOfBirth'] as String?,
              address: result['address'] as String?,
              remarks: result['remarks'] as String?,
            ),
          );
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('លុបសិស្សចេញ?'),
        content: Text('លុប "${student.name}" ចេញពីថ្នាក់នេះមែនទេ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('បោះបង់'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () {
              onDelete!();
              Navigator.pop(ctx);
            },
            child: const Text('លុប'),
          ),
        ],
      ),
    );
  }

  void _openProfile(BuildContext context) {
    if (student.id != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StudentProfileScreen(
            studentId: student.id!,
            studentName: student.name,
          ),
        ),
      );
    }
  }

  void _openDetails(BuildContext context) {
    if (student.id != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StudentDetailsScreen(student: student),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        onTap: () => _openDetails(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                student.name.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            title: Text(student.name, style: AppTextStyles.subheading),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              onSelected: (value) {
                if (value == 'details') _openDetails(context);
                if (value == 'profile') _openProfile(context);
                if (value == 'edit') _showEditDialog(context, ref);
                if (value == 'remove' && onDelete != null)
                  _showDeleteDialog(context);
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'details',
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: AppSizes.iconMd,
                      ),
                      const SizedBox(width: 8),
                      const Text('មើលព័ត៌មានលម្អិត'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(
                        Icons.assessment_outlined,
                        color: Theme.of(context).colorScheme.primary,
                        size: AppSizes.iconMd,
                      ),
                      const SizedBox(width: 8),
                      const Text('មើលពិន្ទុ'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        color: Theme.of(context).colorScheme.primary,
                        size: AppSizes.iconMd,
                      ),
                      SizedBox(width: 8),
                      Text('កែប្រែ'),
                    ],
                  ),
                ),
                if (onDelete != null)
                  const PopupMenuItem<String>(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: AppColors.danger,
                          size: AppSizes.iconMd,
                        ),
                        SizedBox(width: 8),
                        Text('លុប', style: TextStyle(color: AppColors.danger)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
