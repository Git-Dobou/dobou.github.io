import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:my_flutter_web_app/providers/transaction_notifier.dart';
import 'package:provider/provider.dart';
import '../../../providers/category_notifier.dart';
import '../../../models/category.dart' as model;
import '../../../models/transaction.dart' as model_transaction;

class SelectCategoryField extends StatelessWidget {
  final DocumentReference? initialValue;
  final Function(DocumentReference?) onChanged;

  const SelectCategoryField({
    Key? key,
    this.initialValue,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categoryNotifier = Provider.of<CategoryNotifier>(context);

    // Find the initial category object from the list to match the initialValue DocumentReference
    model.Category? initialCategory;
    if (initialValue != null && categoryNotifier.categories.isNotEmpty) {
      try {
        initialCategory = categoryNotifier.categories.firstWhere((cat) => cat.id == initialValue!.id);
      } catch (e) {
        // Initial category ID not found in the current list, can happen if list is loading or ID is stale
        print("Initial category for SelectCategoryField not found in notifier: ${initialValue!.id}");
        initialCategory = null;
      }
    }

    return DropdownButtonFormField<DocumentReference>(
      value: initialCategory != null 
          ? FirebaseFirestore.instance.collection('category').doc(initialCategory.id)
          : null,
      decoration: InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(),
      ),
      hint: Text('Select a category'),
      isExpanded: true,
      items: categoryNotifier.categories.map((model.Category category) {
        return DropdownMenuItem<DocumentReference>(
          value: FirebaseFirestore.instance.collection('category').doc(category.id),
          child: Row( // Display icon and name
            children: [
              // TODO: Implement proper icon display based on category.icon data
              // For now, using a placeholder icon if category.icon is just a string name
              // Icon(Icons.label_outline, size: 20), // Placeholder
              // SizedBox(width: 8),
              Text(category.name),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null) {
          return 'Please select a category.';
        }
        return null;
      },
    );
  }
}

class SelectTransactionField extends StatelessWidget {
  final model_transaction.Transaction? initialValue;
  final Function(model_transaction.Transaction?) onChanged;

  const SelectTransactionField({
    Key? key,
    this.initialValue,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categoryNotifier = Provider.of<TransactionNotifier>(context);
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'de_DE'); 

    // Find the initial category object from the list to match the initialValue DocumentReference
    model_transaction.Transaction? initialCategory;
    if (initialValue != null && categoryNotifier.transactions.isNotEmpty) {
      try {
        initialCategory = categoryNotifier.transactions.firstWhere((cat) => cat.id == initialValue!.id);
      } catch (e) {
        // Initial category ID not found in the current list, can happen if list is loading or ID is stale
        print("Initial category for SelectCategoryField not found in notifier: ${initialValue!.id}");
        initialCategory = null;
      }
    }

    return DropdownButtonFormField<model_transaction.Transaction>(
      value: initialCategory,
      decoration: InputDecoration(
        labelText: 'Trasansaction',
        border: OutlineInputBorder(),
      ),
      hint: Text('Select a transaction'),
      isExpanded: true,
      items: categoryNotifier.transactions.map((model_transaction.Transaction category) {
        return DropdownMenuItem<model_transaction.Transaction>(
          value: category,
          child: Row( // Display icon and name
            children: [
              // TODO: Implement proper icon display based on category.icon data
              // For now, using a placeholder icon if category.icon is just a string name
              // Icon(Icons.label_outline, size: 20), // Placeholder
              // SizedBox(width: 8),
              Text(category.title),
              SizedBox(width: 8),
              Text(currencyFormat.format(category.amount)),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged
    );
  }
}
