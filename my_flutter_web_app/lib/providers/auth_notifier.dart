import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:my_flutter_web_app/models/project.dart';
import 'package:my_flutter_web_app/models/user.dart' as modelUser;
import 'package:my_flutter_web_app/providers/BaseNotifier.dart';

class AuthNotifier extends BaseNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  firebase_auth.User? _user;
  String _message = 'Not signed in';

  firebase_auth.User? get user => _user;
  String get message => _message;

  List<Project> _allProjects = [];
  List<Project> get allProjects => _allProjects;

  Project? _project;
  Project? get project => _project;
  set project(Project? value) {
    _project = value;
    notifyListeners();
  }

  List<modelUser.User> _allUsers = [];
  List<modelUser.User> get allUsers => _allUsers;

  AuthNotifier() {
    _init();
  }

  void _init() {
    // Initialisierung falls benötigt
  }

  Future<void> fetchProjects() async {
    _allProjects.clear();

    final query = await firestore
        .collection('user')
        .where("userId", isEqualTo: user?.uid)
        .get();

    var users = query.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return modelUser.User.fromMap(data, doc.id);
    }).toList();

    var currentUser = users.firstWhereOrNull((u) => u.userId == user?.uid);
    if (currentUser == null) return;

    print('Fetched user: ${currentUser.name} with ID: ${currentUser.id}');
    var count = 0;
    for (var projectRef in currentUser.projects) {
      count++;
      print('Fetching project $count: ${projectRef.id}');
      final projectData = await readRef(projectRef, Project.fromMap);
      
      projectData!.id = projectRef.id;
      if (projectData.active) {
        _project = projectData;
        print('Setting active project: ${projectData.name}');
      }
      _allProjects.add(projectData);
    }

    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      _user = userCredential.user;
      print('Signed in as ${_user!.email}');
      notifyListeners();
    } catch (e) {
      _message = 'Failed to sign in: $e';
      print(e);
      notifyListeners();
    }
  }

  Future<void> signInAnonymously() async {
    try {
      UserCredential userCredential = await _auth.signInAnonymously();
      _user = userCredential.user;
      _message = 'Signed in anonymously as ${_user!.uid}';
      notifyListeners();
    } catch (e) {
      _message = 'Failed to sign in anonymously: $e';
      print(e);
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    _message = 'Signed out';
    notifyListeners();
  }
}
