import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:my_flutter_web_app/main.dart';
import 'package:provider/provider.dart';
import '../../models/debt.dart' as model_debt;
import '../../providers/debt_notifier.dart';
import '../../providers/category_notifier.dart'; 
import '../transactions/widgets/select_category_field.dart';

enum DebtPaymentMode { oneTime, installment } // Keep if needed, or simplify if not used

class AddEditDebtScreen extends StatefulWidget {
  final model_debt.Debt? debtToEdit;

  const AddEditDebtScreen({Key? key, this.debtToEdit}) : super(key: key);

  @override
  _AddEditDebtScreenState createState() => _AddEditDebtScreenState();
}

class _AddEditDebtScreenState extends State<AddEditDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _paymenAmountController;

  late TextEditingController _notesController;
  
  DateTime _initialDate = DateTime.now();
  DateTime? _dueDate;
  DocumentReference? _selectedCategoryRef;
  // DebtPaymentMode _paymentMode = DebtPaymentMode.oneTime; // Simplified for now
  bool _isSaving = false;

  bool get _isEditing => widget.debtToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final debt = widget.debtToEdit!;
      _nameController = TextEditingController(text: debt.creditor);
      _amountController = TextEditingController(text: debt.amount.toString());
      _notesController = TextEditingController(text: debt.comment ?? '');
      _initialDate = debt.firstPaymentDate;
      _dueDate = debt.dueDate;
      // _selectedCategoryRef = debt.categoryRef;
    } else {
      _nameController = TextEditingController();
      _amountController = TextEditingController();
      _notesController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, {bool isDueDate = false}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isDueDate ? (_dueDate ?? _initialDate) : _initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isDueDate) {
          _dueDate = picked;
        } else {
          _initialDate = picked;
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isSaving = true; });
      final scaffoldMessenger = _scaffoldMessengerKey.currentState; // Use the key
      final navigator = Navigator.of(context);

      final name = _nameController.text.trim();
      final totalAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;
      final paymentAmount = double.tryParse(_paymenAmountController.text.trim()) ?? 0.0;
      final notes = _notesController.text.trim();

      if (totalAmount <= 0) {
        scaffoldMessenger?.showSnackBar(SnackBar(content: Text('Total amount must be positive.'), backgroundColor: Colors.redAccent));
        setState(() { _isSaving = false; });
        return;
      }
      if (_selectedCategoryRef == null) {
        scaffoldMessenger?.showSnackBar(SnackBar(content: Text('Please select a category.'), backgroundColor: Colors.redAccent));
        setState(() { _isSaving = false; });
        return;
      }

      final newDebt = model_debt.Debt(
        id: _isEditing ? widget.debtToEdit!.id : '',
        creditor: name,
        amount: totalAmount,
        firstPaymentDate: _initialDate,
        comment: notes,
        dueDate: _initialDate,
        paymentRefs: _isEditing ? widget.debtToEdit!.paymentRefs : [],
        currency: _isEditing ? widget.debtToEdit!.currency : '', 
        paymentMode: '', 
        paymentMethod: '', 
        paymentAmount: paymentAmount, // Preserve if editing // Firestore handles for new via notifier
      );

      final debtNotifier = Provider.of<DebtNotifier>(context, listen: false);
      Future<void> futureAction;

      try {
        if (_isEditing) {
          await debtNotifier.updateDebt(newDebt);
        } else {
          await debtNotifier.addDebt(newDebt);
        }
        scaffoldMessenger?.showSnackBar(
          SnackBar(content: Text('Debt \${_isEditing ? "updated" : "added"} successfully!'), backgroundColor: Colors.green),
        );
        navigator.pop();
      } catch (error) {
        scaffoldMessenger?.showSnackBar(
            SnackBar(content: Text('Failed to \${_isEditing ? "update" : "add"} debt: \$error'), backgroundColor: Colors.redAccent));
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
    // Global InputDecorationTheme is applied from main.dart

    return Scaffold(
      key: _scaffoldMessengerKey, // Assign key here
      appBar: AppBar( // Themed
        title: Text(_isEditing ? 'Edit Debt' : 'Add Debt'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Creditor/Debtor Name'),
                style: textTheme.bodyLarge,
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(labelText: 'Total Debt Amount'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: textTheme.bodyLarge,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter an amount';
                  if (double.tryParse(value) == null || double.parse(value) <= 0) return 'Invalid amount';
                  return null;
                },
              ),
              SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text("Start Date: \${DateFormat.yMd().format(_initialDate)}", style: textTheme.bodyLarge),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _pickDate(context),
              ),
              SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text("Due Date (Optional): \${_dueDate != null ? DateFormat.yMd().format(_dueDate!) : 'Not set'}", style: textTheme.bodyLarge),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _pickDate(context, isDueDate: true),
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
                controller: _notesController,
                decoration: InputDecoration(labelText: 'Reason/Notes (Optional)'),
                style: textTheme.bodyLarge,
                maxLines: 3,
              ),
              SizedBox(height: 24),
              ElevatedButton( // Themed
                onPressed: _isSaving ? null : _submitForm,
                child: _isSaving 
                    ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary))
                    : Text(_isEditing ? 'Save Changes' : 'Add Debt'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
