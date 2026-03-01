class SchoolModel {
  final int? id;
  final String name;
  final String? createdAt;
  final int displayOrder;

  SchoolModel({
    this.id,
    required this.name,
    this.createdAt,
    this.displayOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt,
      'display_order': displayOrder,
    };
  }

  factory SchoolModel.fromMap(Map<String, dynamic> map) {
    return SchoolModel(
      id: map['id'] != null ? map['id'] as int : null,
      name: map['name'] ?? '',
      createdAt: map['created_at'] as String?,
      displayOrder: map['display_order'] as int? ?? 0,
    );
  }

  SchoolModel copyWith({
    int? id,
    String? name,
    String? createdAt,
    int? displayOrder,
  }) {
    return SchoolModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }
}
