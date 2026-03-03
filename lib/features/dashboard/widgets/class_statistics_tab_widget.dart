import 'package:flutter/material.dart';

class ClassStatisticsTabWidget extends StatelessWidget {
  final int classId;

  const ClassStatisticsTabWidget({super.key, required this.classId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pie_chart, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 24),
              Text(
                'ស្ថិតិថ្នាក់នឹងមកដល់ឆាប់ៗ...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
