import 'package:flutter/material.dart';
import '../../gradebook/providers/score_provider.dart';

class AssignmentScoreCard extends StatelessWidget {
  final StudentProfileScore profileScore;

  const AssignmentScoreCard({Key? key, required this.profileScore}) : super(key: key);

  Color _getGradeColor(double percentage, BuildContext context) {
    if (percentage >= 90) return Colors.green.shade700;
    if (percentage >= 80) return Colors.blue.shade700;
    if (percentage >= 70) return Colors.orange.shade700;
    if (percentage > 0) return Colors.red.shade700;
    return Theme.of(context).colorScheme.onPrimaryContainer;
  }

  @override
  Widget build(BuildContext context) {
    final percentage = profileScore.percentage;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListTile(
          minVerticalPadding: 12,
          title: Text(
            profileScore.assignment.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '${profileScore.assignment.month} ${profileScore.assignment.year} • '
              '${profileScore.score.pointsEarned.toStringAsFixed(1)} / '
              '${profileScore.assignment.maxPoints.toStringAsFixed(1)} points',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getGradeColor(percentage, context).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _getGradeColor(percentage, context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
