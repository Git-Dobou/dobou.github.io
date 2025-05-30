import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:provider/provider.dart';
import '../../providers/auth_notifier.dart';
import '../../providers/transaction_notifier.dart';
import '../../providers/category_notifier.dart'; 
import '../../models/category.dart' as model_cat; 
import '../../models/transaction.dart' as model_trans; 
import './add_edit_transaction_screen.dart';
import './transaction_detail_screen.dart';

class TransactionListScreen extends StatefulWidget {
  @override
  _TransactionListScreenState createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {

  @override
  Widget build(BuildContext context) {
    final authNotifier = Provider.of<AuthNotifier>(context);
    final transactionNotifier = Provider.of<TransactionNotifier>(context); 
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;


    if (authNotifier.user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Transactions')), // Will use themed AppBar
        body: Center(child: Text('Please log in to view transactions.')),
      );
    }

    final currencyFormat = NumberFormat.simpleCurrency(locale: 'de_DE'); 
    final categoryNotifier = Provider.of<CategoryNotifier>(context);
    final transactionNotifierConsumer = Provider.of<TransactionNotifier>(context);

  int filteredIndex = 2; // 0 = paid, 1 = unpaid, 2 = all
  int filteredTransactionsIndex = 1; // 0 = income, 1 = expense
  bool showStatistic = false;
  bool isAddingTransaction = false;

  String searchText = '';

  DateTime selectedDate = DateTime.now();

  List<model_trans.Transaction> getFilteredTransactions() {
    var type = filteredTransactionsIndex == 0 ? model_trans.TransactionType.Income 
                : model_trans.TransactionType.Expense;

    List<model_trans.Transaction> baseList = transactionNotifierConsumer.transactions
    .where((b) => b.typeTypisiert == type)
    .toList(); 

    var filteredBySearch = baseList.where((tx) {
      return searchText.isEmpty ||
          tx.title.toLowerCase().contains(searchText.toLowerCase());
    }).toList();

    switch (filteredIndex) {
      case 0:
        return filteredBySearch.where((tx) {
          return !tx.isDeactivated &&
              tx.isPayed &&
              transactionNotifierConsumer.checkTransactionForMonth(tx, transactionNotifierConsumer.selectedMonth);
        }).toList();
      case 1:
        return filteredBySearch.where((tx) {
          return !tx.isDeactivated &&
              !tx.isPayed &&
              transactionNotifierConsumer.checkTransactionForMonth(tx, transactionNotifierConsumer.selectedMonth);
        }).toList();
      default:
        return filteredBySearch.where((tx) {
          return transactionNotifierConsumer.checkTransactionForMonth(tx, transactionNotifierConsumer.selectedMonth);
        }).toList();
    }
  }
  
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Transactions'), // AppBarTheme handles this style
            Text(
              DateFormat.yMMMM().format(transactionNotifier.selectedMonth),
              style: textTheme.titleMedium?.copyWith(color: colorScheme.onPrimary.withOpacity(0.8)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.chevron_left),
            onPressed: () {
              final currentMonth = transactionNotifier.selectedMonth;
              transactionNotifier.selectMonth(DateTime(currentMonth.year, currentMonth.month - 1, 1));
            },
            tooltip: 'Previous Month',
          ),
          IconButton(
            icon: Icon(Icons.chevron_right),
            onPressed: () {
              final currentMonth = transactionNotifier.selectedMonth;
              transactionNotifier.selectMonth(DateTime(currentMonth.year, currentMonth.month + 1, 1));
            },
            tooltip: 'Next Month',
          ),
        ],
      ),
      body: Consumer<TransactionNotifier>(
builder: (context, vm, child) {
    if (vm.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    final List<Widget> headerWidgets = [
      Padding(
        padding: const EdgeInsets.all(12.0),
        child: TextField(
          decoration: InputDecoration(
            labelText: 'Search transaction',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (val) => setState(() => searchText = val),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Selected month: ${selectedDate.month}/${selectedDate.year}',
                style: TextStyle(fontSize: 16),
              ),
            ),
            TextButton(
              child: Text('Change'),
              onPressed: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  firstDate: selectedDate,
                  lastDate: selectedDate
                );
                if (picked != null) {
                  setState(() {
                    selectedDate = picked;
                    vm.selectMonth(picked);
                  });
                }
              },
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Expanded(
              child: DropdownButton<int>(
                value: filteredTransactionsIndex,
                isExpanded: true,
                items: [
                  DropdownMenuItem(value: 0, child: Text('Income')),
                  DropdownMenuItem(value: 1, child: Text('Expense')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => filteredTransactionsIndex = val);
                },
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: DropdownButton<int>(
                value: filteredIndex,
                isExpanded: true,
                items: [
                  DropdownMenuItem(value: 0, child: Text('Paid')),
                  DropdownMenuItem(value: 1, child: Text('Unpaid')),
                  DropdownMenuItem(value: 2, child: Text('All')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => filteredIndex = val);
                },
              ),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            SummaryCard(title: 'Income', amount: vm.incomesTotal, color: Colors.green),
            SummaryCard(title: 'Expense', amount: vm.expensesTotal, color: Colors.red),
            SummaryCard(title: 'Difference', amount: vm.difference, color: Colors.blue),
          ],
        ),
      ),
    ];
        final transactionWidgets = getFilteredTransactions().map((transaction) {
      return Card(
        child: ListTile(
          leading: Icon(
            transaction.amount >= 0 ? Icons.arrow_downward : Icons.arrow_upward,
            color: transaction.amount >= 0 ? Colors.green[700] : Colors.red[700],
            size: 30,
          ),
          title: Text(transaction.title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Category: ${transaction.category?.name ?? transaction.categoryRef?.id ?? "N/A"}', style: textTheme.bodySmall),
              Text('Date: ${DateFormat.yMd().format(transaction.availableFrom)}', style: textTheme.bodySmall),
              if (transaction.comment?.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text('Note: ${transaction.comment}', style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  currencyFormat.format(transaction.amount),
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: transaction.amount >= 0 ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEditTransactionScreen(transactionToEdit: transaction),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.delete, color: colorScheme.error),
                onPressed: () => showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('Confirm Delete'),
                    content: Text('Are you sure you want to delete "${transaction.title}"?'),
                    actions: [
                      TextButton(
                        child: Text('Cancel'),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                      TextButton(
                        child: Text('Delete', style: TextStyle(color: colorScheme.error)),
                        onPressed: () {
                          context.read<TransactionNotifier>().deleteTransaction(transaction.id).then((_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('"${transaction.title}" deleted successfully')),
                            );
                          }).catchError((error) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error deleting transaction: $error')),
                            );
                          });
                          Navigator.of(ctx).pop();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          isThreeLine: true,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionDetailScreen(transaction: transaction),
            ),
          ),
        ),
      );
    }).toList();

            return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        ...headerWidgets,
        if (getFilteredTransactions().isEmpty)
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text('No transactions found.', style: textTheme.titleMedium, textAlign: TextAlign.center),
                  SizedBox(height: 8),
                  Text('Tap "+" to add one.', style: textTheme.bodyMedium, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ...transactionWidgets,
      ],
    );
  },
),
      
      floatingActionButton: FloatingActionButton( // FAB theme from main.dart will apply
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddEditTransactionScreen()), 
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Add Transaction',
      ),
    );
  }
}

// Summary Card Widget
class SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;

  const SummaryCard({
    Key? key,
    required this.title,
    required this.amount,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formattedAmount = amount.toStringAsFixed(2); // Du kannst noch NumberFormat verwenden

    return Container(
      padding: EdgeInsets.all(12),
      width: 100,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          SizedBox(height: 4),
          Text(formattedAmount, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}