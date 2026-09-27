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

  User? get user => _user;

  String? get userId => _user?.uid;

  String? get email => _user?.email;

  bool get isSignedIn => _user != null;

  bool get isAnonymous => _user?.isAnonymous ?? true;

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
