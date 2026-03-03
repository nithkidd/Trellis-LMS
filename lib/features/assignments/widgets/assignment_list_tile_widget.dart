import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/assignment_model.dart';
import '../providers/assignment_provider.dart';
import '../../gradebook/views/gradebook_grid_screen.dart';
import '../../../core/theme/app_theme.dart';

const List<String> kMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
const Map<String, String> kMonthLabels = {
  'Jan': 'មករា',
  'Feb': 'កុម្ភៈ',
  'Mar': 'មីនា',
  'Apr': 'មេសា',
  'May': 'ឧសភា',
  'Jun': 'មិថុនា',
  'Jul': 'កក្កដា',
  'Aug': 'សីហា',
  'Sep': 'កញ្ញា',
  'Oct': 'តុលា',
  'Nov': 'វិច្ឆិកា',
  'Dec': 'ធ្នូ',
};

class AssignmentListTileWidget extends ConsumerWidget {
  final AssignmentModel assignment;
  final VoidCallback? onDelete;

  const AssignmentListTileWidget({
    super.key,
    required this.assignment,
    this.onDelete,
  });

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
    final maxPtsCtrl = TextEditingController(
      text: assignment.maxPoints.toString(),
    );
    String selectedMonth = kMonths.contains(assignment.month)
        ? assignment.month
        : kMonths[0];
    String selectedYear = assignment.year;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('កែប្រែកិច្ចការ'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'ឈ្មោះកិច្ចការ'),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: maxPtsCtrl,
                  decoration: const InputDecoration(labelText: 'ពិន្ទុអតិបរមា'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedMonth,
                        decoration: const InputDecoration(labelText: 'ខែ'),
                        items: kMonths
                            .map(
                              (m) => DropdownMenuItem(
                                value: m,
                                child: Text(kMonthLabels[m] ?? m),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setStateDialog(() => selectedMonth = val!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedYear,
                        decoration: const InputDecoration(labelText: 'ឆ្នាំ'),
                        items: ['2023', '2024', '2025', '2026']
                            .map(
                              (y) => DropdownMenuItem(value: y, child: Text(y)),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setStateDialog(() => selectedYear = val!),
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
              child: const Text('បោះបង់'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final maxPts = double.tryParse(maxPtsCtrl.text.trim());
                if (name.isNotEmpty &&
                    maxPts != null &&
                    maxPts > 0 &&
                    assignment.id != null) {
                  ref
                      .read(assignmentNotifierProvider.notifier)
                      .updateAssignment(
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
              child: const Text('រក្សាទុក'),
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
        title: const Text('លុបកិច្ចការចេញ?'),
        content: Text(
          'លុប "${assignment.name}" មែនទេ? ពិន្ទុទាំងអស់សម្រាប់កិច្ចការនេះនឹងត្រូវលុប។',
        ),
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
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            child: Icon(Icons.assignment, color: Theme.of(context).colorScheme.primary),
          ),
          title: Text(assignment.name, style: AppTextStyles.subheading),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              '${kMonthLabels[assignment.month] ?? assignment.month} ${assignment.year} • អតិបរមា៖ ${assignment.maxPoints} ពិន្ទុ',
              style: AppTextStyles.caption,
            ),
          ),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            onSelected: (value) {
              if (value == 'open') _openGradebook(context);
              if (value == 'edit') _showEditDialog(context, ref);
              if (value == 'remove' && onDelete != null) {
                _showDeleteDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'open',
                child: Row(
                  children: [
                    Icon(
                      Icons.grading,
                      color: AppColors.primary,
                      size: AppSizes.iconMd,
                    ),
                    SizedBox(width: 8),
                    Text('បើកតារាងពិន្ទុ'),
                  ],
                ),
              ),
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
    );
  }
}
