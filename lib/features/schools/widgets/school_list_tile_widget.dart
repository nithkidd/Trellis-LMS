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
    super.key,
    required this.school,
    required this.onDelete,
  });

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
          'លុប "${school.name}" តើអ្នកប្រាកដទេ? សកម្មភាពនេះនឹងលុបទិន្នន័យថ្នាក់រៀន សិស្ស និងពិន្ទុទាំងអស់នៅក្នុងសាលានេះ។',
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
    final primary = Theme.of(context).colorScheme.primary;

    return Card(
      elevation: 2,
      shadowColor: primary.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Blue gradient banner ─────────  ─────────────────────────────
            Container(
              height: 120,
              decoration: BoxDecoration(color: primary),
              child: Stack(
                children: [
                  // Centered school icon
                  const Center(
                    child: Icon(
                      Icons.account_balance_rounded,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                  // ⋮ Menu — top-right corner
                  Positioned(
                    top: 4,
                    right: 4,
                    child: PopupMenuButton<String>(
                      icon: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.more_vert,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
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
                                color: primary,
                                size: AppSizes.iconMd,
                              ),
                              const SizedBox(width: 8),
                              const Text('កែប្រែ'),
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
                              Text(
                                'លុប',
                                style: TextStyle(color: AppColors.danger),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── White body ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(school.name, style: AppTextStyles.subheading),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('ចុចដើម្បីមើលថ្នាក់', style: AppTextStyles.caption),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
