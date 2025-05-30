import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthNotifier with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  String _message = 'Not signed in';

  User? get user => _user;
  String get message => _message;

  AuthNotifier() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      _message = _user == null ? 'Not signed in' : 'Signed in as \${_user!.uid}';
      notifyListeners();
    });
  }

  Future<void> signInAnonymously() async {
    try {
      UserCredential userCredential = await _auth.signInAnonymously();
      _user = userCredential.user;
      _message = 'Signed in anonymously as \${_user!.uid}';
    } catch (e) {
      _message = 'Failed to sign in anonymously: \$e';
      print(e);
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    _message = 'Signed out';
    notifyListeners();
  }
}
