import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_flutter_web_app/models/actionResult.dart';
import 'package:provider/provider.dart';
import '../../models/economize.dart' as model_economize;
import '../../providers/debt_notifier.dart'; // Manages Economize goals
import './add_edit_economize_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For DocumentReference
// Import Transaction model and Notifier if you want to fetch and display transaction details later
// import '../../models/transaction.dart' as model_transaction;
// import '../../providers/transaction_notifier.dart';

class EconomizeDetailScreen extends StatelessWidget {
  final model_economize.Economize economizeGoal;
  final  Function(Actionresult<model_economize.Economize>) callback;

  const EconomizeDetailScreen({Key? key, required this.economizeGoal, required this.callback}) : super(key: key);

  Widget _buildDetailRow(BuildContext context, String label, String? value) {
    final textTheme = Theme.of(context).textTheme;
    if (value == null || value.isEmpty) return SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text(value, style: textTheme.bodyLarge)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'de_DE');
    final dateFormat = DateFormat.yMMMMd();
    final debtNotifier = Provider.of<DebtNotifier>(context, listen: false);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // Placeholder for calculating saved amount - requires fetching linked transactions
    double currentSavedAmount = economizeGoal.savedAmount; 
    
    double progress = 0.0;
    if(economizeGoal.goalAmount != null) {
    if (economizeGoal.goalAmount! > 0) {
      progress = (currentSavedAmount / economizeGoal.goalAmount!).clamp(0.0, 1.0);
    }
    }
    bool isReached = progress >= 1.0;

    return Scaffold(
      appBar: AppBar( // Themed
        title: Text(economizeGoal.title),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            tooltip: 'Edit Goal',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditEconomizeScreen(economizeGoal: economizeGoal, callback: (eco) {
                    
                  },),
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
                    content: Text('Are you sure you want to delete this savings goal "${economizeGoal.title}"?', style: textTheme.bodyLarge),
                    actions: <Widget>[
                      TextButton(child: Text('Cancel'), onPressed: () => Navigator.of(ctx).pop()),
                      TextButton(
                        child: Text('Delete', style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(ctx); // For dialog pop
                          final rootNavigator = Navigator.of(context); // For screen pop

                          debtNotifier.deleteEconomize(economizeGoal.id!).then((_){
                            scaffoldMessenger.showSnackBar(
                              SnackBar(content: Text('Savings Goal "${economizeGoal.title}" deleted.'), backgroundColor: Colors.green)
                            );
                            navigator.pop(); // Close dialog
                            rootNavigator.pop(); // Pop detail screen
                          }).catchError((error){
                            scaffoldMessenger.showSnackBar(
                              SnackBar(content: Text('Error deleting goal: $error'), backgroundColor: Colors.redAccent)
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
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card( // Themed
          elevation: Theme.of(context).cardTheme.elevation ?? 4.0,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(child: Text(economizeGoal.title, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary))),
                if (economizeGoal.comment != null && economizeGoal.comment!.isNotEmpty)
                  Padding(padding: const EdgeInsets.only(top: 8.0, bottom: 12.0), child: Text(economizeGoal.comment!, style: textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic))),
                Divider(),
                if(economizeGoal.goalAmount != null)
                  _buildDetailRow(context, 'Goal Amount', currencyFormat.format(economizeGoal.goalAmount)),
                if (economizeGoal.targetDate != null) 
                  _buildDetailRow(context, 'Target Date', dateFormat.format(economizeGoal.targetDate!)),
                SizedBox(height: 16),
                if(economizeGoal.goalAmount != null)
                  Text('Progress: ${currencyFormat.format(currentSavedAmount)} / ${currencyFormat.format(economizeGoal.goalAmount)} (${(progress * 100).toStringAsFixed(1)}%)', style: textTheme.titleMedium),
                SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0), // Rounded corners
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12, // Thicker progress bar
                    backgroundColor: colorScheme.onSurface.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(isReached ? Colors.green[700]! : colorScheme.primary),
                  ),
                ),
                SizedBox(height: 24),
                Text('Linked Transactions (${economizeGoal.transactionRefs?.length ?? 0}):', style: textTheme.titleLarge),
                SizedBox(height: 8),
                _buildLinkedTransactionsList(context, economizeGoal, debtNotifier),
                SizedBox(height: 16),
                // TODO: Add button/UI to link existing transactions or create new ones for this goal
                // Example: ElevatedButton(onPressed: () { /* Open transaction selection dialog */ }, child: Text("Link Transaction")),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLinkedTransactionsList(BuildContext context, model_economize.Economize goal, DebtNotifier debtNotifier) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    if (goal.transactionRefs == null || goal.transactionRefs!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Center(child: Text('No transactions linked to this goal yet.', style: textTheme.bodyMedium)),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(), 
      itemCount: goal.transactionRefs!.length,
      itemBuilder: (context, index) {
        final ref = goal.transactionRefs![index];
        final transaction = goal.transactions[index];

        return Card(
          elevation: 1.0,
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            leading: Icon(Icons.link, color: colorScheme.secondary),
            title: Text('${transaction.title}', style: textTheme.bodyMedium),
            trailing: IconButton(
              icon: Icon(Icons.remove_circle_outline, color: colorScheme.error.withOpacity(0.7)),
              tooltip: 'Unlink Transaction',
              onPressed: () {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                debtNotifier.unlinkTransactionFromEconomize(goal.id!, ref).then((_){
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Transaction unlinked.'), backgroundColor: Colors.green)
                  );
                }).catchError((error){
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Error unlinking transaction: $error'), backgroundColor: Colors.redAccent)
                  );
                });
              },
            ),
          ),
        );
      },
    );
  }
}
