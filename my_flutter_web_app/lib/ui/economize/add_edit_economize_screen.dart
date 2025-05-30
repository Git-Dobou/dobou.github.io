import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/economize.dart' as model_economize;
import '../../providers/debt_notifier.dart'; // Manages Economize goals
import '../transactions/widgets/select_category_field.dart'; 

class AddEditEconomizeScreen extends StatefulWidget {
  final model_economize.Economize? economizeGoal; 

  const AddEditEconomizeScreen({Key? key, this.economizeGoal})
      : super(key: key);

  @override
  _AddEditEconomizeScreenState createState() =>
      _AddEditEconomizeScreenState();
}

class _AddEditEconomizeScreenState extends State<AddEditEconomizeScreen> {
  final _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  late TextEditingController _titleController;
  late TextEditingController _goalAmountController;
  DateTime _selectedTargetDate = DateTime.now();
  DocumentReference? _selectedCategoryRef;
  bool _isSaving = false;

  bool get _isEditing => widget.economizeGoal != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final goal = widget.economizeGoal!;
      _titleController = TextEditingController(text: goal.name);
      _goalAmountController = TextEditingController(text: goal.amount.toString());
      _selectedTargetDate = goal.date;
      _selectedCategoryRef = goal.categoryRef;
    } else {
      _titleController = TextEditingController();
      _goalAmountController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _goalAmountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedTargetDate,
      firstDate: DateTime.now().subtract(Duration(days:1)), // Allow today
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedTargetDate) {
      setState(() {
        _selectedTargetDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isSaving = true; });
      final scaffoldMessenger = _scaffoldMessengerKey.currentState;
      final navigator = Navigator.of(context);

      final title = _titleController.text.trim();
      final goalAmountText = _goalAmountController.text.trim();
      double goalAmount = double.tryParse(goalAmountText) ?? 0.0;

      if (_selectedCategoryRef == null) {
        scaffoldMessenger?.showSnackBar(
            SnackBar(content: Text('Please select a category.'), backgroundColor: Colors.redAccent));
        if (mounted) setState(() { _isSaving = false; });
        return;
      }
      if (goalAmount <= 0) {
         scaffoldMessenger?.showSnackBar(
            SnackBar(content: Text('Goal amount must be positive.'), backgroundColor: Colors.redAccent));
        if (mounted) setState(() { _isSaving = false; });
        return;
      }

      final newGoal = model_economize.Economize(
        id: _isEditing ? widget.economizeGoal!.id : '',
        name: title,
        amount: goalAmount,
        date: _selectedTargetDate,
        categoryRef: _selectedCategoryRef!,
        transactionRefs: _isEditing ? widget.economizeGoal!.transactionRefs : [],
        savedAmount: _isEditing ? widget.economizeGoal!.savedAmount : 0.0, // Initialize savedAmount for new goals
        isReached: _isEditing ? widget.economizeGoal!.isReached : false,
        comment: _isEditing ? widget.economizeGoal!.comment : null,
        currency: _isEditing ? widget.economizeGoal!.currency : null,
        idOld: _isEditing ? widget.economizeGoal!.idOld : null,
        isDeleted: _isEditing ? widget.economizeGoal!.isDeleted : false,
        timestamp: _isEditing ? widget.economizeGoal!.timestamp : null,
      );

      final debtNotifier = Provider.of<DebtNotifier>(context, listen: false);
      Future<void> futureAction;
      if (_isEditing) {
        futureAction = debtNotifier.updateEconomize(newGoal);
      } else {
        futureAction = debtNotifier.addEconomize(newGoal);
      }

      try {
        await futureAction;
        scaffoldMessenger?.showSnackBar(
          SnackBar(content: Text('Savings Goal \${_isEditing ? "updated" : "added"} successfully!'), backgroundColor: Colors.green),
        );
        navigator.pop();
      } catch (error) {
        scaffoldMessenger?.showSnackBar(
            SnackBar(content: Text('Failed to \${_isEditing ? "update" : "add"} goal: \$error'), backgroundColor: Colors.redAccent));
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
    // Global InputDecorationTheme applied from main.dart

    return Scaffold(
      key: _scaffoldMessengerKey,
      appBar: AppBar( // Themed
        title: Text(_isEditing ? 'Edit Savings Goal' : 'Add Savings Goal'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Goal Title'),
                style: textTheme.bodyLarge,
                validator: (value) => value!.isEmpty ? 'Please enter a title' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _goalAmountController,
                decoration: InputDecoration(labelText: 'Goal Amount'),
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
                title: Text("Target Date: \${DateFormat.yMd().format(_selectedTargetDate)}", style: textTheme.bodyLarge),
                trailing: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                onTap: _isSaving ? null : () => _pickDate(context),
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
              SizedBox(height: 24),
              ElevatedButton( // Themed
                onPressed: _isSaving ? null : _submitForm,
                child: _isSaving 
                    ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary))
                    : Text(_isEditing ? 'Save Changes' : 'Add Goal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
