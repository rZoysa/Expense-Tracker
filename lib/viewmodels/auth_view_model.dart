import 'dart:async';

import 'package:expense_tracker/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({required this._authService}) {
    _user = _authService.currentUser;
    _userSubscription = _authService.userChanges.listen(_handleUserChanged);

    if (_user == null) {
      unawaited(ensureUserSession());
    }
  }

  final AuthService _authService;

  StreamSubscription<User?>? _userSubscription;
  User? _user;
  bool _isProcessing = false;
  bool _isInitializingSession = false;
  String? _errorMessage;

  User? get user => _user;

  String? get email => _user?.email;

  bool get isAnonymous => _user?.isAnonymous ?? true;

  bool get isEmailVerified => _user?.emailVerified ?? false;

  bool get isProcessing => _isProcessing;

  bool get isInitializingSession => _isInitializingSession;

  String? get errorMessage => _errorMessage;

  Future<bool> ensureUserSession() async {
    if (_user != null) {
      return true;
    }

    if (_isInitializingSession) {
      return false;
    }

    _isInitializingSession = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.signInAnonymouslyIfNeeded();
      _user = user;
      return true;
    } on FirebaseAuthException catch (error, stackTrace) {
      _handleFirebaseAuthError(error, stackTrace);
      return false;
    } catch (error, stackTrace) {
      _errorMessage = 'Unable to start your session. Please try again.';
      _logAuthError(error, stackTrace);
      return false;
    } finally {
      _isInitializingSession = false;
      notifyListeners();
    }
  }

  Future<bool> createAccount({
    required String email,
    required String password,
  }) async {
    return _runUserOperation(
      operation: () => _authService.linkAnonymousWithEmailPassword(
        email: email.trim(),
        password: password,
      ),
    );
  }

  Future<bool> signIn({required String email, required String password}) async {
    return _runUserOperation(
      operation: () => _authService.signInWithEmailPassword(
        email: email.trim(),
        password: password,
      ),
    );
  }

  Future<bool> signOutToGuest() async {
    return _runUserOperation(operation: _authService.signOutToAnonymous);
  }

  Future<bool> sendVerificationEmail() async {
    if (isAnonymous || isEmailVerified) {
      return false;
    }

    return _runVoidOperation(
      operation: _authService.sendEmailVerification,
      fallbackErrorMessage: 'Unable to send the verification email.',
    );
  }

  Future<bool> refreshUser() async {
    return _runUserOperation(
      operation: _authService.reloadCurrentUser,
      fallbackErrorMessage: 'Unable to refresh your account status.',
    );
  }

  Future<bool> sendPasswordReset({required String email}) async {
    if (_isProcessing) {
      return false;
    }

    _beginOperation();

    try {
      await _authService.sendPasswordResetEmail(email: email.trim());
      return true;
    } on FirebaseAuthException catch (error, stackTrace) {
      if (error.code == 'user-not-found') {
        return true;
      }

      _handleFirebaseAuthError(error, stackTrace);
      return false;
    } catch (error, stackTrace) {
      _errorMessage = 'Unable to send the password reset email.';

      _logAuthError(error, stackTrace);

      return false;
    } finally {
      _finishOperation();
    }
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> _runUserOperation({
    required Future<User> Function() operation,
    String fallbackErrorMessage = 'Something went wrong. Please try again.',
  }) async {
    if (_isProcessing) {
      return false;
    }

    _beginOperation();

    try {
      final user = await operation();
      _user = user;
      return true;
    } on FirebaseAuthException catch (error, stackTrace) {
      _handleFirebaseAuthError(error, stackTrace);
      return false;
    } catch (error, stackTrace) {
      _errorMessage = fallbackErrorMessage;

      _logAuthError(error, stackTrace);

      return false;
    } finally {
      _finishOperation();
    }
  }

  Future<bool> _runVoidOperation({
    required Future<void> Function() operation,
    required String fallbackErrorMessage,
  }) async {
    if (_isProcessing) {
      return false;
    }

    _beginOperation();

    try {
      await operation();
      return true;
    } on FirebaseAuthException catch (error, stackTrace) {
      _handleFirebaseAuthError(error, stackTrace);
      return false;
    } catch (error, stackTrace) {
      _errorMessage = fallbackErrorMessage;

      _logAuthError(error, stackTrace);

      return false;
    } finally {
      _finishOperation();
    }
  }

  void _beginOperation() {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();
  }

  void _finishOperation() {
    _isProcessing = false;
    notifyListeners();
  }

  void _handleFirebaseAuthError(
    FirebaseAuthException error,
    StackTrace stackTrace,
  ) {
    _errorMessage = _messageForFirebaseAuthError(error);

    _logAuthError(error.code, stackTrace);
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
        'Sign-in is temporarily unavailable. Please try again later.',
      'provider-already-linked' => 'This account already uses email sign-in.',
      _ => 'We couldn\'t complete that request. Please try again.',
    };
  }

  void _handleUserChanged(User? user) {
    final hadNoUser = _user == null;
    _user = user;

    if (user != null && hadNoUser) {
      _errorMessage = null;
    }

    notifyListeners();

    if (user == null && !_isProcessing && !_isInitializingSession) {
      unawaited(ensureUserSession());
    }
  }

  void _logAuthError(Object error, StackTrace stackTrace) {
    if (!kDebugMode) {
      return;
    }

    debugPrint('Authentication operation failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}
