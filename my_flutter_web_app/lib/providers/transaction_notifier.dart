import 'dart:async';
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
import 'package:my_flutter_web_app/providers/debt_notifier.dart';
import '../models/transaction.dart' as model;
import '../models/debt.dart' as model_debt;
import '../models/transaction_new_amount.dart';
import '../models/user.dart' as modelUser;

class TransactionNotifier extends BaseNotifier {

  DebtNotifier debtNotifier;
  List<model.Transaction> _transactions = [];
  Map<DateTime, List<model.Transaction>> _transactionsPerMonth = {};

  List<model.Transaction> _filteredTransactions = [];

  bool _isLoading = false;
  StreamSubscription? _transactionSubscription;
  User? _currentUser;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1); // Normalized to start of month

  List<model.Transaction> get transactions => _transactions;
  List<model.Transaction> get filteredTransactions => _filteredTransactions;

  bool get isLoading => _isLoading;
  DateTime get selectedMonth => _selectedMonth;

  TransactionNotifier({required this.debtNotifier}) {
    _currentUser = auth.currentUser;
    // if (_currentUser != null) {
    //   fetchTransactions(); // Initial fetch for the default selectedMonth (current month)
    // }

    auth.authStateChanges().listen((user) {
      _currentUser = user;
      if (_currentUser != null) {

        // Reset selectedMonth to current month on new login if desired, or keep existing
        // _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
        fetchTransactions();
      } else {
        _transactions = [];
        _transactionSubscription?.cancel();
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  void loading(bool status){
    _isLoading = status;
  }

  int filteredTransactionsIndex = 1;
  String searchText = "";
  int filteredIndex = 2;
  
  List<model.Transaction> filteredTransactionsForView = [];

  setFilteredTransactions() {
    var type = filteredTransactionsIndex == 0 ? model.TransactionType.Income 
                : model.TransactionType.Expense;

    var baseList = filteredTransactions
    .where((b) => b.typeTypisiert == type);

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
    _isLoading = false;
    notifyListeners();
    }
  }

  void selectMonth(DateTime month) async {
    _selectedMonth = DateTime(month.year, month.month, 1); // Normalize to start of month
    notifyListeners(); // Notify listeners about month change for UI update
    
    fetchTransactions(); // Re-fetch transactions for the new month
  }

  Map<DateTime, List<TransactionStatus>> dic = {};
  Map<DateTime, List<TransactionNewAmount>> dicNewAmounts = {};

  Future<model.Transaction> BuildTransactionFromDoc(DocumentReference doc) async {
      var transaction = await readRef(doc, model.Transaction.fromMap);
      return BuildTransactionWithBoth(transaction!, doc);
  }

  Future<model.Transaction> BuildTransactionWithBoth(model.Transaction transaction, DocumentReference ref) async {

    transaction.category = await readRef(transaction.categoryRef, Category.fromMap);

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
      if(restMonth == 0)
      {
        transaction.availableUntil = debt.lastPaymentDate;
      } else {
      transaction.availableUntil = Jiffy.parseFromDateTime(DateTime.now())
          .add(months: restMonth)
          .dateTime;
      }
    }
  }

    if ((transaction.transactionNewAmountsRef  ?? []).isNotEmpty) {
      final snapshot = await firestore
                          .collection('transactionNewAmount') // passe an deine Collection an
                          .where(FieldPath.documentId, whereIn: transaction.transactionNewAmountsRef)
                          // .where('date', isEqualTo: selectedMonth)
                          .get();

      transaction.transactionNewAmounts = snapshot.docs
      .map((doc) => TransactionNewAmount.fromMap(doc.data(), doc.id))
      .toList();
    }

    if ((transaction.transactionStatusRef  ?? []).isNotEmpty) {
      final snapshot = await firestore
                          .collection('transactionStatus') // passe an deine Collection an
                          .where(FieldPath.documentId, whereIn: transaction.transactionStatusRef)
                          .where('date', isEqualTo: selectedMonth)
                          .get();

      transaction.transactionStatus = snapshot.docs
      .map((doc) => TransactionStatus.fromMap(doc.data(), doc.id))
      .toList();
    }

    if ((transaction.subTransactionsRef  ?? []).isNotEmpty) {
      final snapshot = await firestore
                          .collection('transaction') // passe an deine Collection an
                          .where(FieldPath.documentId, whereIn: transaction.subTransactionsRef)
                          .get();

      transaction.subTransactions = snapshot.docs
      .map((doc) => model.Transaction.fromMap(doc.data(), doc.id))
      .toList();
    }

    return transaction;
  }

void fetchTransactions() async {
  if (_currentUser == null) {
    _transactions = [];
    _isLoading = false;
    notifyListeners();
    return;
  }

  _isLoading = true;

  if (!_transactionsPerMonth.keys.contains(selectedMonth)) {
    _transactions.clear();

    final startOfMonth = DateTime(selectedMonth.year, selectedMonth.month);
    final nextMonth = Jiffy.parseFromDateTime(startOfMonth)
          .add(months: 1)
          .dateTime;

    // await firestore.collection('transaction').add({
    //   'availableUntil': null, // explizit setzen
    // });

final fixedQuery = await firestore
    .collection('transaction')
    .where("clientId", isEqualTo: "1735421-1353-53")
    .where("isFixed", isEqualTo: true)
    .where("availableFrom", isLessThan: nextMonth)
    .where("availableUntil", isGreaterThanOrEqualTo: startOfMonth) // Nur die >=-Fälle
    .get();

final fixedNullUntilQuery = await firestore
    .collection('transaction')
    .where("clientId", isEqualTo: "1735421-1353-53")
    // .where("parent", isNull: true)
    .where("isFixed", isEqualTo: true)
    .where("availableFrom", isLessThan: nextMonth)
    .where("availableUntil", isNull: true) // Die NULL-Fälle
    .get();

final nonFixedQuery = await firestore
    .collection('transaction')
    .where("clientId", isEqualTo: "1735421-1353-53")
    .where("isFixed", isEqualTo: false)
    .where("availableFrom", isGreaterThanOrEqualTo: startOfMonth)
    .where("availableFrom", isLessThan: nextMonth)
    .get();

// 👇 Alle Ergebnisse kombinieren
final allDocs = [
  ...fixedQuery.docs,
  ...fixedNullUntilQuery.docs,
  ...nonFixedQuery.docs,
];

    // var result = allDocs.map((b) => model.Transaction.fromMap(b.data(), b.id)).toList();

    // final result = await fetchAll('transaction', model.Transaction.fromMap);
    // print('Fetch all');

    // _transactions = result.where((b) => !b.isDeleted).toList();

    for (int i = 0; i < allDocs.length; i++) {
      var doc = allDocs[i];

      if(doc['isDeleted'] == true) {
        continue;
      }

      final updated = await BuildTransactionWithBoth(model.Transaction.fromMap(doc.data(), doc.id), doc.reference);
      updated.isLoadingDetails = false;
      _transactions.add(updated);
    }    

      _transactionsPerMonth[selectedMonth] = _transactions;
  }
  else {
    _transactions = _transactionsPerMonth[selectedMonth]!;
  }

  // Lade ggf. Statusdaten
  // if (!dic.containsKey(selectedMonth)) {
  //   final snapshot = await firestore
  //       .collection('transactionStatus')
  //       .where('date', isEqualTo: selectedMonth)
  //       .get();

  //   final status = snapshot.docs
  //       .map((doc) => TransactionStatus.fromMap(doc.data(), doc.id))
  //       .toList();

  //   if (status.isNotEmpty) {
  //     dic[selectedMonth] = status;
  //   }
  // }

  // // Mappe Statusdaten auf Transaktionen
  // for (var toElement in _filteredTransactions) {
  //   final potStatus = dic[selectedMonth]
  //           ?.where((status) =>
  //               toElement.transactionStatusRef?.any((ref) => ref.id == status.id) == true)
  //           .toList() ??
  //       [];

  //   final potNewAmounts = dicNewAmounts[selectedMonth]
  //           ?.where((status) =>
  //               toElement.transactionNewAmountsRef?.any((ref) => ref.id == status.id) == true)
  //           .toList() ??
  //       [];

  //   toElement.transactionStatus = potStatus;
  //   toElement.transactionNewAmounts = potNewAmounts;
  // }

    _filteredTransactions = _transactions.where((transaction) => checkTransactionForMonth(transaction, selectedMonth)).toList();
    setFilteredTransactions();
    notifyListeners();
    _isLoading = false;
  }

  Future<DocumentReference> addTransaction(model.Transaction transaction) async {
    if (_currentUser == null) {
      print("Cannot add transaction: No user logged in.");
      throw Exception("User not logged in");
    }
    
    Map<String, dynamic> transactionData = transaction.toJson();
    completeAdd(transactionData);

    _isLoading = true; // This might cause UI flicker if stream updates quickly.

    try {
      var doc = await firestore.collection('transaction').add(transactionData);

      var newtr = await BuildTransactionFromDoc(doc);
      filteredTransactions.add(newtr);
      setFilteredTransactions();

      return doc;
    } catch (e) {
      print("Error adding transaction: $e");
      throw e; 
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> updateTransaction(model.Transaction transaction) async {
    if (_currentUser == null) throw Exception("User not logged in");
    Map<String, dynamic> transactionData = transaction.toJson();
    transactionData = completeUpdate(transactionData);

    await firestore.collection('transaction').doc(transaction.id).update(transactionData);

    var index = filteredTransactions.indexWhere((b) => b.id == transaction.id);

    var ref = await getRef(transaction.id, 'transaction');
    filteredTransactions[index] = await BuildTransactionWithBoth(transaction, ref!);    
    setFilteredTransactions();
  }

  Future<void> deleteTransaction(model.Transaction transaction) async {
    if (_currentUser == null) throw Exception("User not logged in");

    transaction.isDeleted = true;
    Map<String, dynamic> transactionData = transaction.toJson();
    transactionData = completeUpdate(transactionData);    
    await firestore.collection('transaction').doc(transaction.id).update(transactionData);
    var index = filteredTransactions.indexWhere((b) => b.id == transaction.id);
    filteredTransactions.removeAt(index);

    setFilteredTransactions();
  }

  @override
  void dispose() {
    _transactionSubscription?.cancel();
    super.dispose();
  }

  double get incomesTotal {
    return filteredTransactions.where((b) => b.typeTypisiert == model.TransactionType.Income).fold(0.0, (sum, p) => sum + (p.isTransactionDeactivated(selectedMonth) ? 0 : p.getAmount(selectedMonth)));
  }

   double get expensesTotal {
    return filteredTransactions.where((b) => b.typeTypisiert == model.TransactionType.Expense).fold(0.0, (sum, p) => sum + (p.isTransactionDeactivated(selectedMonth) ? 0 :p.getAmount(selectedMonth)));
  }

   double get difference{
    return incomesTotal - expensesTotal;
  }
  
  bool checkTransactionForMonth(model.Transaction transaction, DateTime selectedMonth) {
    print(transaction.title);

    final bool firstCheck = 
        (transaction.parent == null && transaction.isFixed &&
            (transaction.availableFrom.isSameOrBeforeMonthYear(selectedMonth) &&
            (transaction.availableUntil == null || selectedMonth.isSameOrBeforeMonthYear(transaction.availableUntil!)))) ||
        (!transaction.isFixed && selectedMonth.isSameMonthYear(transaction.availableFrom));

    if(!firstCheck) {
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

  void addDataTransactionStatus({required TransactionStatus status, required model.Transaction transaction, required Null Function() callback}) async {
   if (_currentUser == null) throw Exception("User not logged in");

    DocumentReference ref = firestore.collection('transactionStatus').doc(); // Generate ID for payment
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

  void deleteDataTransactionStatus({required TransactionStatus status, required model.Transaction transaction, required Null Function() callback}) async {
      DocumentReference statusRef = firestore.collection('transactionStatus').doc(status.id); // Generate ID for payment
      DocumentReference debtDocRef = firestore.collection('transaction').doc(transaction.id);

      WriteBatch batch = firestore.batch();
      batch.delete(statusRef); // Delete the payment
      batch.update(debtDocRef, { // Update the debt
        'transactionStatusRef': FieldValue.arrayRemove([transaction.transactionStatusRef])
      });

    await batch.commit();
    callback.call();
  }
}

extension MonthYearComparison on DateTime {
  /// Gibt true zurück, wenn dieses Datum vor dem anderen Datum liegt (Monat + Jahr Vergleich)
  bool isBeforeMonthYear(DateTime other) {
    return year < other.year || (year == other.year && month < other.month);
  }

  /// Gibt true zurück, wenn dieses Datum nach dem anderen Datum liegt (Monat + Jahr Vergleich)
  bool isAfterMonthYear(DateTime other) {
    return year > other.year || (year == other.year && month > other.month);
  }

  /// Gibt true zurück, wenn dieses Datum im gleichen Monat und Jahr wie das andere Datum liegt
  bool isSameMonthYear(DateTime other) {
    return year == other.year && month == other.month;
  }

  /// true, wenn gleich oder nach dem anderen Datum (Monat + Jahr)
  bool isSameOrAfterMonthYear(DateTime other) {
    return !isBeforeMonthYear(other);
  }

  /// true, wenn gleich oder vor dem anderen Datum (Monat + Jahr)
  bool isSameOrBeforeMonthYear(DateTime other) {
    return !isAfterMonthYear(other);
  }

  String get MYLongString {
    return DateFormat('MMMM yyyy').format(this); // z. B. "16. Mai 2025"
  }

  String get MYString {
    return DateFormat('MM yyyy').format(this); // z. B. "16. Mai 2025"
  }
  /// Gibt die Differenz in Monaten zwischen diesem Datum und [other]
  int monthsDifferenceTo(DateTime other) {
    return (year - other.year) * 12 + (month - other.month);
  }
}

