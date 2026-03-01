import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/student_model.dart';
import '../providers/student_provider.dart';
import '../widgets/student_form_dialog.dart';
import 'student_profile_screen.dart';
import '../../../core/theme/app_theme.dart';

class StudentDetailsScreen extends ConsumerWidget {
  final StudentModel student;

  const StudentDetailsScreen({Key? key, required this.student})
    : super(key: key);

  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return 'មិនទាន់កំណត់';

    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return 'មិនទាន់កំណត់';
    }
  }

  String _calculateAge(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '';

    try {
      final birthDate = DateTime.parse(isoDate);
      final today = DateTime.now();
      int age = today.year - birthDate.year;

      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }

      return ' ($age ឆ្នាំ)';
    } catch (e) {
      return '';
    }
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) =>
          StudentFormDialog(student: student, classId: student.classId),
    );

    if (result != null && student.id != null && context.mounted) {
      ref
          .read(studentNotifierProvider.notifier)
          .updateStudent(
            student.copyWith(
              name: result['name'] as String,
              sex: result['sex'] as String?,
              dateOfBirth: result['dateOfBirth'] as String?,
              address: result['address'] as String?,
              remarks: result['remarks'] as String?,
            ),
          );
    }
  }

  void _navigateToScores(BuildContext context) {
    if (student.id != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => StudentProfileScreen(
            studentId: student.id!,
            studentName: student.name,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ព័ត៌មានសិស្ស'),
        actions: [
          IconButton(
            icon: const Icon(Icons.assessment_outlined),
            tooltip: 'មើលពិន្ទុ',
            onPressed: () => _navigateToScores(context),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'កែប្រែ',
            onPressed: () => _showEditDialog(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with Avatar and Name
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Text(
                      student.name.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    student.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Personal Information Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ព័ត៌មានផ្ទាល់ខ្លួន',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Sex
                  _buildInfoCard(
                    context,
                    icon: Icons.person_outline,
                    label: 'ភេទ',
                    value: student.sex == 'M'
                        ? 'ប្រុស (Male)'
                        : student.sex == 'F'
                        ? 'ស្រី (Female)'
                        : 'មិនទាន់កំណត់',
                  ),
                  const SizedBox(height: 12),

                  // Date of Birth
                  _buildInfoCard(
                    context,
                    icon: Icons.cake_outlined,
                    label: 'ថ្ងៃខែឆ្នាំកំណើត',
                    value:
                        _formatDate(student.dateOfBirth) +
                        _calculateAge(student.dateOfBirth),
                  ),
                  const SizedBox(height: 12),

                  // Address
                  _buildInfoCard(
                    context,
                    icon: Icons.location_on_outlined,
                    label: 'អាសយដ្ឋាន',
                    value: student.address ?? 'មិនទាន់កំណត់',
                  ),
                  const SizedBox(height: 12),

                  // Remarks
                  if (student.remarks != null && student.remarks!.isNotEmpty)
                    _buildInfoCard(
                      context,
                      icon: Icons.note_outlined,
                      label: 'កំណត់សម្គាល់',
                      value: student.remarks!,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
