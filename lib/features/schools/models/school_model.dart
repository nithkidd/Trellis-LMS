class SchoolModel {
  final String? id;
  final String? organizationId;
  final String name;
  final String? createdAt;
  final int displayOrder;

  SchoolModel({
    this.id,
    this.organizationId,
    required this.name,
    this.createdAt,
    this.displayOrder = 0,
  });

  Map<String, dynamic> toDto() {
    return {
      'organization_id': organizationId,
      'name': name,
      'created_at': createdAt,
      'display_order': displayOrder,
    };
  }

  factory SchoolModel.fromDto(Map<dynamic, dynamic> map, String id) {
    final rawDisplayOrder = map['display_order'];
    return SchoolModel(
      id: id,
      organizationId: map['organization_id']?.toString(),
      name: map['name']?.toString() ?? '',
      createdAt: map['created_at']?.toString(),
      displayOrder: rawDisplayOrder is int
          ? rawDisplayOrder
          : int.tryParse(rawDisplayOrder?.toString() ?? '') ?? 0,
    );
  }

  SchoolModel copyWith({
    String? id,
    String? organizationId,
    String? name,
    String? createdAt,
    int? displayOrder,
  }) {
    return SchoolModel(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }
}
