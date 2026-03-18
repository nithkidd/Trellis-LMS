import '../../schools/models/school_model.dart';
import '../../teachers/models/teacher_model.dart';

class ManagedOrganization {
  const ManagedOrganization({
    required this.id,
    required this.name,
    this.isActive = true,
  });

  final String id;
  final String name;
  final bool isActive;

  factory ManagedOrganization.fromMap(String id, Map<String, dynamic> map) {
    final rawIsActive = map['isActive'];
    return ManagedOrganization(
      id: id,
      name: map['name']?.toString().trim().isNotEmpty == true
          ? map['name'].toString().trim()
          : id,
      isActive: rawIsActive is bool
          ? rawIsActive
          : rawIsActive?.toString().trim().toLowerCase() != 'false',
    );
  }
}

class ManagedUserProfileInput {
  const ManagedUserProfileInput({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.roleValue,
    required this.isActive,
    this.organizationId,
    this.teacherId,
    this.requestStatus,
  });

  final String uid;
  final String email;
  final String displayName;
  final String roleValue;
  final bool isActive;
  final String? organizationId;
  final String? teacherId;
  final String? requestStatus;
}

class SuperadminDirectoryLookups {
  const SuperadminDirectoryLookups({
    required this.organizations,
    required this.schools,
    required this.teachers,
  });

  final List<ManagedOrganization> organizations;
  final List<SchoolModel> schools;
  final List<TeacherModel> teachers;
}
