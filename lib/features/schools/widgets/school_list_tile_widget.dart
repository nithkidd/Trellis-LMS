import 'package:flutter/material.dart';
import '../models/school_model.dart';
import '../providers/school_provider.dart';
import '../../classes/views/class_dashboard_screen.dart';
import '../../../core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SchoolListTileWidget extends ConsumerWidget {
  final SchoolModel school;
  final VoidCallback onDelete;

  const SchoolListTileWidget({
    Key? key,
    required this.school,
    required this.onDelete,
  }) : super(key: key);

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: school.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit School'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'School name'),
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
              if (name.isNotEmpty && school.id != null) {
                ref
                    .read(schoolNotifierProvider.notifier)
                    .updateSchool(school.id!, name);
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
        title: const Text('Remove School?'),
        content: Text(
          'Remove "${school.name}"? This will delete all classes, students, and grades within it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () {
              onDelete();
              Navigator.pop(ctx);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        onTap: () {
          if (school.id != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ClassDashboardScreen(
                  schoolId: school.id!,
                  schoolName: school.name,
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              child: Icon(Icons.account_balance, color: AppColors.primary),
            ),
            title: Text(school.name, style: AppTextStyles.subheading),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              onSelected: (value) {
                if (value == 'edit') _showEditDialog(context, ref);
                if (value == 'remove') _showDeleteDialog(context);
              },
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        color: AppColors.primary,
                        size: AppSizes.iconMd,
                      ),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
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
                      Text('Remove', style: TextStyle(color: AppColors.danger)),
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
