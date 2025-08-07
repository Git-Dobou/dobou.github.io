import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_flutter_web_app/models/project.dart';
import 'package:my_flutter_web_app/models/user.dart' as modelUser;
import 'package:my_flutter_web_app/providers/BaseNotifier.dart';
import '../models/user.dart' as model;

class AuthNotifier extends BaseNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  String _message = 'Not signed in';

  User? get user => _user;
  String get message => _message;

  static AuthNotifier? _instance;

  static AuthNotifier get instance {
    _instance ??= AuthNotifier();
    return _instance!;
  }

  AuthNotifier()  {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      _message = _user == null ? 'Not signed in' : 'Signed in as ${_user!.uid}';

      fetchProjects();
      fetchUsers();

      notifyListeners();
    });
  }
  
  List<Project> _allProjects = [];
  List<Project> get allProjects {
    return _allProjects;
  }

  Project? _project;
  Project? get project {
    return _project;
  }

  Future<void> fetchProjects() async {
    fetchAll('project', Project.fromMap).then((result) async {
      _project = result.firstWhereOrNull((b) => b.active);
      _allProjects = result;
    });
  }

  List<modelUser.User> _allUsers = [];
  List<modelUser.User> get allUsers {
    return _allUsers;
  }

  Future<void> fetchUsers() async {
    fetchAll('user', modelUser.User.fromMap).then((result) async {
      _allUsers = result;
    });
  }
  
  Future<void> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(email:  email, password: password);
      instance._user = userCredential.user;
      _message = 'Signed in anonymously as ${_user!.uid}';
    } catch (e) {
      _message = 'Failed to sign in anonymously: $e';
      print(e);
    }
    notifyListeners();
  }
  
  Future<void> signInAnonymously() async {
    try {
      UserCredential userCredential = await _auth.signInAnonymously();
      _user = userCredential.user;
      _message = 'Signed in anonymously as ${_user!.uid}';
    } catch (e) {
      _message = 'Failed to sign in anonymously: $e';
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
