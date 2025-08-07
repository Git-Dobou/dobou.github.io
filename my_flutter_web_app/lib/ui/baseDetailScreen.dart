import 'package:flutter/material.dart';
import 'package:my_flutter_web_app/models/debt.dart' as model_debt;
import 'package:my_flutter_web_app/providers/debt_notifier.dart';
import 'package:my_flutter_web_app/ui/debts/add_edit_debt_screen.dart';

abstract class BaseDetailScreen<T> extends StatefulWidget {
  final T item;
  final String Function(T item) getTitle;
  final Widget Function(T item) buildEditScreen;
  final Future<void> Function(T item, BuildContext context) onDelete;

  const BaseDetailScreen({
    super.key,
    required this.item,
    required this.getTitle,
    required this.buildEditScreen,
    required this.onDelete,
  });

  @override
  State<BaseDetailScreen<T>> createState() => _BaseDetailScreenState<T>();

  /// Diese Methode muss von der Kindklasse überschrieben werden
  Widget buildBody(BuildContext context, T item);
}


class _BaseDetailScreenState<T> extends State<BaseDetailScreen<T>> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.getTitle(widget.item)),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => widget.buildEditScreen(widget.item),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.delete, color: colorScheme.error),
            tooltip: 'Delete',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('Confirm Delete', style: textTheme.titleLarge),
                  content: Text('Are you sure you want to delete "${widget.getTitle(widget.item)}"?', style: textTheme.bodyLarge),
                  actions: [
                    TextButton(
                      child: Text('Cancel'),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                    TextButton(
                      child: Text('Delete', style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        final navigator = Navigator.of(ctx);
                        try {
                          await widget.onDelete(widget.item, context);
                          navigator.pop(); // close dialog
                          Navigator.of(context).pop(); // close screen
                        } catch (error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error deleting: $error'), backgroundColor: Colors.red),
                          );
                          navigator.pop(); // close dialog
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: widget.buildBody(context, widget.item),
    );
  }
}

// class DebtDetailScreen extends BaseDetailScreen<model_debt.Debt> {
//   final DebtNotifier notifier;

//   DebtDetailScreen({super.key, required model_debt.Debt debt, required this.notifier})
//       : super(
//           item: debt,
//           getTitle: (d) => d.creditor,
//           buildEditScreen: (d) => AddEditDebtScreen(debtToEdit: d, callback: (_) {}),
//           onDelete: (d, context) => notifier.deleteDebt(d.id!),
//         );

//   @override
//   Widget buildBody(BuildContext context, model_debt.Debt debt) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         children: [
//           Text('Betrag: ${debt.amount}', style: Theme.of(context).textTheme.headlineSmall),
//           // Dein eigener Inhalt hier
//         ],
//       ),
//     );
//   }
// }
