import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_flutter_web_app/models/category.dart';
import 'package:my_flutter_web_app/models/transaction_status.dart';
import 'package:my_flutter_web_app/providers/BaseNotifier.dart';
import '../models/debt.dart' as model_debt;
import '../models/transaction.dart' as model_transaction;
import '../models/economize.dart' as model_economize;
import '../models/payment.dart' as model_payment; // Import Payment model

class DebtNotifier extends BaseNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? _currentUser;

  // --- Debt State ---
  List<model_debt.Debt> _debts = [];
  bool _isDebtsLoading = false;
  StreamSubscription? _debtSubscription;
  List<model_debt.Debt> get debts => _debts;
  bool get isDebtsLoading => _isDebtsLoading;

  // --- Economize State ---
  List<model_economize.Economize> _economizes = [];
  bool _isEconomizeLoading = false;
  StreamSubscription? _economizeSubscription;
  List<model_economize.Economize> get economizes => _economizes;
  bool get isEconomizeLoading => _isEconomizeLoading;

  DebtNotifier() {
    _currentUser = _auth.currentUser;
    if (_currentUser != null) {
      // fetchDebts();
      // fetchEconomizes();
    }
    _auth.authStateChanges().listen((user) {
      _currentUser = user;
      if (_currentUser != null) {
        fetchDebts();
        fetchEconomizes();
      } else {
        _debts = [];
        _debtSubscription?.cancel();
        _isDebtsLoading = false;

        _economizes = [];
        _economizeSubscription?.cancel();
        _isEconomizeLoading = false;
        
        // _currentDebtPayments = [];
        // _currentDebtPaymentsSubscription?.cancel();
        notifyListeners();
      }
    });
  }

  Future<model_debt.Debt> buildDebt(model_debt.Debt debt) async {
    List<model_payment.Payment> listPayments = [];
          final snapshot = await firestore
                          .collection('payment') // passe an deine Collection an
                          .where(FieldPath.documentId, whereIn: debt.paymentRefs)
                          .get();

    for(var doc in snapshot.docs) {
      if(!doc.exists) {
        continue;
      }

      var payment = model_payment.Payment.fromMap(doc.data(), doc.id);      
      listPayments.add(payment);
    }

    debt.payments = listPayments;
    return debt;
  }

  // --- Debt Methods ---
  void fetchDebts({bool withPayment = true}) async {
    if (_currentUser == null) {
      _economizes = []; 
      _isEconomizeLoading = false; 
      notifyListeners(); 
      return;
    }

    _isDebtsLoading = true;

    await fetchAll('debt', model_debt.Debt.fromMap).then((result) async {
      _debts = result;
      for(var debt in _debts) {
        debt = await buildDebt(debt);
      }

      _isDebtsLoading = false;
      notifyListeners();
    });
  }

  Future<DocumentReference> addDebt(model_debt.Debt debt) async {
    if (_currentUser == null) throw Exception("User not logged in");
    Map<String, dynamic> data = debt.toMap();
    data = completeAdd(data);
    data.putIfAbsent('paymentRefs', () => []);

    return await firestore.collection('debt').add(data);
  }

  Future<void> updateDebt(model_debt.Debt debt) async {
    if (_currentUser == null) throw Exception("User not logged in");
    Map<String, dynamic> data = debt.toMap();
    data = completeUpdate(data);
    await firestore.collection('debt').doc(debt.id).update(data);
  }

  Future<void> deleteDebt(String debtId) async {
    if (_currentUser == null) throw Exception("User not logged in");
    // Optional: Delete associated payments first if they are in a subcollection or need cleanup
    // For now, just deleting the debt document.
    await firestore.collection('debt').doc(debtId).delete();
  }

  // --- Payment Methods for a specific Debt ---
  Future<void> addPaymentToDebt(model_debt.Debt debt, model_payment.Payment payment) async {
    if (_currentUser == null) throw Exception("User not logged in");
    
    // 1. Create the payment document in a 'payments' subcollection of the debt OR a root 'payments' collection
    // For this example, using a root 'payments' collection and linking via debtRef in Payment model
    // and paymentRefs in Debt model.
    DocumentReference paymentRef = firestore.collection('payment').doc(); // Generate ID for payment
    Map<String, dynamic> paymentData = payment.toMap();
    paymentData = completeAdd(paymentData);

    // 2. Perform operations in a batch for atomicity
    WriteBatch batch = firestore.batch();
    batch.set(paymentRef, paymentData); // Add the payment

    // 3. Update the debt document with the new payment reference and paidAmount
    DocumentReference debtDocRef = firestore.collection('debt').doc(debt.id);
    batch.update(debtDocRef, {
      'paymentRefs': FieldValue.arrayUnion([paymentRef]),
    });
    
    await batch.commit();
    debt.paymentRefs.add(paymentRef);
    debt.payments.add(payment);
    notifyListeners();
    // The main debt list will update via its stream if paidAmount/paymentRefs change.
    // If you have a separate stream for payments of a specific debt, that would update too.
  }

  Future<void> deletePaymentFromDebt(model_debt.Debt debtId, model_payment.Payment paymentId, Null Function() callback) async {
    if (_currentUser == null) throw Exception("User not logged in");

    DocumentReference paymentDocRef = firestore.collection('payment').doc(paymentId.id!);
    DocumentReference debtDocRef = firestore.collection('debt').doc(debtId.id!);

    WriteBatch batch = firestore.batch();
    batch.delete(paymentDocRef); // Delete the payment
    batch.update(debtDocRef, { // Update the debt
      'paymentRefs': FieldValue.arrayRemove([paymentDocRef]),
      // 'paidAmount': FieldValue.increment(-paymentAmount),
      // Optionally, update isPaid status here
    });

    await batch.commit();
    callback.call();
  }

  // --- Economize Methods (from previous subtask, ensure they are complete) ---
  void fetchEconomizes() {
    if (_currentUser == null) {
      _economizes = []; _isEconomizeLoading = false; notifyListeners(); return;
    }

    fetchAll('economize', model_economize.Economize.fromMap).then((result) async {
      _economizes = result; 
      for(var economize in _economizes) {
        for(var transactionRef in economize.transactionRefs ?? []){
          var transaction = await readRef(transactionRef,  model_transaction.Transaction.fromMap);
          if(transaction == null) continue;
          
          if ((transaction.transactionStatusRef  ?? []).isNotEmpty) {
          final snapshot = await firestore
                              .collection('transactionStatus') // passe an deine Collection an
                              .where(FieldPath.documentId, whereIn: transaction.transactionStatusRef)
                              .get();

          transaction.transactionStatus = snapshot.docs
          .map((doc) => TransactionStatus.fromMap(doc.data(), doc.id))
          .toList();
        }

        economize.category = await readRef(economize.categoryRef, Category.fromMap);
        economize.transactions.add(transaction!);
        }
      }
      notifyListeners();
    });
  }

  Future<void> addEconomize(model_economize.Economize economizeGoal) async {
    if (_currentUser == null) {
      print("No user logged in");
      throw Exception("User not logged in");
    }

    Map<String, dynamic> data = economizeGoal.toMap();
    print("Before completeAdd: $data");

    data = completeAdd(data);
    print("After completeAdd: $data");

    final ref = await firestore.collection('economize').add(data);
    print("Saved with ID: ${ref.id}");
  }

  Future<void> updateEconomize(model_economize.Economize economizeGoal) async {
    if (_currentUser == null) throw Exception("User not logged in");
    Map<String, dynamic> data = economizeGoal.toMap();
    completeUpdate(data);

    await firestore.collection('economize').doc(economizeGoal.id).update(data);
  }

  Future<void> deleteEconomize(String economizeId) async {
    if (_currentUser == null) throw Exception("User not logged in");
    await firestore.collection('economize').doc(economizeId).delete();
  }

  Future<void> linkTransactionToEconomize(String economizeId, DocumentReference transactionRef) async {
    if (_currentUser == null) throw Exception("User not logged in");
    await firestore.collection('economize').doc(economizeId).update({
      'transactionRefs': FieldValue.arrayUnion([transactionRef])
    });
  }

  Future<void> unlinkTransactionFromEconomize(String economizeId, DocumentReference transactionRef) async {
    if (_currentUser == null) throw Exception("User not logged in");
    await firestore.collection('economize').doc(economizeId).update({
      'transactionRefs': FieldValue.arrayRemove([transactionRef])
    });
  }

  @override
  void dispose() {
    _debtSubscription?.cancel();
    _economizeSubscription?.cancel();
    // _currentDebtPaymentsSubscription?.cancel();
    super.dispose();
  }
}
