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
}
