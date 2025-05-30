import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_flutter_web_app/models/baseModel.dart';

class UserWithRole {
  final DocumentReference? user;
  final List<String> rolen;

  User? userObj;

  UserWithRole({this.user, this.rolen = const []});

  factory UserWithRole.fromMap(Map<String, dynamic> map) => UserWithRole(
        user: map['user'],
        rolen: List<String>.from(map['rolen'] ?? []),
      );

  Map<String, dynamic> toMap() => {
        'user': user,
        'rolen': rolen,
      };
}

class User extends BaseModel {
  final String name;
  final String identification;
  final List<DocumentReference> projects;

  User({
    String? id,
    String? clientId,
    DateTime? creationTime,
    DateTime? lastUpdateTime,
    required this.name,
    required this.identification,
    this.projects = const [],
  }) : super(id: id, clientId: clientId, creationTime: creationTime, lastUpdateTime: lastUpdateTime);

  factory User.fromMap(Map<String, dynamic> map, String docId) => User(
        id: docId,
        clientId: map['clientId'],
        name: map['name'] ?? '',
        identification: map['identification'] ?? '',
        projects: List<DocumentReference>.from(map['projects'] ?? []),
        creationTime: (map['creationTime'] as Timestamp?)?.toDate(),
        lastUpdateTime: (map['lastUpdateTime'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'identification': identification,
        'projects': projects,
        'clientId': clientId,
        'creationTime': creationTime,
        'lastUpdateTime': lastUpdateTime,
      };
}
