import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_flutter_web_app/providers/BaseNotifier.dart';
import '../models/debt.dart' as model_debt;
import '../models/economize.dart' as model_economize;
import '../models/payment.dart' as model_payment; // Import Payment model

class DebtNotifier extends BaseNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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

  // --- Payments for a selected Debt (example for future use if needed in detail screen)
  // List<model_payment.Payment> _currentDebtPayments = [];
  // List<model_payment.Payment> get currentDebtPayments => _currentDebtPayments;
  // StreamSubscription? _currentDebtPaymentsSubscription;

  DebtNotifier() {
    _currentUser = _auth.currentUser;
    if (_currentUser != null) {
      fetchDebts();
      // fetchEconomizes();
    }
    _auth.authStateChanges().listen((user) {
      _currentUser = user;
      if (_currentUser != null) {
        fetchDebts();
        // fetchEconomizes();
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

  // --- Debt Methods ---
  void fetchDebts() {
     if (_currentUser == null) {
      _economizes = []; 
      _isEconomizeLoading = false; 
      notifyListeners(); 
      return;
    }

    _isDebtsLoading = true;

    fetchAll('debt', model_debt.Debt.fromMap).then((result) async {
      _debts = result;
      for(var debt in _debts) {
        List<model_payment.Payment> listPayments = [];
        for(var paymentRef in debt.paymentRefs) {
          var payment = await readRef(paymentRef, model_payment.Payment.fromMap);
          if(payment == null){
            continue;
          }
          listPayments.add(payment!);
        }

        debt.payments = listPayments;
      }

      _isDebtsLoading = false;
      notifyListeners();
    });
  }

  Future<void> addDebt(model_debt.Debt debt) async {
    if (_currentUser == null) throw Exception("User not logged in");
    Map<String, dynamic> data = debt.toMap();
    data['clientId'] = _currentUser!.uid;
    data.putIfAbsent('timestamp', () => FieldValue.serverTimestamp());
    data.putIfAbsent('paymentRefs', () => []); // Ensure paymentRefs is initialized
    data.putIfAbsent('paidAmount', () => 0.0); // Ensure paidAmount is initialized
    data.putIfAbsent('isPaid', () => false); // Ensure isPaid is initialized
    await _firestore.collection('debts').add(data);
  }

  Future<void> updateDebt(model_debt.Debt debt) async {
    if (_currentUser == null) throw Exception("User not logged in");
    Map<String, dynamic> data = debt.toMap();
    data['clientId'] = _currentUser!.uid; // Ensure clientId remains correct
    await _firestore.collection('debts').doc(debt.id).update(data);
  }

  Future<void> deleteDebt(String debtId) async {
    if (_currentUser == null) throw Exception("User not logged in");
    // Optional: Delete associated payments first if they are in a subcollection or need cleanup
    // For now, just deleting the debt document.
    await _firestore.collection('debts').doc(debtId).delete();
  }

  // --- Payment Methods for a specific Debt ---
  Future<void> addPaymentToDebt(model_debt.Debt debt, model_payment.Payment payment) async {
    if (_currentUser == null) throw Exception("User not logged in");
    
    // 1. Create the payment document in a 'payments' subcollection of the debt OR a root 'payments' collection
    // For this example, using a root 'payments' collection and linking via debtRef in Payment model
    // and paymentRefs in Debt model.
    DocumentReference paymentRef = _firestore.collection('payment').doc(); // Generate ID for payment
    Map<String, dynamic> paymentData = payment.toMap();
    paymentData['clientId'] = '1735421-1353-53'; // Assuming payments also have clientId
    // paymentData['debtRef'] is already set in payment.toJson() from Payment model construction
    paymentData['creationTime'] = DateTime.now();
    paymentData['lastUpdateTime'] = DateTime.now();

    // 2. Perform operations in a batch for atomicity
    WriteBatch batch = _firestore.batch();
    batch.set(paymentRef, paymentData); // Add the payment

    // 3. Update the debt document with the new payment reference and paidAmount
    DocumentReference debtDocRef = _firestore.collection('debt').doc(debt.id);
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

  Future<void> deletePaymentFromDebt(String debtId, String paymentId, double paymentAmount) async {
    if (_currentUser == null) throw Exception("User not logged in");

    DocumentReference paymentDocRef = _firestore.collection('payments').doc(paymentId);
    DocumentReference debtDocRef = _firestore.collection('debts').doc(debtId);

    WriteBatch batch = _firestore.batch();
    batch.delete(paymentDocRef); // Delete the payment
    batch.update(debtDocRef, { // Update the debt
      'paymentRefs': FieldValue.arrayRemove([paymentDocRef]),
      'paidAmount': FieldValue.increment(-paymentAmount),
      // Optionally, update isPaid status here
    });

    await batch.commit();
  }

  // --- Economize Methods (from previous subtask, ensure they are complete) ---
  void fetchEconomizes() {
    if (_currentUser == null) {
      _economizes = []; _isEconomizeLoading = false; notifyListeners(); return;
    }

    fetchAll('economize', model_economize.Economize.fromJson).then((result) async {
      _economizes = result; 
      notifyListeners();
    });
  }

  Future<void> addEconomize(model_economize.Economize economizeGoal) async {
    if (_currentUser == null) throw Exception("User not logged in");
    Map<String, dynamic> data = economizeGoal.toJson();
    data['clientId'] = _currentUser!.uid;
    data.putIfAbsent('timestamp', () => FieldValue.serverTimestamp());
    data.putIfAbsent('transactionRefs', () => []); 
    await _firestore.collection('economize').add(data);
  }

  Future<void> updateEconomize(model_economize.Economize economizeGoal) async {
    if (_currentUser == null) throw Exception("User not logged in");
    Map<String, dynamic> data = economizeGoal.toJson();
    data['clientId'] = _currentUser!.uid; 
    await _firestore.collection('economize').doc(economizeGoal.id).update(data);
  }

  Future<void> deleteEconomize(String economizeId) async {
    if (_currentUser == null) throw Exception("User not logged in");
    await _firestore.collection('economize').doc(economizeId).delete();
  }

  Future<void> linkTransactionToEconomize(String economizeId, DocumentReference transactionRef) async {
    if (_currentUser == null) throw Exception("User not logged in");
    await _firestore.collection('economize').doc(economizeId).update({
      'transactionRefs': FieldValue.arrayUnion([transactionRef])
    });
  }

  Future<void> unlinkTransactionFromEconomize(String economizeId, DocumentReference transactionRef) async {
    if (_currentUser == null) throw Exception("User not logged in");
    await _firestore.collection('economize').doc(economizeId).update({
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
