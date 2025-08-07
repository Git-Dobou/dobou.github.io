import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:my_flutter_web_app/models/baseModel.dart';
import 'package:my_flutter_web_app/models/category.dart';
import 'package:my_flutter_web_app/models/debt.dart';
import 'package:my_flutter_web_app/models/economize.dart';
import 'package:my_flutter_web_app/models/transaction_new_amount.dart';
import 'package:my_flutter_web_app/models/transaction_status.dart';
import 'package:collection/collection.dart';
import 'package:my_flutter_web_app/providers/transaction_notifier.dart';

enum TransactionType { Income, Expense, Unknown }
enum TransactionCyklus {Monthly, Year, Quarterly, Unknown}

extension TransactionExtension on Transaction {
  
   bool get isSubTransaction {
    return true;
  }

    double? get currentAmount {
      return 0;
    }
    TransactionType? get typeTypisiert {
    return TransactionType.values.firstWhere(
        (e) => e.name.toLowerCase() == type.toLowerCase(),
        orElse: () => TransactionType.Unknown);
  }

  TransactionCyklus? get cyklusTypisiert {
    return TransactionCyklus.values.firstWhere(
        (e) => e.name.toLowerCase() == cyklus.toLowerCase(),
        orElse: () => TransactionCyklus.Unknown);
  }

  TransactionStatusType? get statusTypisiert {
    return TransactionStatusType.values.firstWhere(
        (e) => e.name.toLowerCase() == cyklus,
        orElse: () => TransactionStatusType.Unknown);
  }

  bool get isPayed {
    return isTransactionPayed(availableFrom);
  }

  bool get isIncome {
    return typeTypisiert == TransactionType.Income;
  }

  bool get isExpense {
    return typeTypisiert == TransactionType.Expense;
  }

  bool get isDeactivated {
    return isTransactionDeactivated(availableFrom);
  }

  bool isTransactionPayed(DateTime? date) {
    // return transactionStatus.any((t) =>
    //     t.statusTypisiert == TransactionStatusType.Payed &&
    //     (AuthViewModel.instance.activeProject?.transactionWithMonth == false ||
    //         t.date.month == date!.month));

    var check = transactionStatus.any((t) =>
        t.statusTypisiert == TransactionStatusType.Payed &&
            t.date.month == date!.month);

    return check;
  }

  bool isTransactionDeactivated(DateTime? date) {
    // return transactionStatus.any((t) =>
    //     t.statusTypisiert == TransactionStatusType.Deactivated &&
    //     (AuthViewModel.instance.activeProject?.transactionWithMonth == false ||
    //         t.date.month == date!.month));
    return transactionStatus.any((t) =>
        t.statusTypisiert == TransactionStatusType.Deactivated &&
            t.date.month == date!.month);
  }

  double getAmount(DateTime date) {
    return getNewAmount(date) ?? amount;
  }

  double? getNewAmount(DateTime date) {
    var title2 = title;

    var newAmount = transactionNewAmounts.firstWhereOrNull(
      (t) =>
          (t.availableFrom.isSameMonthYear(date)) ||
          (t.availableUntil == null && t.availableFrom.isSameOrBeforeMonthYear(date))
    );

    newAmount ??= transactionNewAmounts.firstWhereOrNull(
      (t) =>
          t.availableFrom.isAtSameMomentAs(date) &&
          (t.availableUntil == null ||
              t.availableUntil!.isAtSameMomentAs(date)),
    );

    return newAmount?.amount;
  }
}

class Transaction extends BaseModel {
  final String id; // Document ID
  final String title;
  final String type;
  final String cyklus;
  final String? comment;
  final double amount;
  final DateTime availableFrom;
  DateTime? availableUntil;
  final DocumentReference? categoryRef;
  bool isFixed;
  final List<DocumentReference>? transactionStatusRef; // List of refs
  final List<DocumentReference>? transactionNewAmountsRef; // List of refs
  final List<DocumentReference>? subTransactionsRef; // List of refs to other Transactions
  final DocumentReference? parentRef; // Ref to parent Transaction
  final String? clientId;
  final String? currency;
  final DateTime? timestamp; // For creation/update

  Category? category;
  Debt? debt;
  final Economize? economize = null;
  List<TransactionStatus> transactionStatus = [];
  List<TransactionNewAmount> transactionNewAmounts = [];
  List<Transaction> subTransactions = [];
  final Transaction? parent = null;
  late bool isLoadingDetails = true;

  Transaction({
    required this.id,
    required this.title,
    required this.type,
    required this.cyklus,
    this.comment,
    required this.amount,
    required this.availableFrom,
    required this.availableUntil,
    required this.categoryRef,
    required this.isFixed,
    this.transactionStatusRef,
    this.transactionNewAmountsRef,
    this.subTransactionsRef,
    this.parentRef,
    this.clientId,
    this.currency,
    this.timestamp,
  });


  factory Transaction.fromMap(Map<String, dynamic> json, String id) {
    var tr = Transaction(
      id: id,

      title: json['title'] as String,
      type: json['type'] as String,
      cyklus: json['cyklus'] as String,
      comment: json['comment'] as String?,
      amount: (json['amount'] as num).toDouble(),
      availableFrom: (json['availableFrom'] as Timestamp).toDate(),
      availableUntil: (json['availableUntil'] as Timestamp?)?.toDate(),
      categoryRef: json['categoryRef'] as DocumentReference?,

      isFixed: json['isFixed'] as bool? ?? false,
      transactionStatusRef: (json['transactionStatusRef'] as List<dynamic>?)
          ?.map((ref) => ref as DocumentReference)
          .toList(),
      transactionNewAmountsRef: (json['transactionNewAmountsRef'] as List<dynamic>?)
          ?.map((ref) => ref as DocumentReference)
          .toList(),

      subTransactionsRef: (json['subTransactionsRef'] as List<dynamic>?)
          ?.map((ref) => ref as DocumentReference)
          .toList(),
      // parentRef: json['parentRef'] as DocumentReference?,
      clientId: json['clientId'] as String?,
      currency: json['currency'] as String?,
    );

    tr.isDeleted = (json['isDeleted'] as bool?) ?? false;

    return tr;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'amount': amount,
      'title': title,
      'cyklus': cyklus,
      'type': type,
      'availableFrom': availableFrom,
      'availableUntil': availableUntil,
      'categoryRef': categoryRef,
      'isFixed': isFixed,
      'isSubTransaction': isSubTransaction,
    };
    //if (comment != null) data['comment'] = comment;
    if (transactionStatusRef != null) data['transactionStatusRef'] = transactionStatusRef;
    if (transactionNewAmountsRef != null) data['transactionNewAmountsRef'] = transactionNewAmountsRef;
    if (subTransactionsRef != null) data['subTransactionsRef'] = subTransactionsRef;
    if (parentRef != null) data['parentRef'] = parentRef;
    if (clientId != null) data['clientId'] = clientId;
    if (currency != null) data['currency'] = currency;
    if (isDeleted != null) data['isDeleted'] = isDeleted;
    return data;
  }
}

