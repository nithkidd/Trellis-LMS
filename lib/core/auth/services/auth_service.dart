import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_auth_session.dart';
import '../models/app_user_profile.dart';
import '../models/app_user_role.dart';
import '../models/eligible_organization.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  static const Duration _firestoreReadTimeout = Duration(seconds: 12);

  // Expected document shape:
  // user_profiles/{uid} => { email, displayName, role, isActive, organizationId?, teacherId? }
  static const String userProfilesCollection = 'user_profiles';
  static const String organizationsCollection = 'organizations';

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.getIdToken(true);
    return credential;
  }

  Future<List<EligibleOrganization>> loadEligibleOrganizations() async {
    final snapshot = await _firestore
        .collection(organizationsCollection)
        .where('isActive', isEqualTo: true)
        .get()
        .timeout(_firestoreReadTimeout);

    final organizations =
        snapshot.docs
            .map(
              (document) =>
                  EligibleOrganization.fromMap(document.id, document.data()),
            )
            .toList(growable: false)
          ..sort((a, b) => a.name.compareTo(b.name));

    return organizations;
  }

  Future<void> signUpTeacherRequest({
    required String displayName,
    required String email,
    required String password,
    required String organizationId,
  }) async {
    UserCredential? credential;

    try {
      credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw StateError('Unable to create the account right now.');
      }

      await user.updateDisplayName(displayName.trim());

      await _firestore.collection(userProfilesCollection).doc(user.uid).set({
        'email': email.trim(),
        'displayName': displayName.trim(),
        'role': AppUserRole.teacher.storageValue,
        'isActive': false,
        'organizationId': organizationId.trim(),
        'teacherId': null,
        'requestStatus': 'pending',
        'signupRequestedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      await user.getIdToken(true);
    } catch (error) {
      final createdUser = credential?.user;
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {
          // Ignore rollback failure; the original error is still the important one.
        }
      }
      rethrow;
    }
  }

  Future<void> signOut() => _firebaseAuth.signOut();

  Future<AppUserProfile?> loadUserProfile(String uid) async {
    if (_firebaseAuth.currentUser?.uid == uid) {
      await _firebaseAuth.currentUser?.getIdToken(true);
    }

    final document = await _firestore
        .collection(userProfilesCollection)
        .doc(uid)
        .get()
        .timeout(_firestoreReadTimeout);

    if (!document.exists) {
      return null;
    }

    return AppUserProfile.fromDocument(document);
  }

  Future<AppAuthSession?> loadCurrentSession() async {
    final user = currentUser;
    if (user == null) {
      return null;
    }

    final profile = await loadUserProfile(user.uid);
    if (profile == null) {
      return null;
    }

    return AppAuthSession(user: user, profile: profile);
  }
}
