class SubjectModel {
  final int? id;
  final int classId;
  final String name;

  SubjectModel({
    this.id,
    required this.classId,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'class_id': classId,
      'name': name,
    };
  }

  factory SubjectModel.fromMap(Map<String, dynamic> map) {
    return SubjectModel(
      id: map['id'] != null ? map['id'] as int : null,
      classId: map['class_id'] as int,
      name: map['name'] ?? '',
    );
  }

  SubjectModel copyWith({
    int? id,
    int? classId,
    String? name,
  }) {
    return SubjectModel(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      name: name ?? this.name,
    );
  }
}
