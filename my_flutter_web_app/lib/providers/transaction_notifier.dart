import 'dart:async';
import 'dart:convert';
import 'package:jiffy/jiffy.dart';
import 'package:collection/collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:my_flutter_web_app/models/category.dart';
import 'package:my_flutter_web_app/models/debt.dart';
import 'package:my_flutter_web_app/models/project.dart';
import 'package:my_flutter_web_app/models/transaction_status.dart';
import 'package:my_flutter_web_app/providers/BaseNotifier.dart';
import 'package:my_flutter_web_app/providers/auth_notifier.dart';
import 'package:my_flutter_web_app/providers/category_notifier.dart';
import 'package:my_flutter_web_app/providers/debt_notifier.dart';
import '../models/transaction.dart' as model;
import '../models/debt.dart' as model_debt;
import '../models/transaction_new_amount.dart';
import '../models/user.dart' as modelUser;

class TransactionNotifier extends BaseNotifier {
  DebtNotifier debtNotifier;
  CategoryNotifier categoryNotifier;
  List<model.Transaction> _transactions = [];
  Map<DateTime, List<model.Transaction>> _transactionsPerMonth = {};
  List<model.Transaction> _filteredTransactions = [];
  bool _isLoading = false;
  StreamSubscription? _transactionSubscription;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  List<model.Transaction> get transactions => _transactions;
  List<model.Transaction> get filteredTransactions => _filteredTransactions;
  bool get isLoading => _isLoading;
  DateTime get selectedMonth => _selectedMonth;

  TransactionNotifier({required this.debtNotifier, required this.categoryNotifier, required AuthNotifier authNotifier}) {
    this.authNotifier = authNotifier;
    categoryNotifier.fetchCategories();
  }

  void loading(bool status) {
    _isLoading = status;
  }

  int filteredTransactionsIndex = 1;
  String searchText = "";
  int filteredIndex = 2;
  List<model.Transaction> filteredTransactionsForView = [];

  setFilteredTransactions() {
    var type = filteredTransactionsIndex == 0
        ? model.TransactionType.Income
        : model.TransactionType.Expense;

    var baseList = filteredTransactions.where((b) => b.typeTypisiert == type);

    var filteredBySearch = baseList.where((tx) {
      return searchText.isEmpty ||
          tx.title.toLowerCase().contains(searchText.toLowerCase());
    }).toList();

    switch (filteredIndex) {
      case 0:
        filteredTransactionsForView = filteredBySearch.where((tx) {
          return !tx.isTransactionDeactivated(selectedMonth) &&
              tx.isTransactionPayed(selectedMonth);
        }).toList();
        break;
      case 1:
        filteredTransactionsForView = filteredBySearch.where((tx) {
          return !tx.isTransactionDeactivated(selectedMonth) &&
              !tx.isTransactionPayed(selectedMonth);
        }).toList();
        break;
      default:
        filteredTransactionsForView = filteredBySearch;
    }

    notifyListeners();
  }

  void selectMonth(DateTime month) async {
    _selectedMonth = DateTime(month.year, month.month, 1);
    _transactions = [];
    _filteredTransactions = [];
    filteredTransactionsForView.clear();
    notifyListeners();
    fetchTransactions();
  }

  Map<DateTime, List<TransactionStatus>> dic = {};
  Map<DateTime, List<TransactionNewAmount>> dicNewAmounts = {};

  Future<model.Transaction> BuildTransactionFromDoc(DocumentReference doc) async {
    var transaction = await readRef(doc, model.Transaction.fromMap);
    return BuildTransactionWithBoth(transaction!, doc);
  }

