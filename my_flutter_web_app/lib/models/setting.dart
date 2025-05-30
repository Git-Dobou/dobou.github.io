import 'package:cloud_firestore/cloud_firestore.dart';

class Setting {
  final String id; // Document ID, which is the setting's module name (e.g., "theme", "currency")
  final String value;

  Setting({
    required this.id, // Represents the module name
    required this.value,
  });

  // Factory constructor to create a Setting object from Firestore document snapshot
  factory Setting.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Setting(
      id: doc.id, // The document ID is the module name
      value: data['value'] as String,
    );
  }

  // Factory constructor for convenience if you have module and value separately
  // This might be less used if doc.id is always the module.
  factory Setting.fromJson(String id, Map<String, dynamic> json) {
    return Setting(
      id: id,
      value: json['value'] as String,
    );
  }

  // Method to convert a Setting object to a map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'value': value,
      // 'id' or 'module' is not stored as a field in the document itself,
      // as it's the document ID.
    };
  }
}
