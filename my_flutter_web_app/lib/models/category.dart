
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_flutter_web_app/models/baseModel.dart';

class Category extends BaseModel {
  String name;
  String icon;

  Category({
    String? id,
    String? clientId,
    DateTime? creationTime,
    DateTime? lastUpdateTime,
    required this.name,
    required this.icon,
  }) : super(id: id, clientId: clientId, creationTime: creationTime, lastUpdateTime: lastUpdateTime);

  factory Category.fromMap(Map<String, dynamic> map, String docId) => Category(
        id: docId,
        clientId: map['clientId'],
        name: map['name'] ?? '',
        icon: map['icon'] ?? '',
        creationTime: (map['creationTime'] as Timestamp?)?.toDate(),
        lastUpdateTime: (map['lastUpdateTime'] as Timestamp?)?.toDate(),
      );
      
  @override
  Map<String, dynamic> toMap() => {
        'name': name,
        'icon': icon,
        'clientId': clientId,
        'creationTime': creationTime,
        'lastUpdateTime': lastUpdateTime,
      };
}
