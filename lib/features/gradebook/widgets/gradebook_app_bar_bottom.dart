import 'package:flutter/material.dart';

const Map<String, String> kMonthLabels = {
  'Jan': 'មករា',
  'Feb': 'កុម្ភៈ',
  'Mar': 'មីនា',
  'Apr': 'មេសា',
  'May': 'ឧសភា',
  'Jun': 'មិថុនា',
  'Jul': 'កក្កដា',
  'Aug': 'សីហា',
  'Sep': 'កញ្ញា',
  'Oct': 'តុលា',
  'Nov': 'វិច្ឆិកា',
  'Dec': 'ធ្នូ',
};

class GradebookAppBarBottom extends StatelessWidget
    implements PreferredSizeWidget {
  final String month;
  final String year;
  final double maxPoints;

  const GradebookAppBarBottom({
    super.key,
    required this.month,
    required this.year,
    required this.maxPoints,
  });

  @override
  Size get preferredSize => const Size.fromHeight(40);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        'ពិន្ទុអតិបរមា៖ ${maxPoints.toInt()} • ${kMonthLabels[month] ?? month} $year',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
