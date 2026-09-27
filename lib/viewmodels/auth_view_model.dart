import 'dart:async';

import 'package:expense_tracker/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({required this._authService}) {
    _user = _authService.currentUser;
    _userSubscription = _authService.userChanges.listen(_handleUserChanged);
  }

  final AuthService _authService;

  StreamSubscription<User?>? _userSubscription;
  User? _user;
  bool _isProcessing = false;
  String? _errorMessage;

  User? get user => _user;

  String? get userId => _user?.uid;

  String? get email => _user?.email;

  bool get isSignedIn => _user != null;

  bool get isAnonymous => _user?.isAnonymous ?? true;

  bool get isProcessing => _isProcessing;

  String? get errorMessage => _errorMessage;

  Future<bool> createAccount({
    required String email,
    required String password,
  }) async {
    return _runAuthOperation(
      operation: () => _authService.linkAnonymousWithEmailPassword(
        email: email.trim(),
        password: password,
      ),
    );
  }

  Future<bool> signIn({required String email, required String password}) async {
    return _runAuthOperation(
      operation: () => _authService.signInWithEmailPassword(
        email: email.trim(),
        password: password,
      ),
    );
  }

  Future<bool> signOutToGuest() async {
    return _runAuthOperation(operation: _authService.signOutToAnonymous);
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> _runAuthOperation({
    required Future<User> Function() operation,
  }) async {
    if (_isProcessing) {
      return false;
    }

    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await operation();
      _user = user;
      return true;
    } on FirebaseAuthException catch (error, stackTrace) {
      _errorMessage = _messageForFirebaseAuthError(error);

      debugPrint('Authentication operation failed: ${error.code}');
      debugPrintStack(stackTrace: stackTrace);

      return false;
    } catch (error, stackTrace) {
      _errorMessage = 'Something went wrong. Please try again.';

      debugPrint('Authentication operation failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  String _messageForFirebaseAuthError(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-email' => 'Please enter a valid email address.',
      'weak-password' => 'Please choose a stronger password.',
      'email-already-in-use' || 'credential-already-in-use' =>
        'An account already exists with this email. Try signing in instead.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => 'The email or password is incorrect.',
      'user-disabled' => 'This account has been disabled.',
      'too-many-requests' =>
        'Too many attempts. Please wait a moment and try again.',
      'network-request-failed' =>
        'Unable to connect. Check your internet connection and try again.',
      'operation-not-allowed' =>
        'Email/password sign-in is not enabled for this Firebase project.',
      'provider-already-linked' =>
        'This account is already linked to an email/password sign-in.',
      _ => 'Authentication failed. Please try again.',
    };
  }

  void _handleUserChanged(User? user) {
    _user = user;
    notifyListeners();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}
