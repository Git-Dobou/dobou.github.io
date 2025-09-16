import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_flutter_web_app/models/actionResult.dart'; 
import 'package:provider/provider.dart';
import '../../providers/auth_notifier.dart';
import '../../providers/transaction_notifier.dart';
import '../../models/transaction.dart' as model_trans; 
import './add_edit_transaction_screen.dart';
import './transaction_detail_screen.dart';
import 'package:shimmer/shimmer.dart';

class TransactionListScreen extends StatefulWidget {
  @override
  _TransactionListScreenState createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  
  TransactionNotifier get notifier => Provider.of<TransactionNotifier>(context, listen: false);
  bool _transactionsLoaded = false;

@override
void initState() {
  super.initState();
  Future.delayed(Duration.zero, () {
    if (!_transactionsLoaded) {
      notifier.fetchTransactions();
      _transactionsLoaded = true;
    }
  });
}

  int filteredIndex = 2; // 0 = paid, 1 = unpaid, 2 = all
  int filteredTransactionsIndex = 1; // 0 = income, 1 = expense
  bool showStatistic = false;
  bool isAddingTransaction = false;

  String searchText = '';

  DateTime selectedDate = DateTime.now();

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
    final transactionNotifierConsumer = Provider.of<TransactionNotifier>(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Transactions')// AppBarTheme handles this style
          ],
        ),
        ),
      body: Consumer<TransactionNotifier>(
builder: (context, vm, child) {

    final List<Widget> headerWidgets = [
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          decoration: InputDecoration(
            labelText: 'Search transaction',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (val) => setState(() {
            vm.searchText = val;
            vm.setFilteredTransactions();
          }),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          IconButton(
            icon: Icon(Icons.arrow_circle_left_outlined, size: 35),
            onPressed: () {
              final currentMonth = transactionNotifier.selectedMonth;
              transactionNotifier.selectMonth(DateTime(currentMonth.year, currentMonth.month - 1, 1));
            },
            tooltip: 'Previous Month',
          ),
          Text(
              DateFormat.yMMMM().format(transactionNotifier.selectedMonth),
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          IconButton(
            icon: Icon(Icons.arrow_circle_right_outlined, size: 35 ),
            onPressed: () {
              final currentMonth = transactionNotifier.selectedMonth;
              transactionNotifier.selectMonth(DateTime(currentMonth.year, currentMonth.month + 1, 1));
            },
            tooltip: 'Next Month',
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
                value: vm.filteredTransactionsIndex,
                isExpanded: true,
                items: [
                  DropdownMenuItem(value: 0, child: Text('Income')),
                  DropdownMenuItem(value: 1, child: Text('Expense')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() {
                    vm.filteredTransactionsIndex = val;
                    vm.setFilteredTransactions();
                    });
                },
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: DropdownButton<int>(
                value: vm.filteredIndex,
                isExpanded: true,
                items: [
                  DropdownMenuItem(value: 0, child: Text('Paid')),
                  DropdownMenuItem(value: 1, child: Text('Unpaid')),
                  DropdownMenuItem(value: 2, child: Text('All')),
                ],
                               onChanged: (val) {
                  if (val != null) setState(() {
                    vm.filteredIndex = val;
                    vm.setFilteredTransactions();
                    });
                },
              ),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
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
        final transactionWidgets =vm.filteredTransactionsForView.map((transaction) {
      return Card(
        child: ListTile(
          leading: Icon(
            transaction.amount >= 0 ? Icons.arrow_downward : Icons.arrow_upward,
            color: transaction.amount >= 0 ? Colors.green[700] : Colors.red[700],
            size: 30,
          ),
title: Text(
                    transaction.title,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

  Text(
    'Category: ${transaction.category?.name ?? transaction.categoryRef?.id ?? "N/A"}',
    style: textTheme.bodyMedium,
  ),
  Text(
    transaction.isTransactionDeactivated(vm.selectedMonth)
        ? 'Deaktiviert'
        : transaction.isTransactionPayed(vm.selectedMonth)
            ? 'Bezahlt'
            : 'Pending',
    style: textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.bold,
      color: transaction.isTransactionPayed(vm.selectedMonth)
          ? Colors.green[700]
          : transaction.isTransactionDeactivated(vm.selectedMonth)
              ? Colors.red[700]
              : Colors.orangeAccent[700],
    ),
  ),
  if (transaction.comment?.isNotEmpty == true)
    Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text(
        'Note: ${transaction.comment}',
        style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
      ),
    ),
]

              // Text('Category: ${transaction.category?.name ?? transaction.categoryRef?.id ?? "N/A"}', style: textTheme.bodyMedium),
              // Text(transaction.isDeactivated ? 'Deaktiviert' : transaction.isTransactionPayed(vm.selectedMonth) ? 'Bezahlt' : 'Pending', 
              //     style: textTheme.bodyLarge?.copyWith(
              //       fontWeight: FontWeight.bold,
              //       color: transaction.isTransactionPayed(vm.selectedMonth) ? Colors.green[700] : transaction.isDeactivated ? Colors.red[700] : Colors.orangeAccent[700],
              //     ),              
              // ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  currencyFormat.format(transaction.getAmount(vm.selectedMonth)),
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: transaction.typeTypisiert == model_trans.TransactionType.Income ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              )
            ]
          ),
          //     IconButton(
          //       icon: Icon(Icons.edit),
          //       onPressed: () {
          //         Navigator.push(
          //           context,
          //           MaterialPageRoute(
          //             builder: (context) => AddEditTransactionScreen(transactionToEdit: transaction),
          //           ),
          //         );
          //       },
          //     ),
          //     IconButton(
          //       icon: Icon(Icons.delete, color: colorScheme.error),
          //       onPressed: () => showDialog(
          //         context: context,
          //         builder: (ctx) => AlertDialog(
          //           title: Text('Confirm Delete'),
          //           content: Text('Are you sure you want to delete "${transaction.title}"?'),
          //           actions: [
          //             TextButton(
          //               child: Text('Cancel'),
          //               onPressed: () => Navigator.of(ctx).pop(),
          //             ),
          //             TextButton(
          //               child: Text('Delete', style: TextStyle(color: colorScheme.error)),
          //               onPressed: () {
          //                 context.read<TransactionNotifier>().deleteTransaction(transaction.id).then((_) {
          //                   ScaffoldMessenger.of(context).showSnackBar(
          //                     SnackBar(content: Text('"${transaction.title}" deleted successfully')),
          //                   );
          //                 }).catchError((error) {
          //                   ScaffoldMessenger.of(context).showSnackBar(
          //                     SnackBar(content: Text('Error deleting transaction: $error')),
          //                   );
          //                 });
          //                 Navigator.of(ctx).pop();
          //               },
          //             ),
          //           ],
          //         ),
          //       ),
          //     ),
          //   ],
          // ),
          isThreeLine: true,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionDetailScreen(transaction: transaction, callback: (result) {
                setState(() {
                  if(result.actionresultEnum == ActionresultEnum.delete){
                    setState(() {
                      var index = transactionNotifier.transactions.indexWhere((b) => b.id == transaction.id);
                      transactionNotifier.transactions.removeAt(index);
                    });
                  }
                });
              }),
            ),
          ),
        ),
      );
    }).toList();

            return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        ...headerWidgets,
            if (vm.isLoading)
Padding(
  padding: const EdgeInsets.all(20.0),
  child: Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    ),
  ),
),

        if (!vm.isLoading && vm.filteredTransactionsForView.isEmpty)
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
        onPressed: () async {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddEditTransactionScreen(callback: (result) async {
              var ref = await transactionNotifierConsumer.getRef(result.data!.id, 'transaction');
              var transaction = await transactionNotifier.BuildTransactionWithBoth(result.data!, ref!);
              setState(() {
                transactionNotifier.transactions.add(transaction);
              });
            })), 
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
    final textTheme = Theme.of(context).textTheme;
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'de_DE'); 

    return Container(
      padding: EdgeInsets.all(8),
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
          Text(currencyFormat.format(amount), style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
