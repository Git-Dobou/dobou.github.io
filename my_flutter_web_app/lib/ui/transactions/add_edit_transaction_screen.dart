import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:my_flutter_web_app/models/actionResult.dart';
import 'package:provider/provider.dart';
import '../../models/transaction.dart' as model;
import '../../providers/transaction_notifier.dart';
import './widgets/select_category_field.dart';

class AddEditTransactionScreen extends StatefulWidget {
  final model.Transaction? transactionToEdit;
  final  Function(Actionresult<model.Transaction>) callback;

  const AddEditTransactionScreen({Key? key, this.transactionToEdit, required this.callback})
      : super(key: key);

  @override
  _AddEditTransactionScreenState createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _typeController;
  late TextEditingController _cyklusController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  DateTime _selectedDate = DateTime.now();
  DateTime? _selectedDateUntil;

  String _transactionType = 'expense'; 
  DocumentReference? _selectedCategoryRef;
  bool _isFixed = false;
  String _transactionCycle = 'Monthly'; 

  bool get _isEditing => widget.transactionToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final transaction = widget.transactionToEdit!;
      _titleController = TextEditingController(text: transaction.title);
      _amountController = TextEditingController(text: transaction.amount.abs().toString());
      _noteController = TextEditingController(text: transaction.comment ?? '');
      _selectedDate = transaction.availableFrom;
      _selectedDateUntil = transaction.availableUntil;
      _transactionType = transaction.type;
      _selectedCategoryRef = transaction.categoryRef;
      _isFixed = transaction.isFixed;
      _transactionCycle = transaction.cyklus; // More robust cycle init
    } else {
      _titleController = TextEditingController();
      _amountController = TextEditingController();
      _noteController = TextEditingController();
      _typeController = TextEditingController();
      _cyklusController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDateFrom(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickDateUntil(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateUntil,
      firstDate: _selectedDate,
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDateUntil) {
      setState(() {
        _selectedDateUntil = picked;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {

      final transactionNotifier = Provider.of<TransactionNotifier>(context, listen: false);
      final scaffoldMessenger = ScaffoldMessenger.of(context); // Capture ScaffoldMessenger

      transactionNotifier.loading(true);
      final title = _titleController.text.trim();
      // final type = _typeController.text.trim();
      // final cyklus = _cyklusController.text.trim();
      final amountText = _amountController.text.trim();
      final note = _noteController.text.trim();
      double amount = double.tryParse(amountText) ?? 0.0;

      if (_selectedCategoryRef == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please select a category.'), backgroundColor: Colors.redAccent));
        return;
      }

      final transactionData = model.Transaction(
        id: _isEditing ? widget.transactionToEdit!.id : '', 
        title: title,
        type: _transactionType,
        cyklus: _transactionCycle,
        comment: note,
        amount: amount,
        availableFrom: _selectedDate,
        availableUntil: _selectedDateUntil,
        categoryRef: _selectedCategoryRef!,
        isFixed: _isFixed,
        currency: _isEditing ? widget.transactionToEdit!.currency : null, 
        parentRef: _isEditing ? widget.transactionToEdit!.parentRef : null,
        subTransactionsRef: _isEditing ? widget.transactionToEdit!.subTransactionsRef : null,
        transactionNewAmountsRef: _isEditing ? widget.transactionToEdit!.transactionNewAmountsRef : null,
        transactionStatusRef: _isEditing ? widget.transactionToEdit!.transactionStatusRef : null,
      );

      
      Future<void> futureAction;
      if (_isEditing) {
        futureAction = transactionNotifier.updateTransaction(transactionData);
      } else {
        futureAction = transactionNotifier.addTransaction(transactionData);
      }

      futureAction.then((_) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Transaction ${_isEditing ? "updated" : "added"} successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }).catchError((error) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Failed to ${_isEditing ? "update" : "add"} transaction: $error'), backgroundColor: Colors.redAccent));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // InputDecoration is already themed globally

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Transaction' : 'Add Transaction'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
                style: textTheme.bodyLarge,
                validator: (value) => value!.isEmpty ? 'Please enter a title' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: textTheme.bodyLarge,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter an amount';
                  if (double.tryParse(value) == null) return 'Invalid amount';
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _transactionType,
                decoration: InputDecoration(labelText: 'Type'),
                items: ['expense', 'income'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value[0].toUpperCase() + value.substring(1), style: textTheme.bodyLarge),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _transactionType = newValue!;
                  });
                },
              ),
              SizedBox(height: 16),

              SwitchListTile(
                title: Text('Fixed Transaction (Recurring)', style: textTheme.bodyLarge),
                value: _isFixed,
                onChanged: (bool value) {
                  setState(() {
                    _isFixed = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),

              ListTile(
                contentPadding: EdgeInsets.zero, // Aligns with TextFormField
                title: Text("From: ${DateFormat.yMd().format(_selectedDate)}", style: textTheme.bodyLarge),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _pickDateFrom(context),
              ),
              
              if (_isFixed)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                  child: DropdownButtonFormField<String>(
                    value: _transactionCycle,
                    decoration: InputDecoration(labelText: 'Cycle'),
                    items: model.TransactionCyklus.values.map((v) => v.name).map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value[0].toUpperCase() + value.substring(1), style: textTheme.bodyLarge),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _transactionCycle = newValue!;
                      });
                    },
                  ),
                ),
              
              if(_isFixed)
                ListTile(
                contentPadding: EdgeInsets.zero, // Aligns with TextFormField
                title: Text("Until: ${DateFormat.yMd().format(_selectedDateUntil ?? DateTime.now())}", style: textTheme.bodyLarge),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _pickDateUntil(context),
              ),

              SizedBox(height: 16),
              SelectCategoryField(
                initialValue: _selectedCategoryRef,
                onChanged: (DocumentReference? newCategoryRef) {
                  setState(() {
                    _selectedCategoryRef = newCategoryRef;
                  });
                },
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(labelText: 'Note (Optional)'),
                style: textTheme.bodyLarge,
                maxLines: 3,
              ),
              SizedBox(height: 24),
              ElevatedButton( // ElevatedButtonTheme from main.dart will apply
                onPressed: _submitForm,
                child: Text(_isEditing ? 'Save Changes' : 'Add Transaction'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
