import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:my_flutter_web_app/models/category.dart';
import 'package:my_flutter_web_app/models/debt.dart';
import 'package:my_flutter_web_app/models/economize.dart';
import 'package:my_flutter_web_app/models/transaction_new_amount.dart';
import 'package:my_flutter_web_app/models/transaction_status.dart';
import 'package:collection/collection.dart';

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
        (e) => e.toString().split('.').last == type,
        orElse: () => TransactionType.Unknown);
  }

  TransactionCyklus? get cyklusTypisiert {
    return TransactionCyklus.values.firstWhere(
        (e) => e.toString().split('.').last == cyklus,
        orElse: () => TransactionCyklus.Unknown);
  }

  TransactionStatusType? get statusTypisiert {
    return TransactionStatusType.values.firstWhere(
        (e) => e.toString().split('.').last == cyklus,
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
    return transactionStatus.any((t) =>
        t.statusTypisiert == TransactionStatusType.Payed &&
            t.date.month == date!.month);
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

  double? getNewAmount(DateTime date) {
    final formattedDate = DateFormat('yyyy-MM').format(date);

    var newAmount = transactionNewAmounts.firstWhereOrNull(
      (t) =>
          DateFormat('yyyy-MM').format(t.availableFrom) == formattedDate &&
          DateFormat('yyyy-MM').format(t.availableUntil ?? DateTime(1900)) == formattedDate,
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

class Transaction {
  final String id; // Document ID
  final String title;
  final String type;
  final String cyklus;
  final String? comment;
  final double amount;
  final DateTime availableFrom;
  final DateTime? availableUntil;
  final DocumentReference? categoryRef;
  final bool isFixed;
  final List<DocumentReference>? transactionStatusRef; // List of refs
  final List<DocumentReference>? transactionNewAmountsRef; // List of refs
  final List<DocumentReference>? subTransactionsRef; // List of refs to other Transactions
  final DocumentReference? parentRef; // Ref to parent Transaction
  final String? clientId;
  final String? currency;
  final bool? isDeleted;
  final DateTime? timestamp; // For creation/update

  Category? category;
  Debt? debt;
  final Economize? economize = null;
  List<TransactionStatus> transactionStatus = [];
  final List<TransactionNewAmount> transactionNewAmounts = const [];
  final List<Transaction> subTransactions = const [];
  final Transaction? parent = null;

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
    this.isDeleted,
    this.timestamp,
  });


  factory Transaction.fromMap(Map<String, dynamic> json, String id) {
           var title= json['title'] as String;

    try {
      if(title == 'Trinkgeld Burgerking') {
        var a = '';
 
      }

      var type= json['type'] as String;var
      cyklus= json['cyklus'] as String;var
      //comment= json['comment'] as String?;var
      amount= (json['amount'] as num).toDouble();var
      availableFrom= (json['availableFrom'] as Timestamp).toDate();var
      categoryRef= json['categoryRef'] as DocumentReference?;var

      isFixed= json['isFixed'] as bool? ?? false;var
      transactionStatusRef= (json['transactionStatusRef'] as List<dynamic>?)
          ?.map((ref) => ref as DocumentReference)
          .toList();var
      transactionNewAmountsRef= (json['transactionNewAmountsRef'] as List<dynamic>?)
          ?.map((ref) => ref as DocumentReference)
          .toList();var

      subTransactionsRef= (json['subTransactionsRef'] as List<dynamic>?)
          ?.map((ref) => ref as DocumentReference)
          .toList();var
      // parentRef= json['parentRef'] as DocumentReference?;var
      clientId= json['clientId'] as String?;var
      currency= json['currency'] as String?;var
      isDeleted= json['isDeleted'] as bool?;
      } catch (e) {
        print("Error parsing transactions: \$e");
      }
          

    return Transaction(
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
      isDeleted: json['isDeleted'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'name': title,
      'amount': amount,
      'date': Timestamp.fromDate(availableFrom),
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
    if (currentAmount != null) data['amount'] = currentAmount;
    if (currency != null) data['currency'] = currency;
    if (isDeleted != null) data['isDeleted'] = isDeleted;
    if (timestamp != null) data['timestamp'] = Timestamp.fromDate(timestamp!);
    return data;
  }
}
