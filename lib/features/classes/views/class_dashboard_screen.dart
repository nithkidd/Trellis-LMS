import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/class_provider.dart';
import '../../workspace/views/class_workspace_screen.dart';
import '../widgets/class_list_tile.dart';
import '../widgets/add_class_dialog.dart';

class ClassDashboardScreen extends ConsumerStatefulWidget {
  final int schoolId;
  final String schoolName;

  const ClassDashboardScreen({
    super.key,
    required this.schoolId,
    required this.schoolName,
  });

  @override
  ConsumerState<ClassDashboardScreen> createState() =>
      _ClassDashboardScreenState();
}

class _ClassDashboardScreenState extends ConsumerState<ClassDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(classNotifierProvider.notifier)
          .loadClassesForSchool(widget.schoolId);
    });
  }

  void _showAddClassDialog(BuildContext context) {
    AddClassDialog.show(context, (name, year, isAdviser, subjects) {
      ref
          .read(classNotifierProvider.notifier)
          .addClass(
            widget.schoolId,
            name,
            year,
            isAdviser: isAdviser,
            subjects: subjects,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final classesState = ref.watch(classNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: Text('ថ្នាក់របស់ ${widget.schoolName}')),
      body: classesState.when(
        data: (classes) {
          if (classes.isEmpty) {
            return const Center(
              child: Text(
                'មិនទាន់មានថ្នាក់ក្នុងសាលានេះ។\nចុច + ដើម្បីបង្កើត។',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final model = classes[index];
              return ClassListTile(
                model: model,
                onDelete: () {
                  if (model.id != null) {
                    ref
                        .read(classNotifierProvider.notifier)
                        .deleteClass(model.id!);
                  }
                },
                onTap: () {
                  if (model.id != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClassWorkspaceScreen(
                          classId: model.id!,
                          className: model.name,
                          isAdviser: model.isAdviser,
                        ),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'កំហុសពេលផ្ទុកថ្នាក់៖ $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddClassDialog(context),
        tooltip: 'បន្ថែមថ្នាក់',
        child: const Icon(Icons.add),
      ),
    );
  }
}
