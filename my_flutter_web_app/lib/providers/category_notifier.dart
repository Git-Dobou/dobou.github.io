import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_flutter_web_app/providers/BaseNotifier.dart';
import '../models/category.dart' as model;

class CategoryNotifier extends BaseNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<model.Category> _categories = [];
  bool _isLoading = false;
  StreamSubscription? _categorySubscription;
  User? _currentUser;

  List<model.Category> get categories => _categories;
  bool get isLoading => _isLoading;

  CategoryNotifier() {
    // Initialize _currentUser immediately if possible
    _currentUser = _auth.currentUser;
    if (_currentUser != null) {
      fetchCategories();
    }

    _auth.authStateChanges().listen((user) {
      _currentUser = user;
      if (_currentUser != null) {
        fetchCategories();
      } else {
        _categories = [];
        _categorySubscription?.cancel();
        _isLoading = false; // Reset loading state on logout
        notifyListeners();
      }
    });
  }

  void fetchCategories() {
    if (_currentUser == null) {
      _categories = []; // Clear categories if no user
      _isLoading = false;
      notifyListeners();
      return;
    }

    // _isLoading = true;
    // notifyListeners();

    // _categorySubscription?.cancel(); // Cancel previous subscription
    // _categorySubscription = _firestore
    //     .collection('category') // Collection name as per instructions
    //     .where('clientId', isEqualTo: _currentUser!.uid)
    //     .snapshots()
    //     .listen((snapshot) {
    //   try {
    //     _categories = snapshot.docs.map((doc) => 
    //       model.Category.fromJson(doc.data() as Map<String, dynamic>, doc.id)
    //     ).toList();
    //   } catch (e) {
    //     print("Error parsing categories: \$e");
    //     // Handle error, maybe set categories to empty or show an error state
    //     _categories = [];
    //   }

    //   _isLoading = false;
    //   notifyListeners();
    // }, onError: (error) {
    //   print("Error fetching categories: \$error");
    //   _isLoading = false;
    //   _categories = []; // Clear categories on error
    //   notifyListeners();
    // });

    // _isLoading = true;

    _categorySubscription?.cancel(); // Cancel previous subscription

    fetchAll('category', model.Category.fromMap).then((result) async {
      _categories = result;
      notifyListeners();
      _isLoading = false;
    });
  }

  Future<void> _fetchCategories() async {
    fetchAll('category', model.Category.fromMap).then((result) async {
      _categories = result; 
    });
  }

  Future<void> addCategory(String name, String iconName) async {
    if (_currentUser == null) {
      print("Cannot add category: No user logged in.");
      return;
    }
    _isLoading = true; // Optional: indicate loading for add operation
    notifyListeners();
    try {
      await _firestore.collection('category').add({
        'name': name,
        'icon': iconName, // Assuming iconName maps to model.Category.icon
        'clientId': _currentUser!.uid,
        // 'color': null, // Explicitly null or remove if not set by default
        // 'id_old': null, // Explicitly null or remove if not set by default
      });
      // Listener in fetchCategories will auto-update the list, 
      // so no need to manually add to _categories here.
      // We might not even need isLoading here if UI updates reactively.
    } catch (e) {
      print("Error adding category: \$e");
    } finally {
      _isLoading = false; // Reset loading state if it was set
      notifyListeners();
    }
  }

  Future<void> updateCategory(String id, String name, String iconName) async {
     if (_currentUser == null) {
      print("Cannot update category: No user logged in.");
      return;
     }
    _isLoading = true; // Optional: indicate loading for update operation
    notifyListeners();
    try {
      await _firestore.collection('category').doc(id).update({
        'name': name,
        'icon': iconName,
        // Ensure other fields are not accidentally wiped out if not included here
        // e.g., 'color', 'id_old' if they exist and should be preserved or updatable
      });
    } catch (e) {
      print("Error updating category: \$e");
    } finally {
      _isLoading = false; // Reset loading state
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String id) async {
    if (_currentUser == null) {
      print("Cannot delete category: No user logged in.");
      return;
    }
    _isLoading = true; // Optional: indicate loading for delete operation
    notifyListeners();
    try {
      await _firestore.collection('category').doc(id).delete();
    } catch (e) {
      print("Error deleting category: \$e");
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
