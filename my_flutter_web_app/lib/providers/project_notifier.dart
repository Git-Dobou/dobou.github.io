import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:my_flutter_web_app/models/project.dart';
import 'package:my_flutter_web_app/models/user.dart';
import 'package:my_flutter_web_app/providers/auth_notifier.dart';
import 'package:my_flutter_web_app/providers/category_notifier.dart';
import 'package:my_flutter_web_app/providers/debt_notifier.dart';
import 'package:my_flutter_web_app/providers/transaction_notifier.dart';
import 'BaseNotifier.dart';

class ProjectNotifier extends BaseNotifier {
  List<Project> _projects = [];
  List<Project> _filteredProjects = [];
  bool _isLoading = false;
  StreamSubscription? _projectSubscription;
  User? _user;

  String searchText = "";

  List<Project> get projects => _projects;
  List<Project> get filteredProjects => _filteredProjects;
  bool get isLoading => _isLoading;

  ProjectNotifier(AuthNotifier authNotifier, TransactionNotifier transactionNotifier, DebtNotifier debtNotifier, CategoryNotifier categoryNotifier) {
    this.authNotifier = authNotifier;
    this.transactionNotifier = transactionNotifier;
    this.debtNotifier = debtNotifier;
    this.categoryNotifier = categoryNotifier;
  }

  void loading(bool status) {
    _isLoading = status;
    notifyListeners();
  }

  void setFilteredProjects() {
    _filteredProjects = _projects.where((project) {
      return searchText.isEmpty ||
          project.name.toLowerCase().contains(searchText.toLowerCase()) ||
          project.description.toLowerCase().contains(searchText.toLowerCase());
    }).toList();
    notifyListeners();
  }

  void setSearchText(String text) {
    searchText = text;
    setFilteredProjects();
  }

  bool _projectsLoaded = false;

  TransactionNotifier? _transactionNotifier;
  TransactionNotifier? get transactionNotifier => _transactionNotifier;

  set transactionNotifier(TransactionNotifier? transactionNotifier) {
    _transactionNotifier = transactionNotifier;
  }

  DebtNotifier?  _debtNotifier;
  DebtNotifier? get debtNotifier => _debtNotifier;
  set debtNotifier(DebtNotifier? debtNotifier) {
    _debtNotifier = debtNotifier;
  }

  CategoryNotifier?  _categoryNotifier;
  CategoryNotifier? get categoryNotifier => _categoryNotifier;
  set categoryNotifier(CategoryNotifier? categoryNotifier) {
    _categoryNotifier = categoryNotifier;
  }

  void resetProjectsLoaded() {
    _projectsLoaded = false;
  }

  Future<void> fetchProjects() async {

    if (_projectsLoaded) return;
    
    if (authNotifier!.user == null) {
      _projects = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();
    await authNotifier!.fetchProjects();
    _filteredProjects = authNotifier!.allProjects;
    _isLoading = false;
    _projectsLoaded = true;
    notifyListeners();
  }

  Future<DocumentReference> addProject(Project project) async {
    if (authNotifier!.user == null) {
      throw Exception("User not logged in");
    }

    Map<String, dynamic> projectData = project.toMap();
    completeAdd(projectData);

    _isLoading = true;
    notifyListeners();

    try {
      var doc = await firestore.collection('project').add(projectData);
      project.id = doc.id;
      _projects.add(project);
      setFilteredProjects();
      return doc;
    } catch (e) {
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

// ...existing code...

  Future<void> setAsDefault(Project project) async {
    _isLoading = true;
    notifyListeners();
    if (authNotifier!.user == null) throw Exception("User not logged in");

    // Setze alle Projekte als nicht default (active = false)
    for (var p in filteredProjects) {
      if (p.id != project.id && p.active) {
        print('Setting project ${p.name} , ${p.id} as inactive');
        p.active = false;
        await firestore.collection('project').doc(p.id).update({'active': false});
      }
    }

    // Setze das gewünschte Projekt als default (active = true)
    await firestore.collection('project').doc(project.id).update({'active': true});
    project.active = true;
    print('Setting project ${project.name} , ${project.id} as active');
    authNotifier!.project = project;
    await fetchProjects();
    await transactionNotifier!.fetchTransactions();
    await debtNotifier!.fetchDebts();
    await categoryNotifier!.fetchCategories();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateProject(Project project) async {
    if (authNotifier!.user == null) throw Exception("User not logged in");
    Map<String, dynamic> projectData = project.toMap();
    projectData = completeUpdate(projectData);

    await firestore.collection('project').doc(project.id).update(projectData);

    var index = _projects.indexWhere((b) => b.id == project.id);
    _projects[index] = project;
    setFilteredProjects();
  }

  Future<void> deleteProject(Project project) async {
    if (authNotifier!.user == null) throw Exception("User not logged in");
    await firestore.collection('project').doc(project.id).delete();
    _projects.removeWhere((b) => b.id == project.id);
    setFilteredProjects();
  }

  @override
  void dispose() {
    _projectSubscription?.cancel();
    super.dispose();
  }
}