class SubjectImportRow {
  String name;
  bool shouldImport;

  SubjectImportRow({required this.name, this.shouldImport = true});
}

class GradebookImportRow {
  String studentName;
  String studentRemarks;
  String subjectName;
  String assignmentName;
  String month;
  String year;
  double maxPoints;
  double pointsEarned;
  bool shouldImport;

  GradebookImportRow({
    required this.studentName,
    required this.studentRemarks,
    required this.subjectName,
    required this.assignmentName,
    required this.month,
    required this.year,
    required this.maxPoints,
    required this.pointsEarned,
    this.shouldImport = true,
  });
}

class SubjectImportPreview {
  final List<SubjectImportRow> rows;
  final List<String> existingNames;

  SubjectImportPreview({required this.rows, required this.existingNames});
}

class GradebookImportPreview {
  final List<SubjectImportRow> subjects;
  final List<String> existingSubjects;
  final List<GradebookImportRow> scores;

  GradebookImportPreview({
    required this.subjects,
    required this.existingSubjects,
    required this.scores,
  });
}
