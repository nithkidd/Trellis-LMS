import 'package:flutter/material.dart';

class GradeBanner extends StatelessWidget {
  final double average;

  const GradeBanner({super.key, required this.average});

  Color _getGradeColor(BuildContext context) {
    // if (average >= 90) return Colors.green.shade700;
    // if (average >= 80) return Colors.blue.shade700;
    // if (average >= 70) return Colors.orange.shade700;
    // if (average > 0) return Colors.red.shade700;
    return Theme.of(context).colorScheme.onPrimaryContainer;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'ពិន្ទុសរុប',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            '${average.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: _getGradeColor(context),
            ),
          ),
        ],
      ),
    );
  }
}
