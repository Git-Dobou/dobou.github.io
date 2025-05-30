import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_flutter_web_app/models/baseModel.dart';

class TransactionNewAmount extends BaseModel {
  DateTime availableFrom;
  DateTime? availableUntil;
  double amount;

  TransactionNewAmount({
    String? id,
    String? clientId,
    DateTime? creationTime,
    DateTime? lastUpdateTime,
    required this.availableFrom,
    this.availableUntil,
    required this.amount,
  }) : super(id: id, clientId: clientId, creationTime: creationTime, lastUpdateTime: lastUpdateTime);

  factory TransactionNewAmount.fromMap(Map<String, dynamic> map, String docId) => TransactionNewAmount(
        id: docId,
        clientId: map['clientId'],
        availableFrom: (map['availableFrom'] as Timestamp).toDate(),
        availableUntil: map['availableUntil'] != null ? (map['availableUntil'] as Timestamp).toDate() : null,
        amount: (map['amount'] ?? 0).toDouble(),
        creationTime: (map['creationTime'] as Timestamp?)?.toDate(),
        lastUpdateTime: (map['lastUpdateTime'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toMap() => {
        'availableFrom': availableFrom,
        'availableUntil': availableUntil,
        'amount': amount,
        'clientId': clientId,
        'creationTime': creationTime,
        'lastUpdateTime': lastUpdateTime,
      };
}
