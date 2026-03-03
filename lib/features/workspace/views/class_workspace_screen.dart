import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/excel_transfer_service.dart';
import '../../assignments/providers/assignment_provider.dart';
import '../../gradebook/providers/score_provider.dart';
import '../../gradebook/services/grade_calculation_service.dart';
import '../../gradebook/views/gradebook_import_preview_screen.dart';
import '../../students/providers/student_provider.dart';
import '../../subjects/providers/subject_provider.dart';
import '../../subjects/views/subject_import_preview_screen.dart';
import '../../students/widgets/roster_tab_widget.dart';
import '../../subjects/widgets/subjects_tab_widget.dart';
import '../../assignments/widgets/assignments_tab_widget.dart';
import '../../assignments/widgets/assignments_tab_widget_with_permissions.dart';
import '../../gradebook/views/gradebook_main_tab_widget.dart';
import '../widgets/workspace_bottom_nav_bar.dart';

class ClassWorkspaceScreen extends ConsumerStatefulWidget {
  final int classId;
  final String className;
  final bool isAdviser;
  final int? teacherId; // null = admin view, non-null = teacher view

  const ClassWorkspaceScreen({
    super.key,
    required this.classId,
    required this.className,
    this.isAdviser = false,
    this.teacherId,
  });

  @override
  ConsumerState<ClassWorkspaceScreen> createState() =>
      _ClassWorkspaceScreenState();
}

class _ClassWorkspaceScreenState extends ConsumerState<ClassWorkspaceScreen> {
  int _currentIndex = 0;
  final ExcelTransferService _excelTransferService = ExcelTransferService();
  final _rosterKey = GlobalKey<RosterTabWidgetState>();

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    // Always show all tabs: Roster, Subjects, Assignments, and Gradebook
    _tabs = [
      RosterTabWidget(key: _rosterKey, classId: widget.classId),
      SubjectsTabWidget(classId: widget.classId),
      // Use permission-aware widget if teacherId is provided, otherwise use regular widget
      widget.teacherId != null
          ? AssignmentsTabWidgetWithPermissions(
              classId: widget.classId,
              teacherId: widget.teacherId,
              isAdviser: widget.isAdviser,
            )
          : AssignmentsTabWidget(classId: widget.classId),
      GradebookMainTabWidget(
        classId: widget.classId,
        teacherId: widget.teacherId,
        isAdviser: widget.isAdviser,
      ),
    ];
  }

  Future<void> _reloadSubjects() async {
    await ref
        .read(subjectNotifierProvider.notifier)
        .loadSubjectsForClass(widget.classId);
  }

  Future<void> _reloadGradebookData() async {
    await _reloadSubjects();
    await ref
        .read(assignmentNotifierProvider.notifier)
        .loadAssignmentsForClass(widget.classId);
    await ref
        .read(studentNotifierProvider.notifier)
        .loadStudentsForClass(widget.classId);
    ref.invalidate(scoreNotifierProvider);
    ref.invalidate(gradeCalculationProvider(widget.classId));
  }

  Future<void> _handleExcelAction(String action) async {
    try {
      if (action == 'subjects_sync_adviser') {
        final inserted = await ref
            .read(subjectNotifierProvider.notifier)
            .syncMissingAdviserSubjects(widget.classId);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              inserted > 0
                  ? 'បានបន្ថែមមុខវិជ្ជាខ្វះចំនួន $inserted'
                  : 'មុខវិជ្ជាគ្រប់គ្រាន់រួចហើយ',
            ),
          ),
        );
        return;
      }

      if (action == 'subjects_export') {
        final result = await _excelTransferService.exportSubjects(
          classId: widget.classId,
          className: widget.className,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'បាន Export មុខវិជ្ជា ${result['count']} ធាតុជា Excel',
            ),
          ),
        );
        return;
      }

      if (action == 'subjects_import') {
        final preview = await _excelTransferService.previewSubjectsImport(
          classId: widget.classId,
        );

        if (!mounted) return;
        final count = await Navigator.push<int>(
          context,
          MaterialPageRoute(
            builder: (context) => SubjectImportPreviewScreen(
              preview: preview,
              onConfirm: (rows) =>
                  _excelTransferService.importSubjectsFromPreview(
                    classId: widget.classId,
                    rows: rows,
                  ),
            ),
          ),
        );

        if (count != null && count > 0) {
          await _reloadSubjects();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('បាន Import មុខវិជ្ជា $count ធាតុ')),
          );
        }
        return;
      }

      if (action == 'gradebook_export') {
        final result = await _excelTransferService.exportGradebook(
          classId: widget.classId,
          className: widget.className,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'បាន Export: ${result['subjects']} Subjects, ${result['assignments']} Assignments, ${result['scores']} Scores',
            ),
          ),
        );
        return;
      }

      if (action == 'gradebook_import') {
        final preview = await _excelTransferService.previewGradebookImport(
          classId: widget.classId,
        );

        if (!mounted) return;
        final summary = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GradebookImportPreviewScreen(
              preview: preview,
              onConfirm: (subjects, scores) =>
                  _excelTransferService.importGradebookFromPreview(
                    classId: widget.classId,
                    subjects: subjects,
                    scores: scores,
                  ),
            ),
          ),
        );

        if (summary != null) {
          await _reloadGradebookData();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'បាន Import: Subjects ${summary.createdSubjects}, Assignments ${summary.createdAssignments}, Students ${summary.createdStudents}, Scores ${summary.upsertedScores}',
              ),
            ),
          );
        }
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ប្រតិបត្តិការបរាជ័យ៖ $error'),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  List<PopupMenuEntry<String>> _buildActionMenuItems() {
    // Tab indices are always: 0=Roster, 1=Subjects, 2=Assignments, 3=Gradebook
    if (_currentIndex == 1) {
      return [
        if (widget.isAdviser)
          const PopupMenuItem<String>(
            value: 'subjects_sync_adviser',
            child: Text('Sync Adviser Subjects (Auto-create missing)'),
          ),
        const PopupMenuItem<String>(
          value: 'subjects_export',
          child: Text('Export Subjects (Excel)'),
        ),
        const PopupMenuItem<String>(
          value: 'subjects_import',
          child: Text('Import Subjects (Excel)'),
        ),
      ];
    }

    if (_currentIndex == 3) {
      return const [
        PopupMenuItem<String>(
          value: 'gradebook_export',
          child: Text('Export Gradebook (Excel)'),
        ),
        PopupMenuItem<String>(
          value: 'gradebook_import',
          child: Text('Import Gradebook (Excel)'),
        ),
      ];
    }

    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final actionItems = _buildActionMenuItems();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.className,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: actionItems.isEmpty
            ? null
            : [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: _handleExcelAction,
                  itemBuilder: (context) => actionItems,
                ),
              ],
        elevation: 1,
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => _rosterKey.currentState?.showAddStudentDialog(),
              tooltip: 'បន្ថែមសិស្ស',
              child: const Icon(Icons.add),
            )
          : null,
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: WorkspaceBottomNavBar(
        currentIndex: _currentIndex,
        isAdviser: widget.isAdviser,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
