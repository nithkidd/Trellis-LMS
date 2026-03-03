import 'dart:async';
import 'package:flutter/material.dart';
import '../../students/models/student_model.dart';
import '../models/score_model.dart';
import '../../assignments/models/assignment_model.dart';
import '../../../core/theme/app_theme.dart';

class GradebookStudentRow extends StatefulWidget {
  final StudentModel student;
  final ScoreModel? score;
  final TextEditingController controller;
  final AssignmentModel assignment;
  final void Function(int studentId, int assignmentId, double points) onSave;

  const GradebookStudentRow({
    super.key,
    required this.student,
    required this.score,
    required this.controller,
    required this.assignment,
    required this.onSave,
  });

  @override
  State<GradebookStudentRow> createState() => _GradebookStudentRowState();
}

class _GradebookStudentRowState extends State<GradebookStudentRow> {
  Timer? _debounce;
  bool _isSaving = false;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _trySave(value);
    });
  }

  void _trySave(String value) {
    final input = value.trim();
    if (input.isEmpty) return;
    final points = double.tryParse(input);
    if (points == null) return;
    if (widget.assignment.id == null || widget.student.id == null) return;

    setState(() => _isSaving = true);
    widget.onSave(widget.student.id!, widget.assignment.id!, points);

    // Brief visual feedback that it saved
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _isSaving = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSavedScore = widget.score != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              widget.student.name[0].toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Text(widget.student.name, style: AppTextStyles.subheading),
          ),
          // Saving indicator
          AnimatedOpacity(
            opacity: _isSaving ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 18,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: TextField(
              controller: widget.controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: '---',
                filled: true,
                fillColor: hasSavedScore
                    ? AppColors.success.withValues(alpha: 0.06)
                    : AppColors.background,
                suffixText: '/ ${widget.assignment.maxPoints.toInt()}',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  borderSide: BorderSide(
                    color: hasSavedScore ? AppColors.success : AppColors.border,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  borderSide: BorderSide(
                    color: hasSavedScore ? AppColors.success : AppColors.border,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
