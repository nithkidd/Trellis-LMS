import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../gradebook/providers/score_provider.dart';
import '../widgets/grade_banner.dart';
import '../widgets/assignment_score_card.dart';

class StudentProfileScreen extends ConsumerStatefulWidget {
  final int studentId;
  final String studentName;

  const StudentProfileScreen({
    Key? key,
    required this.studentId,
    required this.studentName,
  }) : super(key: key);

  @override
  ConsumerState<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends ConsumerState<StudentProfileScreen> {
  @override
  Widget build(BuildContext context) {
    // We watch the new composite provider that joins scores and assignments
    final profileState = ref.watch(studentProfileDataProvider(widget.studentId));

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.studentName}\'s Profile'),
      ),
      body: profileState.when(
        data: (data) {
          final scores = data.scores;
          final average = data.averagePercentage;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GradeBanner(average: average),

              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Assignment History',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),

              Expanded(
                child: scores.isEmpty
                    ? const Center(
                        child: Text(
                          'No scores recorded yet.\nScores are added via the Class Assignments grid.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: scores.length,
                        itemBuilder: (context, index) {
                          final profileScore = scores[index];
                          return AssignmentScoreCard(profileScore: profileScore);
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading profile: $error', style: const TextStyle(fontSize: 16, color: Colors.red)),
        ),
      ),
    );
  }

}
