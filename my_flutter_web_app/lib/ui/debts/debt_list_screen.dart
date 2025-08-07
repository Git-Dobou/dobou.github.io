import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_notifier.dart';
import '../../providers/debt_notifier.dart';
import '../../models/debt.dart' as model_debt;
import './add_edit_debt_screen.dart';
import './debt_detail_screen.dart';

class DebtListScreen extends StatefulWidget {
  const DebtListScreen({Key? key}) : super(key: key);

  @override
  _DebtListScreenState createState() =>
      _DebtListScreenState();

}

class _DebtListScreenState extends State<DebtListScreen> {

  @override
  Widget build(BuildContext context) {
    final authNotifier = Provider.of<AuthNotifier>(context);
    final debtNotifier = Provider.of<DebtNotifier>(context);
    final textTheme = Theme.of(context).textTheme;
    // final colorScheme = Theme.of(context).colorScheme;

    if (authNotifier.user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Debts')), // Themed
        body: Center(child: Text('Please log in to view debts.', style: textTheme.titleMedium)),
      );
    }

    
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'de_DE'); 
    // final debtNotifier = Provider.of<DebtNotifier>(context); // Not needed here for just triggering fetch
    String searchText = '';

    return Scaffold(
      appBar: AppBar( // Themed
        title: Text('Debts Management'),
      ),
      body: Consumer<DebtNotifier>(
        builder: (context, notifier, child) {
          if (notifier.isDebtsLoading) {
            return Center(child: CircularProgressIndicator());
          }
          List<model_debt.Debt> filteredDebts () {
      List<model_debt.Debt> baseList = notifier.debts
      .where((b) => !b.isPayed)
      .toList(); 

      return baseList;
    }

    List<model_debt.Debt> baseList = notifier.debts.where((b) => !b.isPayed)
      .toList();

          if (baseList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payment_outlined, size: 80, color: Colors.grey[400]), // Changed icon
                  SizedBox(height: 16),
                  Text('No debts found.', style: textTheme.titleMedium),
                  SizedBox(height: 8),
                  Text('Tap the "+" button to add a new debt.', style: textTheme.bodyMedium, textAlign: TextAlign.center),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: baseList.length,
            itemBuilder: (context, index) {
              final debt = baseList[index];
              double paidAmount = debt.payedAmount;
              double remainingAmount = debt.amount - paidAmount;
              bool isOverdue = debt.dueDate != null && debt.dueDate!.isBefore(DateTime.now()) && !debt.isPayed;
              
              String debtStatusText;
              Color statusColor;

              if (debt.isPayed) {
                debtStatusText = "Paid";
                statusColor = Colors.green[700]!;
              } else if (remainingAmount <= 0) {
                debtStatusText = "Paid (Pending Verification)"; // Or "Cleared"
                statusColor = Colors.green[700]!;
              } else if (isOverdue) {
                debtStatusText = "Overdue";
                statusColor = Colors.orange[700]!;
              } else {
                debtStatusText = "Pending";
                statusColor = Colors.blue[700]!;
              }

              double currentSavedAmount = debt.payedAmount;
              double progress = (currentSavedAmount / debt.amount).clamp(0.0, 1.0);

              return Card( // Themed
                child: ListTile( // Themed
                  leading: Icon(Icons.receipt_long_outlined, size: 30), // Example icon
                  title: Text(
                    debt.creditor,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [ 
                      Text("Total: ${currencyFormat.format(debt.amount)}", style: textTheme.bodyLarge),
                      ClipRRect(
                          borderRadius: BorderRadius.circular(4.0),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text("Status: $debtStatusText", style: textTheme.bodySmall?.copyWith(color: statusColor, fontStyle: FontStyle.italic))
                    ],
                  ),
                  isThreeLine: true, 
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DebtDetailScreen(debt: debt, callback: (result) {
                          setState(() {
                            debtNotifier.debts.removeWhere((b) => b.id == debt.id);
                          });
                        },),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton( // Themed
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddEditDebtScreen(callback: (result) {
              setState(() {
                debtNotifier.debts.add(result.data!);
              });
            },)),
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Add Debt',
      ),
    );
  }
}
