class TeacherModel {
  final int? id;
  final int schoolId;
  final String name;
  final String? createdAt;

  TeacherModel({
    this.id,
    required this.schoolId,
    required this.name,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'school_id': schoolId,
      'name': name,
      'created_at': createdAt,
    };
  }

  factory TeacherModel.fromMap(Map<String, dynamic> map) {
    return TeacherModel(
      id: map['id'] != null ? map['id'] as int : null,
      schoolId: map['school_id'] as int,
      name: map['name'] ?? '',
      createdAt: map['created_at'] as String?,
    );
  }

  TeacherModel copyWith({
    int? id,
    int? schoolId,
    String? name,
    String? createdAt,
  }) {
    return TeacherModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeacherModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ schoolId.hashCode ^ name.hashCode;

  @override
  String toString() =>
      'TeacherModel(id: $id, schoolId: $schoolId, name: $name)';
}
