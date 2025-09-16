import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_flutter_web_app/providers/BaseNotifier.dart';
import 'package:my_flutter_web_app/providers/auth_notifier.dart';
import '../models/category.dart' as model;

class CategoryNotifier extends BaseNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<model.Category> _categories = [];
  bool _isLoading = false;
  StreamSubscription? _categorySubscription;

  List<model.Category> get categories => _categories;
  bool get isLoading => _isLoading;

  CategoryNotifier({required AuthNotifier authNotifier}) {
    this.authNotifier = authNotifier;
  }

  void reset() {
    _categories = [];
    _isLoading = false;
    isLoaded = false;
    notifyListeners();
  }

  Future<void> fetchCategories() async {
    if (authNotifier!.user == null) {
      _categories = []; // Clear categories if no user
      _isLoading = false;
      notifyListeners();
      return;
    }

    _categorySubscription?.cancel(); // Cancel previous subscription

    if (!isLoaded) {
    fetchAll('category', model.Category.fromMap).then((result) async {
      _categories = result;
      notifyListeners();
      _isLoading = false;
    });
    isLoaded = true;
    }
  }

  Future<void> addCategory(model.Category category) async {
    if (authNotifier!.user == null) {
      print("Cannot add category: No user logged in.");
      return;
    }
    _isLoading = true; // Optional: indicate loading for add operation
    notifyListeners();
    try {

      var map = category.toMap();
      map = completeAdd(map);

      await _firestore.collection('category').add(map);
    } catch (e) {
      print("Error adding category: $e");
    } finally {
      _isLoading = false; // Reset loading state if it was set
      notifyListeners();
    }
  }

  Future<void> updateCategory(model.Category category) async {
     if (authNotifier!.user == null) {
      print("Cannot update category: No user logged in.");
      return;
     }
    _isLoading = true; // Optional: indicate loading for update operation
    notifyListeners();
    try {
      var map = category.toMap();
      map = completeUpdate(map);
      await _firestore.collection('category').doc(category.id).update(map);
    } catch (e) {
      print("Error updating category: $e");
    } finally {
      _isLoading = false; // Reset loading state
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String id) async {
    if (authNotifier!.user == null) {
      print("Cannot delete category: No user logged in.");
      return;
    }
    _isLoading = true; // Optional: indicate loading for delete operation
    notifyListeners();
    try {
      await _firestore.collection('category').doc(id).delete();
    } catch (e) {
      print("Error deleting category: $e");
    } finally {
      _isLoading = false; // Reset loading state
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _categorySubscription?.cancel();
    super.dispose();
  }
}
