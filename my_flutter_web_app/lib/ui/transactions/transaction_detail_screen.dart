import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/transaction.dart' as model;
import '../../providers/category_notifier.dart';
import '../../models/category.dart' as model_cat;
import 'package:cloud_firestore/cloud_firestore.dart'; // For DocumentReference

class TransactionDetailScreen extends StatelessWidget {
  final model.Transaction transaction;

  const TransactionDetailScreen({Key? key, required this.transaction}) : super(key: key);

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
    model_cat.Category? category;
    if (transaction.categoryRef != null && categoryNotifier.categories.isNotEmpty) {
      try {
        category = categoryNotifier.categories.firstWhere((cat) => cat.id == transaction.categoryRef!.id);
      } catch (e) {
        category = null;
        print("Category not found for ID: \${transaction.categoryRef!.id}");
      }
    }

    String transactionType = transaction.amount >= 0 ? "Income" : "Expense";
    
    return Scaffold(
      appBar: AppBar( // AppBarTheme from main.dart will apply
        title: Text(transaction.title), // Will use AppBarTheme titleTextStyle
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
                _buildDetailRow(context, 'Amount', currencyFormat.format(transaction.amount), 
                                isAmount: true, isIncome: transaction.amount >= 0),
                _buildDetailRow(context, 'Type', transactionType, 
                                isAmount: true, isIncome: transaction.amount >=0), // Color code type as well
                _buildDetailRow(context, 'Date', dateFormat.format(transaction.availableFrom)),
                _buildDetailRow(context, 'Category', category?.name ?? transaction.categoryRef?.id ?? "N/A"),
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
                  _buildDetailRow(context, 'Payment Type', "Fixed Transaction (\${cycle})"),
                SizedBox(height: 10),
                Divider(),
                SizedBox(height: 10),
                if (transaction.transactionStatusRef != null && transaction.transactionStatusRef!.isNotEmpty)
                  _buildRefList(context, 'Status IDs', transaction.transactionStatusRef),
                if (transaction.transactionNewAmountsRef != null && transaction.transactionNewAmountsRef!.isNotEmpty)
                  _buildRefList(context, 'New Amounts IDs', transaction.transactionNewAmountsRef),
                if (transaction.subTransactionsRef != null && transaction.subTransactionsRef!.isNotEmpty)
                  _buildRefList(context, 'Sub-Transactions IDs', transaction.subTransactionsRef),
                if (transaction.parentRef != null)
                  _buildDetailRow(context, 'Parent Transaction ID', transaction.parentRef!.id),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
