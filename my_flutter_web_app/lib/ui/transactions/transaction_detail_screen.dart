import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:my_flutter_web_app/models/actionResult.dart';
import 'package:my_flutter_web_app/models/transaction_status.dart';
import 'package:my_flutter_web_app/providers/debt_notifier.dart';
import 'package:my_flutter_web_app/providers/transaction_notifier.dart';
import 'package:my_flutter_web_app/ui/base/advancedLabelValueRow.dart';
import 'package:my_flutter_web_app/ui/debts/add_payment_dialog.dart';
import 'package:my_flutter_web_app/ui/debts/debt_detail_screen.dart';
import 'package:my_flutter_web_app/ui/economize/economize_detail_screen.dart';
import 'package:my_flutter_web_app/ui/transactions/add_edit_transaction_screen.dart';
import 'package:provider/provider.dart';
import '../../models/transaction.dart' as model;
import '../../providers/category_notifier.dart';
import '../../models/category.dart' as model_cat;
import 'package:cloud_firestore/cloud_firestore.dart'; // For DocumentReference

class TransactionDetailScreen extends StatefulWidget {
  final model.Transaction transaction;
  final  Function(Actionresult<model.Transaction>) callback;
    
  const TransactionDetailScreen({
    super.key,
    required this.transaction,
    required this.callback,
  });

  @override
  _TransactionDetailScreenState createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
   late model.Transaction transaction;

    @override
  void initState() {
    super.initState();
    transaction = widget.transaction;
  }


