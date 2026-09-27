import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get userChanges => _firebaseAuth.userChanges();

  Future<User> signInAnonymouslyIfNeeded() async {
    final existingUser = _firebaseAuth.currentUser;

    if (existingUser != null) {
      return existingUser;
    }

    final userCredential = await _firebaseAuth.signInAnonymously();
    final user = userCredential.user;

    if (user == null) {
      throw StateError('Anonymous authentication did not return a user.');
    }

    return user;
  }

  Future<User> linkAnonymousWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final currentUser = _firebaseAuth.currentUser;

    if (currentUser == null) {
      throw StateError('No authenticated user is available to link.');
    }

    if (!currentUser.isAnonymous) {
      throw StateError('The current user is already a permanent account.');
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    final userCredential = await currentUser.linkWithCredential(credential);
    final user = userCredential.user;

    if (user == null) {
      throw StateError('Account linking did not return a user.');
    }

    return user;
  }

  Future<User> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;

    if (user == null) {
      throw StateError('Email/password sign-in did not return a user.');
    }

    return user;
  }

  Future<void> sendEmailVerification() async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw StateError('No authenticated user is available.');
    }

    if (user.isAnonymous || user.email == null) {
      throw StateError('Email verification requires a permanent account.');
    }

    if (user.emailVerified) {
      return;
    }

    await user.sendEmailVerification();
  }

  Future<User> reloadCurrentUser() async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw StateError('No authenticated user is available.');
    }

    await user.reload();

    final refreshedUser = _firebaseAuth.currentUser;

    if (refreshedUser == null) {
      throw StateError('Unable to refresh the current user.');
    }

    return refreshedUser;
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  Future<User> signOutToAnonymous() async {
    await _firebaseAuth.signOut();
    return signInAnonymouslyIfNeeded();
  }
}
