import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/setting.dart' as model; // Using 'as model' to avoid conflict if Setting class name clashes

class SettingsNotifier with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, String> _settings = {};
  bool _isLoading = false;
  User? _user;

  // --- Getters for specific settings ---
  ThemeMode get themeMode {
    switch (_settings['theme']?.toLowerCase()) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  String get appName => _settings['appName'] ?? 'FinanzApp';
  String get currency => _settings['currency'] ?? 'EUR';
  String get font => _settings['font'] ?? 'Verdana';

  // Add other getters as needed: fontName, fontSize, defaultCategoryId, useFaceId, beginMonth etc.

  bool get isLoading => _isLoading;
  Map<String, String> get settings => _settings; // Expose all settings if needed for UI

  SettingsNotifier() {
    _user = _auth.currentUser; // Initialize user immediately
    if (_user != null) {
      loadSettings();
    }
    _auth.authStateChanges().listen((newUser) {
      _user = newUser;
      if (_user != null) {
        loadSettings();
      } else {
        _settings = {
          'theme': 'system',
          'appName': 'FinanzApp',
          'currency': 'EUR',
        }; // Clear settings to defaults on logout
        notifyListeners();
      }
    });
  }

  Future<void> loadSettings() async {
    if (_user == null) {
      // Apply default settings if no user is logged in
      _settings = {
        'theme': 'system',
        'appName': 'FinanzApp',
        'currency': 'EUR',
      };
      notifyListeners();
      return;
    }
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore.collection('users').doc(_user!.uid).collection('settings').get();
      final Map<String, String> loadedSettings = {};
      for (var doc in snapshot.docs) {
        // Assuming 'value' is the field storing the setting's value
        // And doc.id is the setting's module/name (e.g., 'theme', 'currency')
        if (doc.data().containsKey('value')) {
            loadedSettings[doc.id] = doc.data()['value'] as String;
        }
      }
      _settings = loadedSettings;
      
      // Apply default settings if some are missing from Firestore
      _settings.putIfAbsent('theme', () => 'system');
      _settings.putIfAbsent('appName', () => 'FinanzApp');
      _settings.putIfAbsent('currency', () => 'EUR');
      // ... add other defaults as necessary

    } catch (e) {
      print("Error loading settings: $e");
      // On error, apply default settings to ensure app stability
      _settings = {
        'theme': 'system',
        'appName': 'FinanzApp',
        'currency': 'EUR',
      };
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveSetting(String module, String value) async {
    if (_user == null) return;
    // No need to set _isLoading for individual saves unless it's a long operation
    // _isLoading = true;
    // notifyListeners(); // Potentially too many listeners notifications for rapid changes

    try {
      await _firestore.collection('user').doc(_user!.uid)
                      .collection('setting').doc(module).set({'value': value});
      _settings[module] = value;
      notifyListeners(); // Notify after successful save and internal state update
    } catch (e) {
      print("Error saving setting $module: $e");
    }
    // _isLoading = false; 
    // notifyListeners();
  }

  // Convenience methods for specific settings
  Future<void> setTheme(ThemeMode newThemeMode) async {
    String themeValue;
    switch (newThemeMode) {
      case ThemeMode.dark:
        themeValue = 'dark';
        break;
      case ThemeMode.light:
        themeValue = 'light';
        break;
      default:
        themeValue = 'system';
        break;
    }
    await saveSetting('theme', themeValue);
  }

  Future<void> setAppName(String name) async {
    await saveSetting('appName', name);
  }

  Future<void> setCurrency(String newCurrency) async {
    await saveSetting('currency', newCurrency);
  }
}
