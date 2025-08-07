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
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseAuth get auth => _auth;
  

  // Future<bool> encryptAndSave<T>(T data, String collection) async {
  //   try {
  //     final jsonString = jsonEncode(data);
  //     final encrypted = EncryptionService.encryptText(jsonString);

  //     await _firestore.collection(collection).add({'encryptedData': encrypted});
  //     return true;
  //   } catch (e) {
  //     print("Fehler beim Verschlüsseln oder Speichern: $e");
  //     return false;
  //   }
  // }

  // Future<T?> fetchAndDecrypt<T>(String collection, String docId, T Function(Map<String, dynamic>) fromJson) async {
  //   try {
  //     final doc = await _firestore.collection(collection).doc(docId).get();
  //     final data = doc.data();
  //     if (data == null || !data.containsKey('encryptedData')) return null;

  //     final decrypted = EncryptionService.decryptText(data['encryptedData']);
  //     if (decrypted == null) return null;

  //     return fromJson(jsonDecode(decrypted));
  //   } catch (e) {
  //     print("Fehler beim Abrufen/Entschlüsseln: $e");
  //     return null;
  //   }
  // }

Map<String, dynamic> completeGeneral(Map<String, dynamic> map) {
  // map['clientId'] = AuthNotifier.instance.project!.clientId;
  map['clientId'] = '1735421-1353-53';

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
    //  Map<String, dynamic>.from(jsonDecode(jsonEncode(data)));
    json['clientId'] = '1735421-1353-53';
    json['creationTime'] = Timestamp.now();
    json['lastUpdateTime'] = Timestamp.now();

    var added = await _firestore.collection(collection).add(json);
    data.id = added.id;
  }

  Future<void> updateData<T extends BaseModel>(T data, String collection) async {
    final json = Map<String, dynamic>.from(jsonDecode(jsonEncode(data)));
    json['clientId'] = '1735421-1353-53';
    json['lastUpdateTime'] = Timestamp.now();

    await _firestore.collection(collection).doc(data.id).update(json);
  }

  Future<void> deleteData(String collection, String docId) async {
    await _firestore.collection(collection).doc(docId).delete();
  }

   Future<Result<T>> fetchAllWithSubscription<T>(
    String collection,
    T Function(Map<String, dynamic>, String) fromJson,
  ) async {
    List<T> elements = [];

    final query = await _firestore
                    .collection(collection)
                    .where("clientId", isEqualTo: "1735421-1353-53")
                    .snapshots()
                    .listen((onData) {
      try {
        elements = onData.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          try {
            return fromJson(data, doc.id);
          } catch (ex){
            print(doc.id);
          }

          return fromJson(data, doc.id);
        }).toList();

        print(elements);
      } catch (e) {
        print("Error parsing categories: $e");
        // Handle error, maybe set categories to empty or show an error state
        elements = [];
      }
      }
      );

      return Result(elements, query);
  }

  Future<List<T>> fetchAll<T>(
    String collection,
    T Function(Map<String, dynamic>, String) fromJson,
  ) async {
    final query = await _firestore 
                    .collection(collection)
                    .where("clientId", isEqualTo: "1735421-1353-53")
                    .get();

    return query.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;

      return fromJson(data, doc.id);
    }).toList();
  }
}

class Result<T> {
  List<T> a;
  StreamSubscription b;

  Result(this.a, this.b);
}