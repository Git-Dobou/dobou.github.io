import 'package:cloud_firestore/cloud_firestore.dart';

class Economize {
  final String id; // Document ID
  final String name;
  final String? comment;
  final double amount; // Target amount to economize
  final DateTime date; // Target date
  final DocumentReference categoryRef;
  final List<DocumentReference>? transactionRefs; // Transactions contributing
  final String? clientId;
  final String? idOld;
  final String? currency;
  final bool? isDeleted;
  final DateTime? timestamp; // Creation/update timestamp
  final double? savedAmount; // If stored, sum of contributing transactions
  final bool? isReached; // If stored, true if savedAmount >= amount

  Economize({
    required this.id,
    required this.name,
    this.comment,
    required this.amount,
    required this.date,
    required this.categoryRef,
    this.transactionRefs,
    this.clientId,
    this.idOld,
    this.currency,
    this.isDeleted,
    this.timestamp,
    this.savedAmount,
    this.isReached,
  });

  factory Economize.fromJson(Map<String, dynamic> json, String id) {
    return Economize(
      id: id,
      name: json['name'] as String,
      comment: json['comment'] as String?,
      amount: (json['amount'] as num).toDouble(),
      date: (json['date'] as Timestamp).toDate(),
      categoryRef: json['categoryRef'] as DocumentReference,
      transactionRefs: (json['transactionRefs'] as List<dynamic>?)
          ?.map((ref) => ref as DocumentReference)
          .toList(),
      clientId: json['clientId'] as String?,
      idOld: json['id_old'] as String?,
      currency: json['currency'] as String?,
      isDeleted: json['isDeleted'] as bool?,
      timestamp: (json['timestamp'] as Timestamp?)?.toDate(),
      savedAmount: (json['savedAmount'] as num?)?.toDouble(),
      isReached: json['isReached'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'name': name,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'categoryRef': categoryRef,
    };
    if (comment != null) data['comment'] = comment;
    if (transactionRefs != null) data['transactionRefs'] = transactionRefs;
    if (clientId != null) data['clientId'] = clientId;
    if (idOld != null) data['id_old'] = idOld;
    if (currency != null) data['currency'] = currency;
    if (isDeleted != null) data['isDeleted'] = isDeleted;
    if (timestamp != null) data['timestamp'] = Timestamp.fromDate(timestamp!);
    if (savedAmount != null) data['savedAmount'] = savedAmount;
    if (isReached != null) data['isReached'] = isReached;
    return data;
  }
}