  Widget _buildDetailRow(BuildContext context, String label, String? value, {bool isAmount = false, bool isIncome = false}) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    if (value == null || value.isEmpty) return SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold))),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: isAmount 
                  ? textTheme.bodyLarge?.copyWith(color: isIncome ? Colors.green[700] : Colors.red[700], fontWeight: FontWeight.bold)
                  : textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefList(BuildContext context, String label, List<DocumentReference>? refs) {
    if (refs == null || refs.isEmpty) return SizedBox.shrink();
    String displayValue = refs.map((ref) => ref.id).join(', ');
    return _buildDetailRow(context, label, displayValue);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'de_DE'); 
    final dateFormat = DateFormat.yMMMMd(); 
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final categoryNotifier = Provider.of<CategoryNotifier>(context, listen: false);
    final viewModel = Provider.of<TransactionNotifier>(context, listen: false);
    final debtViewModel = Provider.of<DebtNotifier>(context, listen: false);

    bool showEditModalForMonth2 = false;
    bool showAddPayment = false;
    bool confirmPushToNextMonthModal = false;
    bool showModalDebt = false;

    model_cat.Category? category;
    if (transaction.categoryRef != null && categoryNotifier.categories.isNotEmpty) {
      try {
        category = categoryNotifier.categories.firstWhere((cat) => cat.id == transaction.categoryRef!.id);
      } catch (e) {
        category = null;
        print("Category not found for ID: ${transaction.categoryRef!.id}");
      }
    }

    var amount = transaction.getAmount(viewModel.selectedMonth);

    return Scaffold(
      appBar: AppBar( // AppBarTheme from main.dart will apply
        title: Text(transaction.title),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            tooltip: 'Edit Goal',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditTransactionScreen(transactionToEdit: transaction, callback: (tra) async {
                    // 1. Daten asynchron laden
                    var ref = await viewModel.getRef(transaction.id, 'transaction');
                    var updatedTransaction = await viewModel.BuildTransactionFromDoc(ref!);

                    // 2. Dann synchron in setState setzen
                    setState(() {
                      transaction = updatedTransaction;
                    });
                  },
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.delete, color: colorScheme.error),
            tooltip: 'Delete Goal',
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext ctx) {
                  return AlertDialog(
                    title: Text('Confirm Delete', style: textTheme.titleLarge),
                    content: Text('Are you sure you want to delete this transaction "${transaction.title}"?', style: textTheme.bodyLarge),
                    actions: <Widget>[
                      TextButton(child: Text('Cancel'), onPressed: () => Navigator.of(ctx).pop()),
                      TextButton(
                        child: Text('Delete', style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(ctx); // For dialog pop
                          final rootNavigator = Navigator.of(context); // For screen pop

                          viewModel.deleteTransaction(transaction).then((_){
                            scaffoldMessenger.showSnackBar(
                              SnackBar(content: Text('Transaction "${transaction.title}" deleted.'), backgroundColor: Colors.green)
                            );
                            widget.callback.call(Actionresult(actionresultEnum: ActionresultEnum.delete));
                            
                            navigator.pop(); // Close dialog
                            rootNavigator.pop(); // Pop detail screen
                          }).catchError((error){
                            scaffoldMessenger.showSnackBar(
                              SnackBar(content: Text('Error deleting transaction: $error'), backgroundColor: Colors.redAccent)
                            );
                            navigator.pop(); // Close dialog
                          });
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],// Will use AppBarTheme titleTextStyle
      ),
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card( // CardTheme from main.dart will apply
          elevation: 4.0, // Can override global theme if needed, or remove to use global
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Text(
                    transaction.title,
                    style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 20),
                
                AdvancedLabelValueRow(label: 'Amount', value: currencyFormat.format(amount), color: transaction.typeTypisiert == model.TransactionType.Income ? Colors.green[700] : Colors.red[700]),
                AdvancedLabelValueRow(label: 'Type', value: transaction.typeTypisiert.toString()), // Color code type as well
                AdvancedLabelValueRow(label: 'Available from', value: dateFormat.format(transaction.availableFrom)),
                if(transaction.availableUntil != null)
                  AdvancedLabelValueRow(label: 'Available until', value: dateFormat.format(transaction.availableUntil!)),
                AdvancedLabelValueRow(label: 'Category', value: category?.name ?? "N/A"),
                // if (transaction.comment != null && transaction.comment!.isNotEmpty)
                //   Padding(
                //     padding: const EdgeInsets.symmetric(vertical: 6.0),
                //     child: Column(
                //        crossAxisAlignment: CrossAxisAlignment.start,
                //        children: [
                //           Text("Note", style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                //           SizedBox(height: 4),
                //           Text(transaction.comment!, style: textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic)),
                //        ]
                //     )
                //   ),
                SizedBox(height: 10),
                if (transaction.isFixed)
                  _buildDetailRow(context, 'Payment Type', 'Fixed Transaction (${transaction.cyklus})'),
                SizedBox(height: 10),
                Divider(),
                SizedBox(height: 10),
                          Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    // Loop: transaction.transactionNewAmounts
    for (final newAmountObj in transaction.transactionNewAmounts)
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            // Header with date range and amount
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(newAmountObj.availableFrom.MYLongString, style: TextStyle(fontWeight: FontWeight.bold)),
                    if (newAmountObj.availableUntil != null &&
                        newAmountObj.availableUntil != newAmountObj.availableFrom)
                      Text('→ ${newAmountObj.availableUntil!.MYLongString}',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
                Spacer(),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${newAmountObj.amount.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            Row(
              children: [
                InfinityIconButton(
                  icon: Icons.edit,
                  onPressed: (!transaction.subTransactions.isNotEmpty &&
                              !transaction.isTransactionDeactivated(viewModel.selectedMonth) &&
                              !transaction.isTransactionPayed(viewModel.selectedMonth))
                      ? () => setState(() => 
                      showEditModalForMonth2 = true
                      )
                      : null,
                ),
                // InfinityIconButton(
                //   icon: Icons.delete,
                //   onPressed: (!transaction.subTransactions.isNotEmpty &&
                //               !transaction.isTransactionDeactivated(viewModel.selectedMonth) &&
                //               !transaction.isTransactionPayed(viewModel.selectedMonth))
                //       ? () => setState(() => viewModel.deleteNewAmount(newAmount: newAmountObj))
                //       : null,
                // ),
              ],
            ),
          ],
        ),
      ),

    const SizedBox(height: 10),

    // Button: Add/Delete Payment or Status
    if (!transaction.isTransactionDeactivated(viewModel.selectedMonth)) ...[
      if (transaction.debt != null)
        Padding(padding: const EdgeInsets.only(top: 8),
        child:
        InfinityButton(
          icon: transaction.isTransactionPayed(viewModel.selectedMonth)
              ? Icons.check_circle
              : Icons.check_circle_outline,
          label: transaction.isTransactionPayed(viewModel.selectedMonth)
              ? 'go_to_debt_not_payed_'
              : 'go_to_debt_payed_',
          onPressed: () {
            final debt = transaction.debt!;
            if (transaction.isTransactionPayed(viewModel.selectedMonth)) {
              final payment = debt.payments.firstWhere(
                (p) => p.date.MYString == viewModel.selectedMonth.MYString);
                debtViewModel.deletePaymentFromDebt(debt, payment, () {
                final status = transaction.transactionStatus.firstWhere(
                  (s) => s.date.MYString == viewModel.selectedMonth.MYString);
                  viewModel.deleteDataTransactionStatus(status: status, transaction: transaction, callback: () {
                  }
                );
                });
            } else {
              setState(() => showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => AddPaymentDialog(debt: debt, callback: (newPayment) {
                  var status = TransactionStatus(status: TransactionStatusType.Payed.name, date: viewModel.selectedMonth);
                  viewModel.addDataTransactionStatus(status: status, transaction: transaction, callback: () {
                      setState(() {
                        transaction.transactionStatus.add(status);
                      });
                  });
                })
              ));
            }
          },
        ))
      else
      Padding(padding: const EdgeInsets.only(top: 8),
        child:
        InfinityButton(
          icon: transaction.isTransactionPayed(viewModel.selectedMonth)
              ? Icons.check_circle
              : Icons.check_circle_outline,
          label: transaction.isTransactionPayed(viewModel.selectedMonth)
              ? 'not_payed_'
              : 'payed_',
          onPressed: () {
            final existing = transaction.transactionStatus.firstWhereOrNull((s) =>
              s.date.MYString == viewModel.selectedMonth.MYString &&
              s.statusTypisiert == TransactionStatusType.Payed);

            if (existing != null) {
              viewModel.deleteDataTransactionStatus(status: existing, transaction: transaction, callback: () {

              });
            } else {
              final status = TransactionStatus(status: TransactionStatusType.Payed.name, date: viewModel.selectedMonth);

              viewModel.addDataTransactionStatus(status: status, transaction: transaction, callback: () {
                  setState(() {
                    transaction.transactionStatus.add(status);
                  });
              });
            }
          },
        )
          ),

      // Button: Push to next month
      if (!transaction.isTransactionPayed(viewModel.selectedMonth))
      Padding(padding: const EdgeInsets.only(top: 8),
        child:
        InfinityButton(
          icon: Icons.arrow_circle_right,
          label: 'push_to_next_month',
          onPressed: () => setState(() => confirmPushToNextMonthModal = true),
        )
          ),
    ],

          Padding(
        padding: const EdgeInsets.only(top: 8),
    child: 
    InfinityButton(
      icon: transaction.isTransactionDeactivated(viewModel.selectedMonth)
          ? Icons.play_circle
          : Icons.stop_circle,
      label: transaction.isTransactionDeactivated(viewModel.selectedMonth)
          ? 'activated_'
          : 'deactivated_',
      onPressed: () {
        if (transaction.isTransactionDeactivated(viewModel.selectedMonth)) {
          final status = transaction.transactionStatus.firstWhere((s) =>
              s.statusTypisiert == TransactionStatusType.Deactivated &&
              s.date.MYString == viewModel.selectedMonth.MYString);
          viewModel.deleteDataTransactionStatus(status: status, transaction: transaction, callback: () {});
        } else {
          final status = TransactionStatus(status: TransactionStatusType.Deactivated.toString(), date: viewModel.selectedMonth);
          viewModel.addDataTransactionStatus(status: status, transaction: transaction, callback: () {
            final debt = transaction.debt;
            final payment = debt?.payments.firstWhereOrNull((p) =>
                p.date.MYString == viewModel.selectedMonth.MYString);
            if (payment != null) {
              debtViewModel.deletePaymentFromDebt(debt!, payment, () {

              });
            }
          });
        }
      },
    ),
          ),
    // Button: Go to Debt / Economize
    if (transaction.debt != null ||
        transaction.economize != null)
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: ElevatedButton(
          onPressed: () => setState(() {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => transaction.debt != null ? DebtDetailScreen(debt: transaction.debt!, callback: (_) {})
                                        : EconomizeDetailScreen(economizeGoal: transaction.economize!, callback: (_){}),
              ),
            );
          }),
          style: ElevatedButton.styleFrom(
            // backgroundColor: textTheme.,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.all(14),
          ),
          child: Text(
            transaction.debt != null
                ? 'goto_debt'
                : 'goto_economize',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
  ],
),

                // if (transaction.transactionStatusRef != null && transaction.transactionStatusRef!.isNotEmpty)
                //   _buildRefList(context, 'Status IDs', transaction.transactionStatusRef),
                // if (transaction.transactionNewAmountsRef != null && transaction.transactionNewAmountsRef!.isNotEmpty)
                //   _buildRefList(context, 'New Amounts IDs', transaction.transactionNewAmountsRef),
                // if (transaction.subTransactionsRef != null && transaction.subTransactionsRef!.isNotEmpty)
                //   _buildRefList(context, 'Sub-Transactions IDs', transaction.subTransactionsRef),
                // if (transaction.parentRef != null)
                //   _buildDetailRow(context, 'Parent Transaction ID', transaction.parentRef!.id),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



class InfinityButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const InfinityButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class InfinityIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const InfinityIconButton({required this.icon, required this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
    );
  }
}
