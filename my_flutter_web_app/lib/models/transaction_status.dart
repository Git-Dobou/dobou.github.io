import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_flutter_web_app/models/baseModel.dart';
enum TransactionStatusType { Payed, NotPayed, Deactivated, Unknown }

class TransactionStatus extends BaseModel {
  String status;
  DateTime date;

  TransactionStatus({
    String? id,
    String? clientId,
    DateTime? creationTime,
    DateTime? lastUpdateTime,
    required this.status,
    required this.date,
  }) : super(id: id, clientId: clientId, creationTime: creationTime, lastUpdateTime: lastUpdateTime);

  factory TransactionStatus.fromMap(Map<String, dynamic> map, String docId) => TransactionStatus(
        id: docId,
        clientId: map['clientId'],
        status: map['status'] ?? '',
        date: (map['date'] as Timestamp).toDate(),
        creationTime: (map['creationTime'] as Timestamp?)?.toDate(),
        lastUpdateTime: (map['lastUpdateTime'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toMap() => {
        'status': status,
        'date': date,
        'clientId': clientId,
        'creationTime': creationTime,
        'lastUpdateTime': lastUpdateTime,
      };

  TransactionStatusType get statusTypisiert {
    return TransactionStatusType.values.firstWhere(
      (e) => e.name.toLowerCase() == status.toLowerCase(),
      orElse: () => TransactionStatusType.Unknown,
    );
  }

  set statusTypisiert(TransactionStatusType value) {
    status = value.name;
  }
}