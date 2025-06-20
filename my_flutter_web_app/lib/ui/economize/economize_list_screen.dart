import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_notifier.dart';
import '../../providers/debt_notifier.dart'; // Manages both Debts and Economizes
import '../../models/economize.dart' as model_economize;
import './add_edit_economize_screen.dart';
import './economize_detail_screen.dart';

class EconomizeListScreen extends StatelessWidget {
  const EconomizeListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authNotifier = Provider.of<AuthNotifier>(context);
    final textTheme = Theme.of(context).textTheme;
    // final colorScheme = Theme.of(context).colorScheme;

    if (authNotifier.user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Savings Goals')), // Themed
        body: Center(child: Text('Please log in to view savings goals.', style: textTheme.titleMedium)),
      );
    }

    final currencyFormat = NumberFormat.simpleCurrency(locale: 'de_DE'); 

    return Scaffold(
      appBar: AppBar( // Themed
        title: Text('Savings Goals'),
      ),
      body: Consumer<DebtNotifier>(
        builder: (context, debtNotifier, child) {
          if (debtNotifier.isEconomizeLoading && debtNotifier.economizes.isEmpty) {
            return Center(child: CircularProgressIndicator());
          }

          if (debtNotifier.economizes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.savings_outlined, size: 80, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text('No savings goals found.', style: textTheme.titleMedium),
                  SizedBox(height: 8),
                  Text('Tap the "+" button to add a new savings goal.', style: textTheme.bodyMedium, textAlign: TextAlign.center),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: debtNotifier.economizes.length,
            itemBuilder: (context, index) {
              final economizeGoal = debtNotifier.economizes[index];
              double currentSavedAmount = economizeGoal.savedAmount ?? 0.0;
              double progress = 0.0;
              if (economizeGoal.amount > 0) {
                progress = (currentSavedAmount / economizeGoal.amount).clamp(0.0, 1.0);
              }
              bool isReached = economizeGoal.isReached ?? (progress >= 1.0);

              return Card( // Themed
                child: ListTile( // Themed
                  leading: Icon(Icons.savings, size: 30, color: isReached ? Colors.green[700] : Theme.of(context).colorScheme.secondary),
                  title: Text(economizeGoal.name, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Goal: \${currencyFormat.format(economizeGoal.amount)}', style: textTheme.bodySmall),
                      if (economizeGoal.date != null)
                        Text('Target Date: \${DateFormat.yMd().format(economizeGoal.date)}', style: textTheme.bodySmall),
                      SizedBox(height: 4),
                      if (economizeGoal.amount > 0) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4.0),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(isReached ? Colors.green[700]! : Theme.of(context).colorScheme.primary),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text('\${(progress * 100).toStringAsFixed(0)}% - Saved: \${currencyFormat.format(currentSavedAmount)}', style: textTheme.bodySmall),
                      ]
                    ],
                  ),
                  trailing: Icon(Icons.chevron_right), // Themed
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EconomizeDetailScreen(economizeGoal: economizeGoal),
                      ),
                    );
                  },
                  isThreeLine: economizeGoal.amount > 0, // Make it three line if progress bar is shown
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
            MaterialPageRoute(builder: (context) => AddEditEconomizeScreen()),
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Add Savings Goal',
      ),
    );
  }
}
