import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/class_model.dart';
import '../providers/class_provider.dart';
import '../../../core/theme/app_theme.dart';

class ClassListTile extends ConsumerWidget {
  final ClassModel model;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const ClassListTile({
    Key? key,
    required this.model,
    required this.onDelete,
    required this.onTap,
  }) : super(key: key);

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController(text: model.name);
    final yearCtrl = TextEditingController(text: model.academicYear);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('កែប្រែថ្នាក់'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'ឈ្មោះថ្នាក់'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: yearCtrl,
              decoration: const InputDecoration(labelText: 'ឆ្នាំសិក្សា'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('បោះបង់'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final year = yearCtrl.text.trim();
              if (name.isNotEmpty && year.isNotEmpty && model.id != null) {
                ref
                    .read(classNotifierProvider.notifier)
                    .updateClass(model.id!, name, year);
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
        title: const Text('លុបថ្នាក់ចេញ?'),
        content: Text(
          'លុប "${model.name}" មែនទេ? សិស្ស និងពិន្ទុទាំងអស់ក្នុងថ្នាក់នេះនឹងត្រូវលុប។',
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
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        onTap: onTap,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingMd,
            vertical: AppSizes.paddingSm,
          ),
          leading: const CircleAvatar(
            backgroundColor: AppColors.primaryLight,
            child: Icon(Icons.class_, color: AppColors.primary),
          ),
          title: Text(model.name, style: AppTextStyles.subheading),
          subtitle: Text(
            'ឆ្នាំសិក្សា៖ ${model.academicYear}',
            style: AppTextStyles.caption,
          ),
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
    );
  }
}
