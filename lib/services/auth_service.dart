// lib/services/auth_service.dart
// Talks to Firebase Authentication and the Firestore "users" collection.
// This is the ONLY file that does so; screens and providers never call
// Firebase Auth directly.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import '../models/enums.dart';
import '../utils/constants.dart';

/// A readable error that can be shown directly to the user.
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// Shortcut to the users collection.
  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestorePaths.users);

  /// Emits the signed-in Firebase user, or null when signed out.
  /// Fires on app start too, which restores a previous session.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Creates the account, then saves the profile in Firestore.
  /// Every new account is a student; staff are promoted in the console.
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = AppUser(
        uid: credential.user!.uid,
        name: name.trim(),
        email: email.trim(),
        role: UserRole.student,
        createdAt: DateTime.now(),
      );

      // The document id equals the Authentication uid.
      await _users.doc(user.uid).set(user.toMap());
      try {
        await credential.user!.sendEmailVerification();
      } catch (_) {}

      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e));
    } on FirebaseException catch (e) {
      throw AuthFailure('Could not save your profile: ${e.message}');
    }
  }

  /// Signs in and returns the user's profile (including role).
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final profile = await fetchProfile(credential.user!.uid);
      if (profile == null) {
        // Signed in but no profile document: treat as a failed login.
        await _auth.signOut();
        throw const AuthFailure('Account profile not found.');
      }
      return profile;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e));
    }
  }

  Future<void> logout() => _auth.signOut();

  /// True when the signed-in account has confirmed its email address.
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  /// Sends (or re-sends) the verification email to the signed-in user.
  Future<void> sendVerificationEmail() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e));
    }
  }

  /// Verification happens in the user's inbox, outside the app, so we must
  /// re-read the account from Firebase to learn about it.
  Future<bool> refreshVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }
  /// Reads users/{uid}. Returns null if the document does not exist.
  Future<AppUser?> fetchProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return AppUser.fromMap(doc.id, data);
  }

  /// Converts Firebase's technical error codes into friendly messages.
  String _messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      default:
        return 'Something went wrong (${e.code}): ${e.message}';
    }
  }
}