import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_flutter_web_app/models/debt.dart';
import 'package:provider/provider.dart';
import '../../models/payment.dart' as model_payment;
import '../../providers/debt_notifier.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 

class AddPaymentDialog extends StatefulWidget {
  final Debt debt;

  const AddPaymentDialog({Key? key, required this.debt}) : super(key: key);

  @override
  _AddPaymentDialogState createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<AddPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  // Note: _noteController was commented out in previous version, keeping it that way unless model changes
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(), // Payments usually not in future
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isSaving = true; });
      final scaffoldMessenger = ScaffoldMessenger.of(context); // Capture context
      final navigator = Navigator.of(context); // Capture context for pop

      final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

      if (amount <= 0) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Payment amount must be positive.'), backgroundColor: Colors.redAccent));
        if (mounted) setState(() { _isSaving = false; });
        return;
      }

      final newPayment = model_payment.Payment(
        id: '', // Firestore will generate
        amount: amount,
        date: _selectedDate, 
        note: '', 
        reason: '',
      );

      final debtNotifier = Provider.of<DebtNotifier>(context, listen: false);
      try {
        await debtNotifier.addPaymentToDebt(widget.debt, newPayment);
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Payment added successfully!'), backgroundColor: Colors.green),
        );
        navigator.pop(); // Close the dialog on success
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Failed to add payment: $e'), backgroundColor: Colors.redAccent),
        );
      } finally {
        if (mounted) {
          setState(() { _isSaving = false; });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // AlertDialog, TextFormField, ElevatedButton will be styled by global themes from main.dart

    return AlertDialog(
      title: Text('Add Payment', style: textTheme.titleLarge),
      contentPadding: const EdgeInsets.all(20.0),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(labelText: 'Payment Amount'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              style: textTheme.bodyLarge,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                if (double.tryParse(value) == null || double.parse(value) <= 0) {
                  return 'Invalid amount';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text("Payment Date: ${DateFormat.yMd().format(_selectedDate)}", style: textTheme.bodyLarge),
              trailing: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
              onTap: _isSaving ? null : () => _pickDate(context),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      actions: <Widget>[
        TextButton( // Themed by main.dart
          child: Text('Cancel'),
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
        ),
        ElevatedButton( // Themed by main.dart
          onPressed: _isSaving ? null : _submitForm,
          child: _isSaving 
              ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary))
              : Text('Add Payment'),
        ),
      ],
    );
  }
}
