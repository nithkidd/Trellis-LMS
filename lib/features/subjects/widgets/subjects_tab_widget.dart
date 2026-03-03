import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subject_model.dart';
import '../providers/subject_provider.dart';
import '../../../core/theme/app_theme.dart';

class SubjectsTabWidget extends ConsumerStatefulWidget {
  final int classId;

  const SubjectsTabWidget({super.key, required this.classId});

  @override
  ConsumerState<SubjectsTabWidget> createState() => _SubjectsTabWidgetState();
}

class _SubjectsTabWidgetState extends ConsumerState<SubjectsTabWidget> {
  bool _isReordering = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(subjectNotifierProvider.notifier)
          .loadSubjectsForClass(widget.classId);
    });
  }

  Future<void> _reorderSubjects(
    List<SubjectModel> subjects,
    int oldIndex,
    int newIndex,
  ) async {
    setState(() => _isReordering = true);
    try {
      final reordered = List<SubjectModel>.from(subjects);
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final moved = reordered.removeAt(oldIndex);
      reordered.insert(newIndex, moved);

      await ref
          .read(subjectNotifierProvider.notifier)
          .reorderSubjects(widget.classId, reordered);
    } finally {
      if (mounted) {
        setState(() => _isReordering = false);
      }
    }
  }

  void _showAddSubjectDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('បន្ថែមមុខវិជ្ជា'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'ឈ្មោះមុខវិជ្ជា'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('បោះបង់'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  ref
                      .read(subjectNotifierProvider.notifier)
                      .addSubject(widget.classId, name);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('បន្ថែម'),
            ),
          ],
        );
      },
    );
  }

  void _showEditSubjectDialog(BuildContext context, SubjectModel subject) {
    final nameController = TextEditingController(text: subject.name);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('កែប្រែមុខវិជ្ជា'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'ឈ្មោះមុខវិជ្ជា'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('បោះបង់'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty && subject.id != null) {
                  ref
                      .read(subjectNotifierProvider.notifier)
                      .updateSubject(subject.copyWith(name: name));
                  Navigator.of(context).pop();
                }
              },
              child: const Text('រក្សាទុក'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjectsState = ref.watch(subjectNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: subjectsState.when(
        data: (subjects) {
          if (subjects.isEmpty) {
            return Center(
              child: Text(
                'មិនទាន់មានមុខវិជ្ជា។\nចុចបន្ថែមខាងក្រោមដើម្បីបង្កើត។',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            );
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(
                  AppSizes.paddingMd,
                  AppSizes.paddingMd,
                  AppSizes.paddingMd,
                  AppSizes.paddingSm,
                ),
                padding: const EdgeInsets.all(AppSizes.paddingSm),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.drag_indicator,
                      size: AppSizes.iconSm,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isReordering
                            ? 'កំពុងរក្សាទុកលំដាប់មុខវិជ្ជា...'
                            : 'អូសដើម្បីប្ដូរលំដាប់មុខវិជ្ជា',
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingMd,
                    vertical: AppSizes.paddingSm,
                  ),
                  itemCount: subjects.length,
                  onReorder: (oldIndex, newIndex) =>
                      _reorderSubjects(subjects, oldIndex, newIndex),
                  itemBuilder: (context, index) {
                    final subject = subjects[index];
                    return Card(
                      key: ValueKey(subject.id ?? '${subject.name}_$index'),
                      margin: const EdgeInsets.only(bottom: AppSizes.paddingSm),
                      child: ListTile(
                        title: Text(
                          subject.name,
                          style: AppTextStyles.subheading,
                        ),
                        leading: ReorderableDragStartListener(
                          index: index,
                          child: const Icon(
                            Icons.drag_handle,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert,
                            color: AppColors.textSecondary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusMd,
                            ),
                          ),
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showEditSubjectDialog(context, subject);
                            }
                            if (value == 'remove' && subject.id != null) {
                              ref
                                  .read(subjectNotifierProvider.notifier)
                                  .deleteSubject(subject.id!, widget.classId);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem<String>(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit_outlined,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
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
                    );
                  },
                ),
              ),
            ],
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
      floatingActionButton: FloatingActionButton(
        heroTag: 'subjects_fab',
        onPressed: () => _showAddSubjectDialog(context),
        tooltip: 'បន្ថែមមុខវិជ្ជា',
        child: const Icon(Icons.add),
      ),
    );
  }
}
