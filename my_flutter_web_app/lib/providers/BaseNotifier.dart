import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_flutter_web_app/providers/auth_notifier.dart';
import '../models/baseModel.dart';
import 'dart:convert';

class BaseNotifier extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseFirestore get firestore => _firestore;

  AuthNotifier? _authNotifier;
  set authNotifier(AuthNotifier? notifier) => _authNotifier = notifier;
  AuthNotifier? get authNotifier => _authNotifier;

  bool _isLoaded = false;
  set isLoaded(bool value) {
    _isLoaded = value;
    notifyListeners();
  }
  bool get isLoaded => _isLoaded;
  
  String get clientId => _authNotifier?.project?.projectIdentification ?? 'default-client-id';

  Map<String, dynamic> completeGeneral(Map<String, dynamic> map) {
    map['clientId'] = clientId;
    return map;
  }

  Map<String, dynamic> completeAdd(Map<String, dynamic> map) {
    map['creationTime'] = DateTime.now();
    map['lastUpdateTime'] = DateTime.now();
    map = completeGeneral(map);
    return map;
  }

  Map<String, dynamic> completeUpdate(Map<String, dynamic> map) {
    map['lastUpdateTime'] = DateTime.now();
    map = completeGeneral(map);
    return map;
  }

  Map<String, dynamic> completeDelete(Map<String, dynamic> map) {
    map['isDeleted'] = DateTime.now();
    map = completeGeneral(map);
    return map;
  }

  Future<DocumentReference?> getRef(String id, String collection) async {
    return _firestore.collection(collection).doc(id);
  }

  Future<T?> readRef<T extends BaseModel>(
    DocumentReference? ref,
    T Function(Map<String, dynamic> map, String id) fromMapFn,
  ) async {
    if (ref == null) {
      print("readRef: ref ist null");
      return null;
    }

    try {
      final snapshot = await ref.get();

      if (!snapshot.exists) {
        print("readRef: snapshot existiert nicht: ${ref.path}");
        return null;
      }

      return BaseModel.fromSnapshot<T>(snapshot, fromMapFn);
    } catch (e, stack) {
      print('Fehler beim Laden der Referenz: $e');
      print(stack);
      return null;
    }
  }

  Future<void> addData<T extends BaseModel>(T data, String collection) async {
    final json = data.toMap();
    json['clientId'] = clientId;
    json['creationTime'] = Timestamp.now();
    json['lastUpdateTime'] = Timestamp.now();

    var added = await _firestore.collection(collection).add(json);
    data.id = added.id;
  }

  Future<void> updateData<T extends BaseModel>(T data, String collection) async {
    final json = Map<String, dynamic>.from(jsonDecode(jsonEncode(data)));
    json['clientId'] = clientId;
    json['lastUpdateTime'] = Timestamp.now();

    await _firestore.collection(collection).doc(data.id).update(json);
  }

  Future<void> deleteData(String collection, String docId) async {
    await _firestore.collection(collection).doc(docId).delete();
  }
  
  Future<List<T>> fetchAll<T>(
    String collection,
    T Function(Map<String, dynamic>, String) fromJson,
  ) async {
    final query = await _firestore
        .collection(collection)
        .where("clientId", isEqualTo: clientId)
        .get();

    return query.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return fromJson(data, doc.id);
    }).toList();
  }
}