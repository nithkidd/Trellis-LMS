import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/models/app_user_role.dart';
import '../../../core/auth/models/app_user_profile.dart';
import '../../schools/models/school_model.dart';
import '../../teachers/models/teacher_model.dart';
import '../models/superadmin_management_models.dart';
import 'dashboard_providers.dart';
import '../repositories/superadmin_management_repository.dart';

final superadminManagementRepositoryProvider =
    Provider<SuperadminManagementRepository>((ref) {
      return SuperadminManagementRepository();
    });

class SuperadminOrganizationsNotifier
    extends AsyncNotifier<List<ManagedOrganization>> {
  @override
  FutureOr<List<ManagedOrganization>> build() async {
    return _load();
  }

  Future<List<ManagedOrganization>> _load() {
    return ref.read(superadminManagementRepositoryProvider).loadOrganizations();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> createOrganization({
    required String id,
    required String name,
  }) async {
    await ref
        .read(superadminManagementRepositoryProvider)
        .createOrganization(id: id, name: name);
    await refresh();
    ref.invalidate(superadminDirectoryLookupsProvider);
  }

  Future<void> updateOrganization({
    required String id,
    required String name,
    required bool isActive,
  }) async {
    await ref
        .read(superadminManagementRepositoryProvider)
        .updateOrganization(id: id, name: name, isActive: isActive);
    await refresh();
    ref.invalidate(superadminDirectoryLookupsProvider);
  }

  Future<void> deleteOrganization(String id) async {
    await ref
        .read(superadminManagementRepositoryProvider)
        .deleteOrganization(id);
    await refresh();
    ref.invalidate(superadminDirectoryLookupsProvider);
  }
}

final superadminOrganizationsProvider =
    AsyncNotifierProvider<
      SuperadminOrganizationsNotifier,
      List<ManagedOrganization>
    >(SuperadminOrganizationsNotifier.new);

class SuperadminSchoolsNotifier extends AsyncNotifier<List<SchoolModel>> {
  @override
  FutureOr<List<SchoolModel>> build() async {
    return _load();
  }

  Future<List<SchoolModel>> _load() {
    return ref.read(superadminManagementRepositoryProvider).loadSchools();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> createSchool({
    required String organizationId,
    required String name,
  }) async {
    await ref
        .read(superadminManagementRepositoryProvider)
        .createSchool(organizationId: organizationId, name: name);
    await refresh();
    ref.invalidate(superadminDirectoryLookupsProvider);
    ref.invalidate(superadminDashboardSummaryProvider);
  }

  Future<void> updateSchool({
    required String id,
    required String organizationId,
    required String name,
  }) async {
    await ref
        .read(superadminManagementRepositoryProvider)
        .updateSchool(id: id, organizationId: organizationId, name: name);
    await refresh();
    ref.invalidate(superadminDirectoryLookupsProvider);
    ref.invalidate(superadminDashboardSummaryProvider);
  }

  Future<void> deleteSchool(String id) async {
    await ref.read(superadminManagementRepositoryProvider).deleteSchool(id);
    await refresh();
    ref.invalidate(superadminDirectoryLookupsProvider);
    ref.invalidate(superadminDashboardSummaryProvider);
  }
}

final superadminSchoolsProvider =
    AsyncNotifierProvider<SuperadminSchoolsNotifier, List<SchoolModel>>(
      SuperadminSchoolsNotifier.new,
    );

class SuperadminUserProfilesNotifier
    extends AsyncNotifier<List<AppUserProfile>> {
  @override
  FutureOr<List<AppUserProfile>> build() async {
    return _load();
  }

  Future<List<AppUserProfile>> _load() {
    return ref.read(superadminManagementRepositoryProvider).loadUserProfiles();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> upsertUserProfile(ManagedUserProfileInput input) async {
    await ref
        .read(superadminManagementRepositoryProvider)
        .upsertUserProfile(input);
    await refresh();
    ref.invalidate(superadminDashboardSummaryProvider);
  }

  Future<void> deleteUserProfile(String uid) async {
    await ref
        .read(superadminManagementRepositoryProvider)
        .deleteUserProfile(uid);
    await refresh();
    ref.invalidate(superadminDashboardSummaryProvider);
  }

  Future<void> approveTeacherRequest({
    required String uid,
    required String teacherId,
  }) async {
    await ref
        .read(superadminManagementRepositoryProvider)
        .approveTeacherRequest(uid: uid, teacherId: teacherId);
    await refresh();
    ref.invalidate(superadminDashboardSummaryProvider);
  }

  Future<void> declineTeacherRequest(String uid) async {
    await ref
        .read(superadminManagementRepositoryProvider)
        .declineTeacherRequest(uid);
    await refresh();
    ref.invalidate(superadminDashboardSummaryProvider);
  }
}

final superadminUserProfilesProvider =
    AsyncNotifierProvider<SuperadminUserProfilesNotifier, List<AppUserProfile>>(
      SuperadminUserProfilesNotifier.new,
    );

class SuperadminTeachersNotifier extends AsyncNotifier<List<TeacherModel>> {
  @override
  FutureOr<List<TeacherModel>> build() async {
    return _load();
  }

  Future<List<TeacherModel>> _load() {
    return ref.read(superadminManagementRepositoryProvider).loadTeachers();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> createTeacher({
    required String schoolId,
    required String name,
  }) async {
    await ref
        .read(superadminManagementRepositoryProvider)
        .createTeacher(schoolId: schoolId, name: name);
    await refresh();
    ref.invalidate(superadminDirectoryLookupsProvider);
    ref.invalidate(superadminDashboardSummaryProvider);
  }

  Future<void> updateTeacher({
    required String id,
    required String schoolId,
    required String name,
  }) async {
    await ref
        .read(superadminManagementRepositoryProvider)
        .updateTeacher(id: id, schoolId: schoolId, name: name);
    await refresh();
    ref.invalidate(superadminDirectoryLookupsProvider);
    ref.invalidate(superadminDashboardSummaryProvider);
  }

  Future<void> deleteTeacher(String id) async {
    await ref.read(superadminManagementRepositoryProvider).deleteTeacher(id);
    await refresh();
    ref.invalidate(superadminDirectoryLookupsProvider);
    ref.invalidate(superadminDashboardSummaryProvider);
  }
}

final superadminTeachersProvider =
    AsyncNotifierProvider<SuperadminTeachersNotifier, List<TeacherModel>>(
      SuperadminTeachersNotifier.new,
    );

final superadminDirectoryLookupsProvider =
    FutureProvider<SuperadminDirectoryLookups>((ref) async {
      return ref
          .read(superadminManagementRepositoryProvider)
          .loadDirectoryLookups();
    });

final superadminTeacherProfilesProvider =
    Provider<AsyncValue<List<AppUserProfile>>>((ref) {
      final profiles = ref.watch(superadminUserProfilesProvider);
      return profiles.whenData(
        (items) => items
            .where((profile) => profile.role == AppUserRole.teacher)
            .toList(growable: false),
      );
    });

final superadminPendingTeacherRequestsProvider =
    Provider<AsyncValue<List<AppUserProfile>>>((ref) {
      final profiles = ref.watch(superadminUserProfilesProvider);
      return profiles.whenData(
        (items) => items
            .where((profile) => profile.isPendingApproval)
            .toList(growable: false),
      );
    });

final superadminAdminProfilesProvider =
    Provider<AsyncValue<List<AppUserProfile>>>((ref) {
      final profiles = ref.watch(superadminUserProfilesProvider);
      return profiles.whenData(
        (items) => items
            .where((profile) => profile.role == AppUserRole.organizationAdmin)
            .toList(growable: false),
      );
    });
