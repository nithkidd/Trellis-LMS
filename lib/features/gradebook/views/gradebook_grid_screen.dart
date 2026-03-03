import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../assignments/models/assignment_model.dart';
import '../../students/providers/student_provider.dart';
import '../providers/score_provider.dart';
import '../models/score_model.dart';
import '../widgets/gradebook_app_bar_bottom.dart';
import '../widgets/gradebook_student_row.dart';

class GradebookGridScreen extends ConsumerStatefulWidget {
  final AssignmentModel assignment;

  const GradebookGridScreen({super.key, required this.assignment});

  @override
  ConsumerState<GradebookGridScreen> createState() =>
      _GradebookGridScreenState();
}

class _GradebookGridScreenState extends ConsumerState<GradebookGridScreen> {
  final Map<int, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(studentNotifierProvider.notifier)
          .loadStudentsForClass(widget.assignment.classId);
      ref
          .read(scoreNotifierProvider.notifier)
          .loadScoresForAssignment(widget.assignment.id!);
    });
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentsState = ref.watch(studentNotifierProvider);
    final scoresState = ref.watch(scoreNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.assignment.name),
        bottom: GradebookAppBarBottom(
          month: widget.assignment.month,
          year: widget.assignment.year,
          maxPoints: widget.assignment.maxPoints,
        ),
      ),
      body: studentsState.when(
        data: (students) {
          if (students.isEmpty) {
            return const Center(child: Text('មិនមានសិស្សក្នុងថ្នាក់នេះ។'));
          }

          // Build a studentId → ScoreModel lookup map
          Map<int, ScoreModel> studentScores = {};
          if (scoresState is AsyncData) {
            for (var score in scoresState.value!) {
              studentScores[score.studentId] = score;
            }
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final student = students[index];
              final score = studentScores[student.id];

              // Create and cache controller per student
              if (!_controllers.containsKey(student.id)) {
                _controllers[student.id!] = TextEditingController(
                  text: score != null ? score.pointsEarned.toString() : '',
                );
              }

              // Sync controller when a score arrives from the provider
              final controller = _controllers[student.id!]!;
              if (score != null && controller.text.isEmpty) {
                controller.text = score.pointsEarned.toString();
              }

              return GradebookStudentRow(
                student: student,
                score: score,
                controller: controller,
                assignment: widget.assignment,
                onSave: (studentId, assignmentId, points) {
                  ref
                      .read(scoreNotifierProvider.notifier)
                      .saveScoreForAssignment(studentId, assignmentId, points);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('កំហុសពេលផ្ទុកបញ្ជីសិស្ស៖ $e')),
      ),
    );
  }
}
