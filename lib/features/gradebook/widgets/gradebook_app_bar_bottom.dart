import 'package:flutter/material.dart';

class GradebookAppBarBottom extends StatelessWidget implements PreferredSizeWidget {
  final String month;
  final String year;
  final double maxPoints;

  const GradebookAppBarBottom({
    Key? key,
    required this.month,
    required this.year,
    required this.maxPoints,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(40);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        'Max Points: ${maxPoints.toInt()} • $month $year',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
