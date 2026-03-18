import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_user_role.dart';

class AppUserProfile {
  const AppUserProfile({
    required this.uid,
    required this.email,
    required this.role,
    required this.isActive,
    this.displayName,
    this.organizationId,
    this.teacherId,
    this.requestStatus,
    this.signupRequestedAt,
  });

  final String uid;
  final String email;
  final AppUserRole role;
  final bool isActive;
  final String? displayName;
  final String? organizationId;
  final String? teacherId;
  final String? requestStatus;
  final DateTime? signupRequestedAt;

  String get displayLabel {
    final value = displayName?.trim();
    if (value == null || value.isEmpty) {
      return email;
    }
    return value;
  }

  String? get primaryScopeLabel {
    final organization = organizationId?.trim();
    if (organization != null && organization.isNotEmpty) {
      return 'Organization: $organization';
    }

    final teacher = teacherId?.trim();
    if (teacher != null && teacher.isNotEmpty) {
      return 'Teacher: $teacher';
    }

    return null;
  }

  bool get isPendingApproval {
    if (role != AppUserRole.teacher || isActive) {
      return false;
    }

    final normalizedStatus = requestStatus?.trim().toLowerCase();
    if (normalizedStatus == 'declined' || normalizedStatus == 'approved') {
      return false;
    }

    return normalizedStatus == 'pending' ||
        signupRequestedAt != null ||
        (teacherId == null || teacherId!.trim().isEmpty);
  }

  bool get isDeclined {
    return !isActive && requestStatus?.trim().toLowerCase() == 'declined';
  }

  String get accessStateLabel {
    if (isActive) {
      return 'Active';
    }
    if (isDeclined) {
      return 'Declined';
    }
    if (isPendingApproval) {
      return 'Pending approval';
    }
    return 'Inactive';
  }

  factory AppUserProfile.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    final role = AppUserRole.fromValue(data['role']?.toString());

    if (role == null) {
      throw const FormatException(
        'User profile is missing a supported role value.',
      );
    }

    final rawIsActive = data['isActive'];
    final rawRequestedAt = data['signupRequestedAt'];

    return AppUserProfile(
      uid: document.id,
      email: data['email']?.toString().trim() ?? '',
      role: role,
      isActive: rawIsActive is bool
          ? rawIsActive
          : rawIsActive?.toString().trim().toLowerCase() != 'false',
      displayName: data['displayName']?.toString(),
      organizationId: data['organizationId']?.toString(),
      teacherId: data['teacherId']?.toString(),
      requestStatus: data['requestStatus']?.toString(),
      signupRequestedAt: rawRequestedAt is Timestamp
          ? rawRequestedAt.toDate()
          : DateTime.tryParse(rawRequestedAt?.toString() ?? ''),
    );
  }
}
