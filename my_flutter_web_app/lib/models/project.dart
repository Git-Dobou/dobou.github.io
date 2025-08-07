import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_flutter_web_app/models/baseModel.dart';
import 'package:my_flutter_web_app/models/user.dart';

class Project extends BaseModel {
  final String name;
  final String description;
  final bool active;
  final String projectIdentification;
  final bool debtTabVisible;
  final bool economizeTabVisible;
  final bool transactionWithMonth;
  DocumentReference? owner;

  final List<UserWithRole> users;

  Project({
    String? id,
    String? clientId,
    DateTime? creationTime,
    DateTime? lastUpdateTime,
    required this.name,
    required this.active,
    required this.description,
    required this.projectIdentification,
    this.debtTabVisible = false,
    this.economizeTabVisible = false,
    this.transactionWithMonth = false,
    this.owner,
    this.users = const [],
  }) : super(id: id, clientId: clientId, creationTime: creationTime, lastUpdateTime: lastUpdateTime);

  factory Project.fromMap(Map<String, dynamic> map, String docId) => Project(
        id: docId,
        clientId: map['clientId'],
        name: map['name'] ?? '',
        active: map['active'] ?? false,
        description: map['description'] ?? '',
        projectIdentification: map['projectIdentification'] ?? '',
        debtTabVisible: map['debtTabVisible'] ?? false,
        economizeTabVisible: map['economizeTabVisible'] ?? false,
        transactionWithMonth: map['transactionWithMonth'] ?? false,
        owner: map['owner'],
        users: (map['users'] as List?)?.map((e) => UserWithRole.fromMap(e)).toList() ?? [],
        creationTime: (map['creationTime'] as Timestamp?)?.toDate(),
        lastUpdateTime: (map['lastUpdateTime'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'active': active,
        'projectIdentification': projectIdentification,
        'debtTabVisible': debtTabVisible,
        'economizeTabVisible': economizeTabVisible,
        'transactionWithMonth': transactionWithMonth,
        'owner': owner,
        'users': users.map((u) => u.toMap()).toList(),
        'clientId': clientId,
        'creationTime': creationTime,
        'lastUpdateTime': lastUpdateTime,
      };

  factory Project.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return Project.fromMap(data, snapshot.id);
  }
}