  Future<model.Transaction> BuildTransactionWithBoth(
      model.Transaction transaction, DocumentReference ref) async {
    transaction.category =
        await readRef(transaction.categoryRef, Category.fromMap);

    final snapshot = await firestore
        .collection('debt')
        .where('transactionRef', isEqualTo: ref)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      final id = snapshot.docs.first.id;

      if (data.isNotEmpty) {
        final debt = model_debt.Debt.fromMap(data, id);
        transaction.debt = await debtNotifier.buildDebt(debt);

        final restMonth = transaction.debt?.restMonth ?? 0;
        if (restMonth == 0) {
          transaction.availableUntil = debt.lastPaymentDate;
        } else {
          transaction.availableUntil = Jiffy.parseFromDateTime(DateTime.now())
              .add(months: restMonth)
              .dateTime;
        }
      }
    }

    if ((transaction.transactionNewAmountsRef ?? []).isNotEmpty) {
      final snapshot = await firestore
          .collection('transactionNewAmount')
          .where(FieldPath.documentId,
              whereIn: transaction.transactionNewAmountsRef)
          .get();

      transaction.transactionNewAmounts = snapshot.docs
          .map((doc) => TransactionNewAmount.fromMap(doc.data(), doc.id))
          .toList();
    }

    if ((transaction.transactionStatusRef ?? []).isNotEmpty) {
      final snapshot = await firestore
          .collection('transactionStatus')
          .where(FieldPath.documentId,
              whereIn: transaction.transactionStatusRef)
          .where('date', isEqualTo: selectedMonth)
          .get();

      transaction.transactionStatus = snapshot.docs
          .map((doc) => TransactionStatus.fromMap(doc.data(), doc.id))
          .toList();
    }

    if ((transaction.subTransactionsRef ?? []).isNotEmpty) {
      final snapshot = await firestore
          .collection('transaction')
          .where(FieldPath.documentId,
              whereIn: transaction.subTransactionsRef)
          .get();

      transaction.subTransactions = snapshot.docs
          .map((doc) => model.Transaction.fromMap(doc.data(), doc.id))
          .toList();
    }

    return transaction;
  }

  void reset() {
    _transactions = [];
    _filteredTransactions = [];
    _transactionsPerMonth = {};
    notifyListeners();
  }


