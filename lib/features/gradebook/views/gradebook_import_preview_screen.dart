import 'package:flutter/material.dart';
import '../../../core/services/excel_preview_models.dart';
import '../../../core/theme/app_theme.dart';

class GradebookImportPreviewScreen extends StatefulWidget {
  final GradebookImportPreview preview;
  final Future<dynamic> Function(
    List<SubjectImportRow> subjects,
    List<GradebookImportRow> scores,
  )
  onConfirm;

  const GradebookImportPreviewScreen({
    super.key,
    required this.preview,
    required this.onConfirm,
  });

  @override
  State<GradebookImportPreviewScreen> createState() =>
      _GradebookImportPreviewScreenState();
}

class _GradebookImportPreviewScreenState
    extends State<GradebookImportPreviewScreen> {
  late List<SubjectImportRow> _subjects;
  late List<GradebookImportRow> _scores;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _subjects = List.from(widget.preview.subjects);
    _scores = List.from(widget.preview.scores);
  }

  void _toggleSubject(int index) {
    setState(() {
      _subjects[index].shouldImport = !_subjects[index].shouldImport;
    });
  }

  void _toggleScore(int index) {
    setState(() {
      _scores[index].shouldImport = !_scores[index].shouldImport;
    });
  }

  void _editScore(int index) {
    final score = _scores[index];
    final studentController = TextEditingController(text: score.studentName);
    final pointsController = TextEditingController(
      text: score.pointsEarned.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('កែប្រែពិន្ទុ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: studentController,
              decoration: const InputDecoration(labelText: 'ឈ្មោះសិស្ស'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: pointsController,
              decoration: const InputDecoration(labelText: 'ពិន្ទុទទួលបាន'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('បោះបង់'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _scores[index].studentName = studentController.text.trim();
                _scores[index].pointsEarned =
                    double.tryParse(pointsController.text) ??
                    score.pointsEarned;
              });
              Navigator.pop(context);
            },
            child: const Text('រក្សាទុក'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmImport() async {
    setState(() {
      _isImporting = true;
    });

    try {
      final selectedSubjects = _subjects.where((s) => s.shouldImport).toList();
      final selectedScores = _scores.where((s) => s.shouldImport).toList();

      if (selectedSubjects.isEmpty && selectedScores.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('សូមជ្រើសរើសយ៉ាងហោចណាស់មួយធាតុ')),
        );
        return;
      }

      final result = await widget.onConfirm(selectedSubjects, selectedScores);

      if (!mounted) return;
      Navigator.pop(context, result);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('កំហុស៖ $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedSubjectsCount = _subjects.where((s) => s.shouldImport).length;
    final selectedScoresCount = _scores.where((s) => s.shouldImport).length;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Preview Import Gradebook'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'មុខវិជ្ជា'),
              Tab(text: 'ពិន្ទុ'),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: _isImporting ? null : _confirmImport,
              icon: _isImporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(
                'Import (S:$selectedSubjectsCount, Sc:$selectedScoresCount)',
              ),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          ],
        ),
        body: TabBarView(children: [_buildSubjectsTab(), _buildScoresTab()]),
      ),
    );
  }

  Widget _buildSubjectsTab() {
    if (_subjects.isEmpty) {
      return const Center(child: Text('គ្មានមុខវិជ្ជាថ្មី'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      itemCount: _subjects.length,
      itemBuilder: (context, index) {
        final subject = _subjects[index];
        final existsAlready = widget.preview.existingSubjects.contains(
          subject.name.trim().toLowerCase(),
        );

        return Card(
          margin: const EdgeInsets.only(bottom: AppSizes.paddingSm),
          child: ListTile(
            leading: Checkbox(
              value: subject.shouldImport && !existsAlready,
              onChanged: existsAlready ? null : (val) => _toggleSubject(index),
            ),
            title: Text(
              subject.name,
              style: TextStyle(
                decoration: existsAlready ? TextDecoration.lineThrough : null,
                color: existsAlready ? Colors.grey : AppColors.textPrimary,
              ),
            ),
            subtitle: existsAlready
                ? const Text(
                    'មានរួចហើយ',
                    style: TextStyle(color: Colors.orange),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildScoresTab() {
    if (_scores.isEmpty) {
      return const Center(child: Text('គ្មានពិន្ទុ'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      itemCount: _scores.length,
      itemBuilder: (context, index) {
        final score = _scores[index];

        return Card(
          margin: const EdgeInsets.only(bottom: AppSizes.paddingSm),
          child: ListTile(
            leading: Checkbox(
              value: score.shouldImport,
              onChanged: (val) => _toggleScore(index),
            ),
            title: Text(score.studentName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${score.subjectName} • ${score.assignmentName}'),
                Text(
                  'ពិន្ទុ៖ ${score.pointsEarned.toStringAsFixed(1)}/${score.maxPoints.toStringAsFixed(1)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _editScore(index),
            ),
          ),
        );
      },
    );
  }
}
