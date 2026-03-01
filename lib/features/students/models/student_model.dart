class StudentModel {
  final int? id;
  final int classId;
  final String name;
  final String? sex; // 'M' for male, 'F' for female
  final String? dateOfBirth; // ISO 8601 format (yyyy-MM-dd)
  final String? address;
  final String? remarks;

  StudentModel({
    this.id,
    required this.classId,
    required this.name,
    this.sex,
    this.dateOfBirth,
    this.address,
    this.remarks,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'class_id': classId,
      'name': name,
      'sex': sex,
      'date_of_birth': dateOfBirth,
      'address': address,
      'remarks': remarks,
    };
  }

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      id: map['id'] != null ? map['id'] as int : null,
      classId: map['class_id'] as int,
      name: map['name'] ?? '',
      sex: map['sex'] as String?,
      dateOfBirth: map['date_of_birth'] as String?,
      address: map['address'] as String?,
      remarks: map['remarks'] as String?,
    );
  }

  StudentModel copyWith({
    int? id,
    int? classId,
    String? name,
    String? sex,
    String? dateOfBirth,
    String? address,
    String? remarks,
  }) {
    return StudentModel(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      name: name ?? this.name,
      sex: sex ?? this.sex,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      remarks: remarks ?? this.remarks,
    );
  }
}
