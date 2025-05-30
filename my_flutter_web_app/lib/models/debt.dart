import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_flutter_web_app/models/baseModel.dart';
import 'package:my_flutter_web_app/models/payment.dart';
import 'package:my_flutter_web_app/models/transaction.dart' as transaction_model;

enum PaymentMode { installment, oneTime, none }

enum PaymentMethod {
  none,
  keine,
  paypal,
  transfer,
  cash,
  directDebit
}

extension DebtModelExtensions on Debt {
  PaymentMode get paymentModeTyped {
    switch (paymentMode.toLowerCase()) {
      case 'installment':
        return PaymentMode.installment;
      case 'onetime':
        return PaymentMode.oneTime;
      default:
        return PaymentMode.none;
    }
  }

  PaymentMethod get paymentMethodTyped {
    switch (paymentMethod.toLowerCase()) {
      case 'paypal':
        return PaymentMethod.paypal;
      case 'transfer':
        return PaymentMethod.transfer;
      case 'cash':
        return PaymentMethod.cash;
      default:
        return PaymentMethod.none;
    }
  }

  double get restAmount {
    double rest = amount;
    for (var p in payments) {
      if ((interest ?? 0) > 0) {
        rest *= (1 + (interest ?? 0) / 100);
      }
      rest -= p.amount;
    }
    return rest;
  }

  double get payedAmount {
  return payments.fold(0.0, (sum, payment) => sum + (payment.amount));
  }

  int get restMonth {
    switch (paymentModeTyped) {
      case PaymentMode.installment:
        final count = restAmount / paymentAmount;
        return count.isFinite ? count.ceil() : 0;
      case PaymentMode.oneTime:
        return 1;
      case PaymentMode.none:
        return 0;
    }
  }

  int get payMonth {
    final count = amount / paymentAmount;
    return count.isFinite ? count.ceil() : 0;
  }

  bool get isPayed => restAmount <= 0.001;

  bool get isInstallment => paymentModeTyped == PaymentMode.installment;
  bool get isOneTime => paymentModeTyped == PaymentMode.oneTime;

  DateTime get lastPaymentDate {
    switch (paymentModeTyped) {
      case PaymentMode.installment:
        return DateTime(
          firstPaymentDate.year,
          firstPaymentDate.month + payMonth - 1,
          firstPaymentDate.day,
        );
      case PaymentMode.oneTime:
        return firstPaymentDate;
      case PaymentMode.none:
        return DateTime.now();
    }
  }

  double get lastPaymentAmount {
    if (paymentModeTyped != PaymentMode.installment) return 0;
    final count = amount / paymentAmount;
    final remainder = count % 1;
    return paymentAmount * remainder;
  }

  bool get hasLastPaymentAmount => lastPaymentAmount != 0 && lastPaymentAmount != paymentAmount;
}

class Debt extends BaseModel {
  final String creditor;
  final double amount;
  final String paymentMode;
  final String paymentMethod;
  final double paymentAmount;
  final double? interest;
  final DateTime firstPaymentDate;
  final DateTime dueDate;
  final String? iban;
  final String? bic;
  final String? bankName;
  final String? bankAccountHolder;
  final String? paypalEmail;
  final String? reason;
  final String? comment;
  final String? currency;
  final bool addPaymentAuto;
  final int? position;
  final List<DocumentReference?> paymentRefs;
  final List<String> datas;
  final DocumentReference? transactionRef;

  List<Payment> payments;
  transaction_model.Transaction? transaction;

  Debt({
    String? id,
    String? clientId,
    DateTime? creationTime,
    DateTime? lastUpdateTime,
    required this.creditor,
    required this.amount,
    required this.paymentMode,
    required this.paymentMethod,
    required this.paymentAmount,
    required this.firstPaymentDate,
    required this.dueDate,
    required this.comment,
    required this.currency,
    this.interest,
    this.iban,
    this.bic,
    this.bankName,
    this.bankAccountHolder,
    this.paypalEmail,
    this.reason,
    this.addPaymentAuto = false,
    this.position,
    this.paymentRefs = const [],
    this.datas = const [],
    this.transactionRef,
    this.payments = const [],
  }) : super(id: id, clientId: clientId, creationTime: creationTime, lastUpdateTime: lastUpdateTime);

