import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/subject_provider.dart';
import '../../../core/theme/app_theme.dart';

class SubjectsTabWidget extends ConsumerStatefulWidget {
  final int classId;

  const SubjectsTabWidget({Key? key, required this.classId}) : super(key: key);

  @override
  ConsumerState<SubjectsTabWidget> createState() => _SubjectsTabWidgetState();
}

class _SubjectsTabWidgetState extends ConsumerState<SubjectsTabWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(subjectNotifierProvider.notifier)
          .loadSubjectsForClass(widget.classId);
    });
  }

  void _showAddSubjectDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Subject'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Subject Name'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
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
              child: const Text('Add'),
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
                'No subjects yet.\nTap Add below to create one.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSizes.paddingMd),
            itemCount: subjects.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return ListTile(
                title: Text(subject.name, style: AppTextStyles.subheading),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.danger,
                  ),
                  onPressed: () {
                    if (subject.id != null) {
                      ref
                          .read(subjectNotifierProvider.notifier)
                          .deleteSubject(subject.id!, widget.classId);
                    }
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Error: $error',
            style: TextStyle(color: AppColors.danger),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSubjectDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add', style: AppTextStyles.button),
      ),
    );
  }
}
