import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/assignment_model.dart';
import '../providers/assignment_provider.dart';
import '../../gradebook/views/gradebook_grid_screen.dart';
import '../../../core/theme/app_theme.dart';

const List<String> kMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

class AssignmentListTileWidget extends ConsumerWidget {
  final AssignmentModel assignment;
  final VoidCallback? onDelete;

  const AssignmentListTileWidget({
    Key? key,
    required this.assignment,
    this.onDelete,
  }) : super(key: key);

  void _openGradebook(BuildContext context) {
    if (assignment.id != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GradebookGridScreen(assignment: assignment),
        ),
      );
    }
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController(text: assignment.name);
    final maxPtsCtrl = TextEditingController(text: assignment.maxPoints.toString());
    String selectedMonth = kMonths.contains(assignment.month) ? assignment.month : kMonths[0];
    String selectedYear = assignment.year;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Edit Assignment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Assignment name'),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: maxPtsCtrl,
                  decoration: const InputDecoration(labelText: 'Max points'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedMonth,
                        decoration: const InputDecoration(labelText: 'Month'),
                        items: kMonths.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                        onChanged: (val) => setStateDialog(() => selectedMonth = val!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedYear,
                        decoration: const InputDecoration(labelText: 'Year'),
                        items: ['2023', '2024', '2025', '2026'].map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                        onChanged: (val) => setStateDialog(() => selectedYear = val!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final maxPts = double.tryParse(maxPtsCtrl.text.trim());
                if (name.isNotEmpty && maxPts != null && maxPts > 0 && assignment.id != null) {
                  ref.read(assignmentNotifierProvider.notifier).updateAssignment(
                    assignment.copyWith(
                      name: name,
                      month: selectedMonth,
                      year: selectedYear,
                      maxPoints: maxPts,
                    ),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Assignment?'),
        content: Text('Remove "${assignment.name}"? All scores for this assignment will be deleted.'),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingSm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        onTap: () => _openGradebook(context),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingMd,
            vertical: AppSizes.paddingSm,
          ),
          leading: const CircleAvatar(
            backgroundColor: AppColors.primaryLight,
            child: Icon(Icons.assignment, color: AppColors.primary),
          ),
          title: Text(assignment.name, style: AppTextStyles.subheading),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              '${assignment.month} ${assignment.year} • Max: ${assignment.maxPoints} pts',
              style: AppTextStyles.caption,
            ),
          ),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
            onSelected: (value) {
              if (value == 'open') _openGradebook(context);
              if (value == 'edit') _showEditDialog(context, ref);
              if (value == 'remove' && onDelete != null) _showDeleteDialog(context);
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'open',
                child: Row(children: [
                  Icon(Icons.grading, color: AppColors.primary, size: AppSizes.iconMd),
                  SizedBox(width: 8),
                  Text('Open Gradebook'),
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
    );
  }
}