  factory Debt.fromMap(Map<String, dynamic> map, String docId) { 
    try {
var clientId= map['clientId']; var
        creditor= map['creditor'] ?? ''; var
        amount= (map['amount'] ?? 0).toDouble(); var
        paymentMode= map['paymentMode'] ?? ''; var
        paymentMethod= map['paymentMethod'] ?? ''; var
        paymentAmount= (map['paymentAmount'] ?? 0).toDouble(); var
        interest= (map['interest'] ?? 0).toDouble(); var
        firstPaymentDate= (map['firstPaymentDate'] as Timestamp).toDate(); var
        dueDate= (map['dueDate'] as Timestamp).toDate(); var
        iban= map['iban']; var
        bic= map['bic']; var
        bankName= map['bankName']; var
        bankAccountHolder= map['bankAcountHolder']; var
        paypalEmail= map['paypalEmail']; var
        reason= map['reason']; var
        comment= map['comment']; var
        currency= map['currency']; var
        addPaymentAuto= map['addPaymentAuto'] ?? false; var
        position= map['position']; var
        paymentRefs= List<DocumentReference?>.from(map['paymentRefs'] ?? []); var
        datas= List<String>.from(map['datas'] ?? []); var
        transactionRef= map['transactionRef']; var
        creationTime= (map['creationTime'] as Timestamp?)?.toDate(); var
        lastUpdateTime= (map['lastUpdateTime'] as Timestamp?)?.toDate();
    }
    catch (ex) {
      print(docId);
    }

    return Debt(
        id: docId,
        clientId: map['clientId'],
        creditor: map['creditor'] ?? '',
        amount: (map['amount'] ?? 0).toDouble(),
        paymentMode: map['paymentMode'] ?? '',
        paymentMethod: map['paymentMethod'] ?? '',
        paymentAmount: (map['paymentAmount'] ?? 0).toDouble(),
        interest: (map['interest'] ?? 0).toDouble(),
        firstPaymentDate: (map['firstPaymentDate'] as Timestamp).toDate(),
        dueDate: (map['dueDate'] as Timestamp).toDate(),
        iban: map['iban'],
        bic: map['bic'],
        bankName: map['bankName'],
        bankAccountHolder: map['bankAcountHolder'],
        paypalEmail: map['paypalEmail'],
        reason: map['reason'],
        comment: map['comment'],
        currency: map['currency'],
        addPaymentAuto: map['addPaymentAuto'] ?? false,
        position: map['position'],
        paymentRefs: List<DocumentReference?>.from(map['paymentRefs'] ?? []),
        datas: List<String>.from(map['datas'] ?? []),
        transactionRef: map['transactionRef'],
        creationTime: (map['creationTime'] as Timestamp?)?.toDate(),
        lastUpdateTime: (map['lastUpdateTime'] as Timestamp?)?.toDate(),
      );
  }

  Map<String, dynamic> toMap() => {
        'creditor': creditor,
        'amount': amount,
        'paymentMode': paymentMode,
        'paymentMethod': paymentMethod,
        'paymentAmount': paymentAmount,
        'interest': interest,
        'firstPaymentDate': firstPaymentDate,
        'iban': iban,
        'bic': bic,
        'bankName': bankName,
        'bankAcountHolder': bankAccountHolder,
        'paypalEmail': paypalEmail,
        'reason': reason,
        'addPaymentAuto': addPaymentAuto,
        'position': position,
        'paymentRefs': paymentRefs,
        'datas': datas,
        'transactionRef': transactionRef,
        'clientId': clientId,
        'creationTime': creationTime,
        'lastUpdateTime': lastUpdateTime,
      };
}