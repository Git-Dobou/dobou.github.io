import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:my_flutter_web_app/models/category.dart';
import 'package:my_flutter_web_app/models/project.dart';
import 'package:my_flutter_web_app/models/transaction_status.dart';
import 'package:my_flutter_web_app/providers/BaseNotifier.dart';
import '../models/transaction.dart' as model;
import '../models/user.dart' as modelUser;

class TransactionNotifier extends BaseNotifier {

  List<model.Transaction> _transactions = [];
  
  bool _isLoading = false;
  StreamSubscription? _transactionSubscription;
  User? _currentUser;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1); // Normalized to start of month

  List<model.Transaction> get transactions => _transactions;

  bool get isLoading => _isLoading;
  DateTime get selectedMonth => _selectedMonth;

  TransactionNotifier() {
    _currentUser = auth.currentUser;
    if (_currentUser != null) {
      fetchTransactions(); // Initial fetch for the default selectedMonth (current month)
    }
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

  void selectMonth(DateTime month) {
    _selectedMonth = DateTime(month.year, month.month, 1); // Normalize to start of month
    notifyListeners(); // Notify listeners about month change for UI update
    fetchTransactions(); // Re-fetch transactions for the new month
  }

  void fetchTransactions() {
    if (_currentUser == null) {
      _transactions = [];
      _isLoading = false;
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    notifyListeners();

    // Calculate start of the selected month and start of the next month
    DateTime startOfMonth = _selectedMonth; // Already normalized
    DateTime startOfNextMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);

    _transactionSubscription?.cancel(); // Cancel previous subscription before creating a new one
     fetchAll('transaction', model.Transaction.fromMap).then((result) async {
      _transactions = result;
      for(var transaction in _transactions) {
        transaction.category = await readRef(transaction.categoryRef, Category.fromMap);
      }
      notifyListeners();
      _isLoading = false;
    });
  }

  Future<void> addTransaction(model.Transaction transaction) async {
    if (_currentUser == null) {
      print("Cannot add transaction: No user logged in.");
      throw Exception("User not logged in");
    }
    
    Map<String, dynamic> transactionData = transaction.toJson();
    transactionData['clientId'] = _currentUser!.uid;
    transactionData.putIfAbsent('timestamp', () => FieldValue.serverTimestamp()); 

    // _isLoading = true; // This might cause UI flicker if stream updates quickly.
    // notifyListeners(); // Usually not needed here if stream updates UI.
    try {
      await firestore.collection('transaction').add(transactionData);
      // If the new transaction is within the currently selected month, 
      // the stream will pick it up. If it's for a different month,
      // it will appear when that month is selected.
    } catch (e) {
      print("Error adding transaction: \$e");
      throw e; 
    } finally {
      // _isLoading = false;
      // notifyListeners();
    }
  }
  
  Future<void> updateTransaction(model.Transaction transaction) async {
    if (_currentUser == null) throw Exception("User not logged in");
    Map<String, dynamic> transactionData = transaction.toJson();
    transactionData['clientId'] = _currentUser!.uid; 
    await firestore.collection('transaction').doc(transaction.id).update(transactionData);
    // Stream will update the list if the transaction remains in the selected month.
    // If date changed, it might move out of view until that month is selected.
  }

  Future<void> deleteTransaction(String transactionId) async {
    if (_currentUser == null) throw Exception("User not logged in");
    await firestore.collection('transaction').doc(transactionId).delete();
    // Stream will update the list.
  }

  @override
  void dispose() {
    _transactionSubscription?.cancel();
    super.dispose();
  }

  double get incomesTotal {
    return 0;
  }

   double get expensesTotal {
    return 0;
  }

   double get difference{
    return 0;
  }

  TransactionsViewModel() {
    _initializeData();
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _fetchProject(),
      _fetchUsers(),
    ]);
  }

  Future<void> _fetchProject() async {
    fetchAll('project', Project.fromMap).then((result) async {
      for (var r in result) {
        // currentProject = r;
      }
    });
  }

  Future<void> _fetchUsers() async {
    fetchAll('user', modelUser.User.fromMap).then((result) async {
      // allUsers = result;
    });
  }

  bool checkTransactionForMonth(model.Transaction transaction, DateTime selectedMonth) {
    final bool firstCheck = 
        (transaction.parent == null && transaction.isFixed &&
            (transaction.availableFrom.isSameOrBeforeMonthYear(selectedMonth) &&
            (transaction.availableUntil == null || selectedMonth.isSameOrBeforeMonthYear(transaction.availableUntil!)))) ||
        (!transaction.isFixed && selectedMonth.isSameMonthYear(transaction.availableFrom));

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

  // void selectMonth(DateTime picked) {
  //   selectedMonth = picked;
  // }

  void addDataTransactionStatus({required TransactionStatus status, required Transaction transaction, required Null Function() callback}) {}

  void deleteDataTransactionStatus({required TransactionStatus status, required Transaction transaction, required Null Function() callback}) {}
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

