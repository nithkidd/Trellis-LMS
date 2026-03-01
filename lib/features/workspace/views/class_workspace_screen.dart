import 'package:flutter/material.dart';
import '../../students/widgets/roster_tab_widget.dart';
import '../../subjects/widgets/subjects_tab_widget.dart';
import '../../assignments/widgets/assignments_tab_widget.dart';
import '../../gradebook/views/gradebook_main_tab_widget.dart';
import '../widgets/workspace_bottom_nav_bar.dart';

class ClassWorkspaceScreen extends StatefulWidget {
  final int classId;
  final String className;

  const ClassWorkspaceScreen({
    Key? key,
    required this.classId,
    required this.className,
  }) : super(key: key);

  @override
  State<ClassWorkspaceScreen> createState() => _ClassWorkspaceScreenState();
}

class _ClassWorkspaceScreenState extends State<ClassWorkspaceScreen> {
  int _currentIndex = 0;

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    // Initialize the tab views once
    _tabs = [
      RosterTabWidget(classId: widget.classId),
      SubjectsTabWidget(classId: widget.classId),
      AssignmentsTabWidget(classId: widget.classId),
      GradebookMainTabWidget(classId: widget.classId),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.className, style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 1,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: WorkspaceBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
