import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/student_model.dart';
import '../providers/student_provider.dart';
import '../views/student_profile_screen.dart';
import '../../../core/theme/app_theme.dart';

class StudentListTileWidget extends ConsumerWidget {
  final StudentModel student;
  final VoidCallback? onDelete;

  const StudentListTileWidget({
    Key? key,
    required this.student,
    this.onDelete,
  }) : super(key: key);

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: student.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Student'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Student full name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty && student.id != null) {
                ref.read(studentNotifierProvider.notifier).updateStudent(student.copyWith(name: name));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Student?'),
        content: Text('Remove "${student.name}" from this class?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () {
              onDelete!();
              Navigator.pop(ctx);
            },
            child: const Text('Remove'),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        onTap: () => _openProfile(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primaryLight,
              child: Text(
                student.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
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
                if (value == 'profile') _openProfile(context);
                if (value == 'edit') _showEditDialog(context, ref);
                if (value == 'remove' && onDelete != null) _showDeleteDialog(context);
              },
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'profile',
                  child: Row(children: [
                    Icon(Icons.person_outline, color: AppColors.primary, size: AppSizes.iconMd),
                    SizedBox(width: 8),
                    Text('View Profile'),
                  ]),
                ),
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(children: [
                    Icon(Icons.edit_outlined, color: AppColors.primary, size: AppSizes.iconMd),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ]),
                ),
                if (onDelete != null)
                  const PopupMenuItem<String>(
                    value: 'remove',
                    child: Row(children: [
                      Icon(Icons.delete_outline, color: AppColors.danger, size: AppSizes.iconMd),
                      SizedBox(width: 8),
                      Text('Remove', style: TextStyle(color: AppColors.danger)),
                    ]),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
