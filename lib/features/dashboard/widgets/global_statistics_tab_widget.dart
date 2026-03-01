import 'package:flutter/material.dart';

class GlobalStatisticsTabWidget extends StatelessWidget {
  const GlobalStatisticsTabWidget({Key? key}) : super(key: key);

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
              Icon(Icons.bar_chart, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 24),
              Text(
                'Global Statistics coming soon...',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
