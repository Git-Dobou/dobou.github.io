// Gemeinsames Basismodell
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

abstract class BaseModel extends ChangeNotifier {
  String? id;
  final String? clientId;
  final DateTime? creationTime;
  final DateTime? lastUpdateTime;

  BaseModel({this.id, this.clientId, this.creationTime, this.lastUpdateTime});

  Map<String, dynamic> toMap() => {
  };

  // Optional helper (nicht erzwingbar für alle Kinder, aber nutzbar)
  static T fromSnapshot<T extends BaseModel>(
    DocumentSnapshot snapshot,
    T Function(Map<String, dynamic> data, String id) fromMapFn,
  ) {
    final data = snapshot.data() as Map<String, dynamic>;
    return fromMapFn(data, snapshot.id);
  }
}
