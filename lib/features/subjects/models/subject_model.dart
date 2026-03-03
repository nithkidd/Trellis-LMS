class SubjectModel {
  final int? id;
  final int classId;
  final String name;
  final int? displayOrder;

  SubjectModel({
    this.id,
    required this.classId,
    required this.name,
    this.displayOrder,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'class_id': classId,
      'name': name,
      'display_order': displayOrder,
    };
  }

  factory SubjectModel.fromMap(Map<String, dynamic> map) {
    return SubjectModel(
      id: map['id'] != null ? map['id'] as int : null,
      classId: map['class_id'] as int,
      name: map['name'] ?? '',
      displayOrder: map['display_order'] as int?,
    );
  }

  SubjectModel copyWith({
    int? id,
    int? classId,
    String? name,
    int? displayOrder,
  }) {
    return SubjectModel(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      name: name ?? this.name,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }
}
