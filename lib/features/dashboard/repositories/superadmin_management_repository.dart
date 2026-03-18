import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/auth/models/app_user_profile.dart';
import '../../../core/auth/services/auth_service.dart';
import '../../../core/utils/khmer_collator.dart';
import '../../schools/models/school_model.dart';
import '../../schools/repositories/school_repository.dart';
import '../../teachers/models/teacher_model.dart';
import '../../teachers/repositories/teacher_repository.dart';
import '../models/superadmin_management_models.dart';

class SuperadminManagementRepository {
  SuperadminManagementRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _schoolRepository = SchoolRepository(),
      _teacherRepository = TeacherRepository();

  static const String organizationsCollection = 'organizations';
  static const Duration _firestoreReadTimeout = Duration(seconds: 12);
  static const Duration _localReadTimeout = Duration(seconds: 6);

  final FirebaseFirestore _firestore;
  final SchoolRepository _schoolRepository;
  final TeacherRepository _teacherRepository;

  Future<List<ManagedOrganization>> loadOrganizations() async {
    final snapshot = await _firestore
        .collection(organizationsCollection)
        .get()
        .timeout(_firestoreReadTimeout);
    final organizations = snapshot.docs
        .map((doc) => ManagedOrganization.fromMap(doc.id, doc.data()))
        .toList(growable: false);
    organizations.sort((a, b) => a.name.compareTo(b.name));
    return organizations;
  }

  Future<void> createOrganization({
    required String id,
    required String name,
  }) async {
    await _firestore.collection(organizationsCollection).doc(id.trim()).set({
      'name': name.trim(),
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateOrganization({
    required String id,
    required String name,
    required bool isActive,
  }) async {
    await _firestore.collection(organizationsCollection).doc(id.trim()).set({
      'name': name.trim(),
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteOrganization(String id) async {
    await _firestore.collection(organizationsCollection).doc(id).delete();
  }

  Future<List<SchoolModel>> loadSchools() async {
    final schools = await _schoolRepository.getAll().timeout(_localReadTimeout);
    KhmerCollator.sortBy(schools, (school) => school.name);
    return schools;
  }

  Future<void> createSchool({
    required String organizationId,
    required String name,
  }) async {
    await _schoolRepository.insert(
      SchoolModel(
        organizationId: organizationId.trim(),
        name: name.trim(),
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  Future<void> updateSchool({
    required String id,
    required String organizationId,
    required String name,
  }) async {
    final existing = await _schoolRepository.getById(id);
    if (existing == null) {
      return;
    }

    await _schoolRepository.update(
      existing.copyWith(
        organizationId: organizationId.trim(),
        name: name.trim(),
      ),
    );
  }

  Future<void> deleteSchool(String id) async {
    await _schoolRepository.delete(id);
  }

  Future<List<AppUserProfile>> loadUserProfiles() async {
    final snapshot = await _firestore
        .collection(AuthService.userProfilesCollection)
        .get()
        .timeout(_firestoreReadTimeout);

    final profiles = <AppUserProfile>[];
    for (final doc in snapshot.docs) {
      try {
        profiles.add(AppUserProfile.fromDocument(doc));
      } catch (_) {
        // Ignore malformed docs in the CRUD list; the dashboard summary still flags them.
      }
    }

    profiles.sort((a, b) => a.displayLabel.compareTo(b.displayLabel));
    return profiles;
  }

  Future<void> upsertUserProfile(ManagedUserProfileInput input) async {
    final data = <String, Object?>{
      'email': input.email.trim(),
      'displayName': input.displayName.trim(),
      'role': input.roleValue,
      'isActive': input.isActive,
      'organizationId': _normalizeNullable(input.organizationId),
      'schoolId': FieldValue.delete(),
      'teacherId': _normalizeNullable(input.teacherId),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final normalizedRequestStatus = _normalizeNullable(input.requestStatus);
    if (normalizedRequestStatus != null) {
      data['requestStatus'] = normalizedRequestStatus;
    } else if (input.isActive) {
      data['requestStatus'] = 'approved';
    }

    await _firestore
        .collection(AuthService.userProfilesCollection)
        .doc(input.uid.trim())
        .set(data, SetOptions(merge: true));
  }

  Future<void> deleteUserProfile(String uid) async {
    await _firestore
        .collection(AuthService.userProfilesCollection)
        .doc(uid)
        .delete();
  }

  Future<void> approveTeacherRequest({
    required String uid,
    required String teacherId,
  }) async {
    await _firestore
        .collection(AuthService.userProfilesCollection)
        .doc(uid.trim())
        .set({
          'isActive': true,
          'teacherId': teacherId.trim(),
          'requestStatus': 'approved',
          'approvedAt': FieldValue.serverTimestamp(),
          'reviewedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> declineTeacherRequest(String uid) async {
    await _firestore
        .collection(AuthService.userProfilesCollection)
        .doc(uid.trim())
        .set({
          'isActive': false,
          'requestStatus': 'declined',
          'declinedAt': FieldValue.serverTimestamp(),
          'reviewedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<List<TeacherModel>> loadTeachers() async {
    final teachers = await _teacherRepository.getAll().timeout(
      _localReadTimeout,
    );
    KhmerCollator.sortBy(teachers, (teacher) => teacher.name);
    return teachers;
  }

  Future<void> createTeacher({
    required String schoolId,
    required String name,
  }) async {
    await _teacherRepository.insert(
      TeacherModel(
        schoolId: schoolId.trim(),
        name: name.trim(),
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  Future<void> updateTeacher({
    required String id,
    required String schoolId,
    required String name,
  }) async {
    final existing = await _teacherRepository.getById(id);
    if (existing == null) {
      return;
    }

    await _teacherRepository.update(
      existing.copyWith(schoolId: schoolId.trim(), name: name.trim()),
    );
  }

  Future<void> deleteTeacher(String id) async {
    await _teacherRepository.delete(id);
  }

  Future<SuperadminDirectoryLookups> loadDirectoryLookups() async {
    final organizations = await loadOrganizations();
    final schools = await loadSchools();
    final teachers = await loadTeachers();

    return SuperadminDirectoryLookups(
      organizations: organizations,
      schools: schools,
      teachers: teachers,
    );
  }

  String? _normalizeNullable(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
