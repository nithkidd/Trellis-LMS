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
        title: const Text('កែប្រែសាលា'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'ឈ្មោះសាលា'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('បោះបង់'),
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
            child: const Text('រក្សាទុក'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('លុបសាលាចេញ?'),
        content: Text(
          'លុប "${school.name}" មែនទេ? វានឹងលុបថ្នាក់ទាំងអស់ សិស្សទាំងអស់ និងពិន្ទុទាំងអស់នៅក្នុងសាលានេះ។',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('បោះបង់'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () {
              onDelete();
              Navigator.pop(ctx);
            },
            child: const Text('លុប'),
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
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.account_balance,
                color: Theme.of(context).colorScheme.primary,
              ),
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
