import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_flutter_web_app/models/baseModel.dart';
import 'package:my_flutter_web_app/models/category.dart';
import 'package:my_flutter_web_app/models/transaction.dart' as model_trans;
import 'package:my_flutter_web_app/models/transaction_status.dart';

class Economize extends BaseModel {
  final double? goalAmount;
  final String title;
  final double? beginAmount;
  final String? comment;
  final DateTime? targetDate;
  final List<DocumentReference>? transactionRefs;
  DocumentReference? categoryRef;

  List<model_trans.Transaction> transactions =  [];
  Category? category;

  Economize({
    String? id,
    String? clientId,
    DateTime? creationTime,
    DateTime? lastUpdateTime,
    this.comment,
    this.targetDate,
    this.goalAmount,
    required this.title,
    this.beginAmount,
    this.transactionRefs,
    this.categoryRef,
  }) : super(
          id: id,
          clientId: clientId,
          creationTime: creationTime,
          lastUpdateTime: lastUpdateTime,
        );

  factory Economize.fromMap(Map<String, dynamic> map, String docId) {
    return Economize(
      id: docId,
      clientId: map['clientId'],
      title: map['title'] ?? '',
      goalAmount: (map['goalAmount'] as num?)?.toDouble(),
      comment: map['comment'] as String?,
      targetDate: (map['targetDate'] as DateTime?),
      beginAmount: (map['beginAmount'] as num?)?.toDouble(),
      creationTime: (map['creationTime'] as Timestamp?)?.toDate(),
      lastUpdateTime: (map['lastUpdateTime'] as Timestamp?)?.toDate(),
      transactionRefs: (map['transactionsRef'] as List<dynamic>?)
          ?.map((ref) => ref as DocumentReference)
          .toList(),
      categoryRef: (map['categoryRef'] as dynamic) as DocumentReference?
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goalAmount': goalAmount,
      'beginAmount': beginAmount,
      'title': title,
      'transactionsRef': transactionRefs,
      'clientId': clientId,
      'creationTime': creationTime,
      'lastUpdateTime': lastUpdateTime,
      'categoryRef' : categoryRef
    };
  }
}

extension EconomizeExtension on Economize {
  double get savedAmount {
    double total = 0;
    for (var t in transactions) {
      final status = t.transactionStatus.where((s) => s.statusTypisiert == TransactionStatusType.Payed);
      for (var s in status) {
        total += t.getNewAmount(s.date) ?? t.amount;
      }
    }
    return total;
  }
}