Future<void> fetchTransactions() async {
  if (authNotifier!.user == null) {
    _transactions = [];
    _isLoading = false;
    notifyListeners();
    return;
  }

  _isLoading = true;
  notifyListeners();

  if (!_transactionsPerMonth.keys.contains(selectedMonth)) {
    _transactions.clear();

    final startOfMonth = DateTime(selectedMonth.year, selectedMonth.month);
    final nextMonth = Jiffy.parseFromDateTime(startOfMonth)
        .add(months: 1)
        .dateTime;

    print(authNotifier!.project!.projectIdentification);
    print(selectedMonth);

    final fixedQuery = await firestore
        .collection('transaction')
        .where("clientId", isEqualTo: authNotifier!.project!.projectIdentification)
        .where("isFixed", isEqualTo: true)
        .where("availableFrom", isLessThan: nextMonth)
        .where("availableUntil", isGreaterThanOrEqualTo: startOfMonth)
        .get();

    final fixedNullUntilQuery = await firestore
        .collection('transaction')
        .where("clientId", isEqualTo: authNotifier!.project!.projectIdentification)
        .where("isFixed", isEqualTo: true)
        .where("availableFrom", isLessThan: nextMonth)
        .where("availableUntil", isNull: true)
        .get();

    final nonFixedQuery = await firestore
        .collection('transaction')
        .where("clientId", isEqualTo: authNotifier!.project!.projectIdentification)
        .where("isFixed", isEqualTo: false)
        .where("availableFrom", isGreaterThanOrEqualTo: startOfMonth)
        .where("availableFrom", isLessThan: nextMonth)
        .get();

    final allDocs = [
      ...fixedQuery.docs,
      ...fixedNullUntilQuery.docs,
      ...nonFixedQuery.docs,
    ];

    // --------- Optimierung: Batch-Laden aller Referenzen ---------
final allTransactionsWithRef = allDocs
    .where((doc) => doc['isDeleted'] != true)
    .map((doc) => MapEntry(doc.reference, model.Transaction.fromMap(doc.data(), doc.id)))
    .toList();

    final allTransactions = allTransactionsWithRef.map((e) => e.value).toList();

    // Sammle alle Referenzen
    final categoryRefs = allTransactions
        .map((t) => t.categoryRef)
        .where((ref) => ref != null)
        .toSet()
        .toList();

    final transactionStatusRefs = <String>[];
    final transactionNewAmountRefs = <String>[];
    final subTransactionRefs = <String>[];

for (var t in allTransactions) {
  if (t.transactionStatusRef != null) {
    transactionStatusRefs.addAll(
      (t.transactionStatusRef! as List)
          .map((ref) => ref is String ? ref : (ref as DocumentReference).id)
          .toList()
    );
  }
  if (t.transactionNewAmountsRef != null) {
    transactionNewAmountRefs.addAll(
      (t.transactionNewAmountsRef! as List)
          .map((ref) => ref is String ? ref : (ref as DocumentReference).id)
          .toList()
    );
  }
  if (t.subTransactionsRef != null) {
    subTransactionRefs.addAll(
      (t.subTransactionsRef! as List)
          .map((ref) => ref is String ? ref : (ref as DocumentReference).id)
          .toList()
    );
  }
}

    // batch laden
    Map<String, Category> categories = {};
    if (allTransactions.isNotEmpty) {
      final transactionIds = allTransactions
          .map((t) => t.categoryRef)
          .where((ref) => ref != null)
          .map((ref) => ref!.id)
          .toList();

      final categoryChunks = transactionIds.slices(30);
      for (final chunk in categoryChunks) {
        final snap = await firestore
            .collection('category')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (var doc in snap.docs) {
          categories[doc.id] = Category.fromMap(doc.data(), doc.id);
        }
      }
    }

    // Debts batch laden: Hole alle Debts, deren transactionRef auf eine der geladenen Transaktionen zeigt
    Map<String, model_debt.Debt> debts = {};
    if (allTransactions.isNotEmpty) {
      final transactionIds = allTransactionsWithRef.map((e) => e.key).toList();
      final debtChunks = transactionIds.slices(30);
      for (final chunk in debtChunks) {
        final snap = await firestore
            .collection('debt')
            .where('transactionRef', whereIn: chunk)
            .get();

            print('debt holen');
        for (var doc in snap.docs) {
          final debt = model_debt.Debt.fromMap(doc.data(), doc.id);
          // Mappe nach transactionId!
          debts[doc['transactionRef'].id] = debt;
        }
      }
    }

    print(transactionStatusRefs.length);
    final statusChunks = transactionStatusRefs.toSet().toList().slices(30);
   Map<String, TransactionStatus> statuses = {};

  for (final chunk in statusChunks) {
    final snap = await firestore
        .collection('transactionStatus')
        .where(FieldPath.documentId, whereIn: chunk)
        .where('date', isEqualTo: selectedMonth)
        .get();

        print('transactionStatus');
    for (var doc in snap.docs) {
          statuses[doc.id] = TransactionStatus.fromMap(doc.data(), doc.id);
    }
  }

    // TransactionNewAmount batch laden
    Map<String, TransactionNewAmount> newAmounts = {};
    if (transactionNewAmountRefs.isNotEmpty) {
      final newAmountChunks = transactionNewAmountRefs.toSet().toList().slices(30);
      for (final chunk in newAmountChunks) {
        final snap = await firestore
            .collection('transactionNewAmount')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (var doc in snap.docs) {
          newAmounts[doc.id] = TransactionNewAmount.fromMap(doc.data(), doc.id);
        }
      }
    }

    // SubTransactions batch laden
    Map<String, model.Transaction> subTransactions = {};
    if (subTransactionRefs.isNotEmpty) {
      final subChunks = subTransactionRefs.toSet().toList().slices(30);
      for (final chunk in subChunks) {
        final snap = await firestore
            .collection('transaction')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (var doc in snap.docs) {
          subTransactions[doc.id] = model.Transaction.fromMap(doc.data(), doc.id);
        }
      }
    }

    // --------- Transaktionen zusammensetzen ---------
    _transactions.clear();
    for (var transaction in allTransactions) {
      // Kategorie
      if (transaction.categoryRef != null) {
        transaction.category = categories[transaction.categoryRef!.id];
      }

      // Debt: jetzt korrekt!
      if (debts.containsKey(transaction.id)) {
        transaction.debt = await debtNotifier.buildDebt(debts[transaction.id]!);
        final restMonth = transaction.debt?.restMonth ?? 0;
        if(transaction.debt?.isPayed == true) {
          continue; // Wenn die Schuld abbezahlt ist, überspringe diese Transaktion //TODO: Überdenken, ob das so gewollt ist
        } else if (restMonth == 0) {
          transaction.availableUntil = transaction.debt?.lastPaymentDate;
        } else {
          transaction.availableUntil = Jiffy.parseFromDateTime(DateTime.now())
              .add(months: restMonth)
              .dateTime;
        }
      }

      // Status
      if ((transaction.transactionStatusRef ?? []).isNotEmpty) {
        transaction.transactionStatus = transaction.transactionStatusRef!
            .map((id) => statuses[id.id])
            .whereType<TransactionStatus>()
            .toList();

      }

      // NewAmounts
      if ((transaction.transactionNewAmountsRef ?? []).isNotEmpty) {
        transaction.transactionNewAmounts = transaction.transactionNewAmountsRef!
            .map((id) => newAmounts[id.id])
            .whereType<TransactionNewAmount>()
            .toList();
      }

      // SubTransactions
      if ((transaction.subTransactionsRef ?? []).isNotEmpty) {
        transaction.subTransactions = transaction.subTransactionsRef!
            .map((id) => subTransactions[id.id])
            .whereType<model.Transaction>()
            .toList();
      }

      transaction.isLoadingDetails = false;
      _transactions.add(transaction);
    }

    _transactionsPerMonth[selectedMonth] = _transactions;
  } else {
    _transactions = _transactionsPerMonth[selectedMonth]!;
  }

  _isLoading = false;
  _filteredTransactions = _transactions
      .where((transaction) => checkTransactionForMonth(transaction, selectedMonth))
      .toList();
  setFilteredTransactions();
  notifyListeners();
}

  Future<DocumentReference> addTransaction(model.Transaction transaction) async {
    if (authNotifier!.user == null) {
      throw Exception("User not logged in");
    }

    Map<String, dynamic> transactionData = transaction.toJson();
    completeAdd(transactionData);

    _isLoading = true;

    try {
      var doc = await firestore.collection('transaction').add(transactionData);
      var newtr = await BuildTransactionFromDoc(doc);
      filteredTransactions.add(newtr);
      setFilteredTransactions();
      return doc;
    } catch (e) {
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTransaction(model.Transaction transaction) async {
    if (authNotifier!.user == null) throw Exception("User not logged in");
    Map<String, dynamic> transactionData = transaction.toJson();
    transactionData = completeUpdate(transactionData);

    await firestore.collection('transaction').doc(transaction.id).update(transactionData);

    var index = _transactionsPerMonth[selectedMonth]?.indexWhere((b) => b.id == transaction.id);
    var ref = await getRef(transaction.id, 'transaction');
    _transactionsPerMonth[selectedMonth]?[index!] = await BuildTransactionWithBoth(transaction, ref!);
    setFilteredTransactions();
  }

  Future<void> deleteTransaction(model.Transaction transaction) async {
    if (authNotifier!.user == null) throw Exception("User not logged in");

    transaction.isDeleted = true;
    Map<String, dynamic> transactionData = transaction.toJson();
    transactionData = completeUpdate(transactionData);
    await firestore.collection('transaction').doc(transaction.id).update(transactionData);
    var index = _transactionsPerMonth[selectedMonth]?.indexWhere((b) => b.id == transaction.id);
    filteredTransactions.removeAt(index!);
    
    setFilteredTransactions();
  }

  @override
  void dispose() {
    _transactionSubscription?.cancel();
    super.dispose();
  }

  double get incomesTotal {
    return filteredTransactions
        .where((b) => b.typeTypisiert == model.TransactionType.Income)
        .fold(0.0, (sum, p) => sum + (p.isTransactionDeactivated(selectedMonth) ? 0 : p.getAmount(selectedMonth)));
  }

  double get expensesTotal {
    return filteredTransactions
        .where((b) => b.typeTypisiert == model.TransactionType.Expense)
        .fold(0.0, (sum, p) => sum + (p.isTransactionDeactivated(selectedMonth) ? 0 : p.getAmount(selectedMonth)));
  }

  double get difference {
    return incomesTotal - expensesTotal;
  }

  bool checkTransactionForMonth(model.Transaction transaction, DateTime selectedMonth) {
    final bool firstCheck =
        (transaction.parent == null &&
            transaction.isFixed &&
            (transaction.availableFrom.isSameOrBeforeMonthYear(selectedMonth) &&
                (transaction.availableUntil == null ||
                    selectedMonth.isSameOrBeforeMonthYear(transaction.availableUntil!)))) ||
        (!transaction.isFixed &&
            selectedMonth.isSameMonthYear(transaction.availableFrom));

    if (!firstCheck) {
      return false;
    }

    bool secondCheck = false;
    int count;
    switch (transaction.cyklusTypisiert) {
      case model.TransactionCyklus.Quarterly:
        count = 3;
        break;
      case model.TransactionCyklus.Year:
        count = 12;
        break;
      default:
        count = 1;
        break;
    }

    int dif = selectedMonth.monthsDifferenceTo(transaction.availableFrom);
    if (dif % count == 0) {
      secondCheck = true;
    }

    return firstCheck && secondCheck;
  }

  void addDataTransactionStatus({
    required TransactionStatus status,
    required model.Transaction transaction,
    required Null Function() callback,
  }) async {
    if (authNotifier!.user == null) throw Exception("User not logged in");

    DocumentReference ref = firestore.collection('transactionStatus').doc();
    Map<String, dynamic> statusData = status.toMap();
    statusData = completeAdd(statusData);

    WriteBatch batch = firestore.batch();
    batch.set(ref, statusData);

    DocumentReference debtDocRef = firestore.collection('transaction').doc(transaction.id);
    batch.update(debtDocRef, {
      'transactionStatusRef': FieldValue.arrayUnion([ref]),
    });

    await batch.commit();
    callback.call();
    notifyListeners();
  }

  void deleteDataTransactionStatus({
    required TransactionStatus status,
    required model.Transaction transaction,
    required Null Function() callback,
  }) async {
    DocumentReference statusRef = firestore.collection('transactionStatus').doc(status.id);
    DocumentReference debtDocRef = firestore.collection('transaction').doc(transaction.id);

    WriteBatch batch = firestore.batch();
    batch.delete(statusRef);
    batch.update(debtDocRef, {
      'transactionStatusRef': FieldValue.arrayRemove([transaction.transactionStatusRef])
    });

    await batch.commit();
    callback.call();
  }
}

extension MonthYearComparison on DateTime {
  bool isBeforeMonthYear(DateTime other) {
    return year < other.year || (year == other.year && month < other.month);
  }

  bool isAfterMonthYear(DateTime other) {
    return year > other.year || (year == other.year && month > other.month);
  }

  bool isSameMonthYear(DateTime other) {
    return year == other.year && month == other.month;
  }

  bool isSameOrAfterMonthYear(DateTime other) {
    return !isBeforeMonthYear(other);
  }

  bool isSameOrBeforeMonthYear(DateTime other) {
    return !isAfterMonthYear(other);
  }

  String get MYLongString {
    return DateFormat('MMMM yyyy').format(this);
  }

  String get MYString {
    return DateFormat('MM yyyy').format(this);
  }

  int monthsDifferenceTo(DateTime other) {
    return (year - other.year) * 12 + (month - other.month);
  }
}

