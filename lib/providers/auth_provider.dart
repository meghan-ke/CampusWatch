// lib/providers/auth_provider.dart
// Holds the authentication STATE: who is signed in, their role, whether their
// email is verified, and whether a request is loading or failed. Screens read
// this and rebuild automatically when it changes (via notifyListeners).

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? service}) : _service = service ?? AuthService() {
    // Watch Firebase's sign-in state. This also restores a previous session
    // when the app starts.
    _subscription = _service.authStateChanges.listen(_onAuthChanged);
  }

  final AuthService _service;
  late final StreamSubscription<User?> _subscription;

  AppUser? _user;
  bool _emailVerified = false;
  bool _isInitializing = true; // true until the first sign-in check finishes
  bool _isLoading = false; // true while a login/register request runs
  String? _errorMessage;

  // True while login()/register() load the profile themselves, so the
  // listener must not do it a second time.
  bool _handlingManually = false;

  // --- Read-only values for the UI -----------------------------------------

  /// The signed-in user's profile, or null when signed out.
  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isStaff => _user?.role.isStaff ?? false;

  /// Whether the signed-in account has confirmed its email address.
  bool get emailVerified => _emailVerified;

  /// Students must verify their email before entering the app.
  /// Staff accounts are created by an administrator, so they are exempt.
  bool get needsVerification => isLoggedIn && !isStaff && !_emailVerified;

  /// True only during app start, while we check for a saved session.
  bool get isInitializing => _isInitializing;

  /// True while a login or registration request is running.
  bool get isLoading => _isLoading;

  /// The last error message to show, or null.
  String? get errorMessage => _errorMessage;

  // --- Actions the UI can call ---------------------------------------------

  /// Returns true on success, false on failure (see [errorMessage]).
  Future<bool> login({required String email, required String password}) {
    return _run(() => _service.login(email: email, password: password));
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _run(
      () => _service.register(name: name, email: email, password: password),
    );
  }

  Future<void> logout() => _service.logout();

  /// Sends the verification email again. Returns true if it was sent.
  Future<bool> resendVerification() async {
    try {
      await _service.sendVerificationEmail();
      return true;
    } on AuthFailure catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  /// Re-reads the account from Firebase and returns whether it is verified.
  /// AuthGate reacts automatically when this becomes true.
  Future<bool> checkVerified() async {
    try {
      _emailVerified = await _service.refreshVerified();
    } catch (_) {
      // Keep the previous value if the check fails (e.g. offline).
    }
    notifyListeners();
    return _emailVerified;
  }

  /// Clears the error, e.g. when the user leaves a screen.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // --- Internals -------------------------------------------------------------

  /// Shared wrapper for login and register: handles loading and errors.
  Future<bool> _run(Future<AppUser> Function() action) async {
    _handlingManually = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await action();
      _emailVerified = _service.isEmailVerified;
      return true;
    } on AuthFailure catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _handlingManually = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Called by Firebase on app start, and on logout.
  Future<void> _onAuthChanged(User? firebaseUser) async {
    if (_handlingManually) return;

    if (firebaseUser == null) {
      _user = null;
      _emailVerified = false;
    } else {
      try {
        _user = await _service.fetchProfile(firebaseUser.uid);
        _emailVerified = firebaseUser.emailVerified;
      } catch (_) {
        _user = null;
      }
    }
    _isInitializing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}