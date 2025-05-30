import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_flutter_web_app/models/baseModel.dart';

class Payment extends BaseModel {
  final double amount;
  final DateTime date;
  final String? note;
  final String? reason;
  final double? interestAmount;

  Payment({
    String? id,
    String? clientId,
    DateTime? creationTime,
    DateTime? lastUpdateTime,
    required this.amount,
    required this.date,
    this.note,
    this.reason,
    this.interestAmount,
  }) : super(id: id, clientId: clientId, creationTime: creationTime, lastUpdateTime: lastUpdateTime);

  factory Payment.fromMap(Map<String, dynamic> map, String docId) => Payment(
        id: docId,
        clientId: map['clientId'],
        amount: (map['amount'] ?? 0).toDouble(),
        date: (map['date'] as Timestamp).toDate(),
        note: map['note'] ?? '',
        reason: map['reason'] ?? '',
        interestAmount: (map['interestAmount'] as num?)?.toDouble(),
        creationTime: (map['creationTime'] as Timestamp?)?.toDate(),
        lastUpdateTime: (map['lastUpdateTime'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toMap() => {
        'amount': amount,
        'date': date,
        'note': note,
        'reason': reason,
        'interestAmount': interestAmount,
        'clientId': clientId,
        'creationTime': creationTime,
        'lastUpdateTime': lastUpdateTime,
      };
}
