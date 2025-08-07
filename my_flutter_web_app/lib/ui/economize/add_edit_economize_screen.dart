
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:my_flutter_web_app/providers/transaction_notifier.dart';
import 'package:provider/provider.dart';
import '../../models/economize.dart' as model_economize;
import '../../models/transaction.dart' as model_transaction;
import '../../providers/debt_notifier.dart'; // Manages Economize goals
import '../transactions/widgets/select_category_field.dart'; 

class AddEditEconomizeScreen extends StatefulWidget {
  final model_economize.Economize? economizeGoal; 
  final  Function(model_economize.Economize) callback;

  const AddEditEconomizeScreen({Key? key, this.economizeGoal,required this.callback})
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
  late TextEditingController _beginingAmountController;
    late TextEditingController _transactionAmountController;

  DateTime _selectedTargetDate = DateTime.now();
    DateTime _selectedTransactionDate = DateTime.now();

  DocumentReference? _selectedCategoryRef;
  List<model_transaction.Transaction> _transactions = [];
  bool _isSaving = false;
  bool _createNewTransaction = false;

  bool get _isEditing => widget.economizeGoal != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final goal = widget.economizeGoal!;
      _titleController = TextEditingController(text: goal.title);
      _goalAmountController = TextEditingController(text: goal.goalAmount.toString());
      _beginingAmountController = TextEditingController(text: goal.goalAmount.toString());
      // _selectedTargetDate = goal.date;
      _selectedCategoryRef = goal.categoryRef;
    } else {
      _titleController = TextEditingController();
      _goalAmountController = TextEditingController();
      _beginingAmountController = TextEditingController();
      _transactionAmountController = TextEditingController();
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
      double goalAmount = double.tryParse(_goalAmountController.text.trim()) ?? 0.0;
      double beginingAmount = double.tryParse(_beginingAmountController.text.trim()) ?? 0.0;
      double transactionAmount = 0;

      if(_createNewTransaction){
        transactionAmount = double.tryParse(_transactionAmountController.text.trim()) ?? 0.0;
      }

      final debtNotifier = Provider.of<DebtNotifier>(context, listen: false);
      final transactionNotifier = Provider.of<TransactionNotifier>(context, listen: false);

      if (_selectedCategoryRef == null) {
        scaffoldMessenger?.showSnackBar( 
            SnackBar(content: Text('Please select a category.'), backgroundColor: Colors.redAccent));
        if (mounted) setState(() { _isSaving = false; });
        return;
      }
      
      List<DocumentReference> refs = [];
      for(var tr in _transactions) {
        var refTr = await debtNotifier.getRef(tr.id, 'transaction');
        refs.add(refTr!);
      }
            
      if(_createNewTransaction) {
        var newtransaction = model_transaction.Transaction(id: '', title: title, type: 'Expense', cyklus: 'Monthly', amount: transactionAmount, availableFrom: _selectedTransactionDate, availableUntil: _selectedTargetDate, categoryRef: _selectedCategoryRef, isFixed: true);
        var doc = await transactionNotifier.addTransaction(newtransaction);
        var transaction = await transactionNotifier.BuildTransactionFromDoc(doc);
        setState(() {
          transactionNotifier.transactions.add(transaction);
        });
        refs.add(doc);
      }

      final newGoal = model_economize.Economize(
        id: _isEditing ? widget.economizeGoal!.id : '', 
        title: title,
        goalAmount: goalAmount,
        beginAmount: beginingAmount,
        transactionRefs: _isEditing ? widget.economizeGoal!.transactionRefs : refs,
      );


      Future<void> futureAction;
      if (_isEditing) {
        futureAction = debtNotifier.updateEconomize(newGoal);
      } else {
        futureAction = debtNotifier.addEconomize(newGoal);
      }

      try {
        await futureAction;
        scaffoldMessenger?.showSnackBar(
          SnackBar(content: Text('Savings Goal ${_isEditing ? "updated" : "added"} successfully!'), backgroundColor: Colors.green),
        );
        navigator.pop();
        widget.callback.call(newGoal);
      } catch (error) {
        scaffoldMessenger?.showSnackBar(
            SnackBar(content: Text('Failed to ${_isEditing ? "update" : "add"} goal: $error'), backgroundColor: Colors.redAccent));
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
    final dateFormat = DateFormat.yMMMMd(); 
    final colorScheme = Theme.of(context).colorScheme;

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
                controller: _beginingAmountController,
                decoration: InputDecoration(labelText: 'Begining Amount'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: textTheme.bodyLarge,
                validator: (value) {
                  if (value!.isEmpty) return null;
                  if (double.tryParse(value) == null || double.parse(value) < 0) return 'Invalid amount';
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _goalAmountController,
                decoration: InputDecoration(labelText: 'Goal Amount'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: textTheme.bodyLarge,
                validator: (value) {
                  if (value!.isEmpty) return null;
                  if (double.tryParse(value) == null || double.parse(value) < 0) return 'Invalid amount';
                  return null;
                },
              ),
              SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text("Target Date: ${DateFormat.yMd().format(_selectedTargetDate)}", style: textTheme.bodyLarge),
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
              SizedBox(height: 16),

              SizedBox(height: 16),
              SelectTransactionField(
                onChanged: (transaction) {
                  setState(() {
                    if(transaction != null) {
                      _transactions.add(transaction);
                    }

                  });
                },
              ),
              SizedBox(height: 16),

              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final payment = _transactions[index];
                      return Card(
                        elevation: 1.0,
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        child: ListTile(
                          leading: Icon(Icons.payment, color: colorScheme.secondary),
                          title: Text('${ payment.title} ${payment.amount} ${payment.currency ?? 'EUR'} : ${DateFormat('MMM yyyy').format(payment.availableFrom)}', style: textTheme.bodyMedium),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: colorScheme.error),
                            onPressed: () => 
                              setState(() {
                                _transactions.remove(payment);
                              })
                          ),
                        ),
                      );
                    },
                  ),
                ]
              ),
              SwitchListTile(
                title: Text('Create new transaction', style: textTheme.bodyLarge),
                value: _createNewTransaction,
                onChanged: (bool value) {
                  setState(() {
                    _createNewTransaction = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              if(_createNewTransaction)
                SizedBox(height: 16),

              if(_createNewTransaction)
                TextFormField(
                  controller: _transactionAmountController,
                  decoration: InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  style: textTheme.bodyLarge,
                  validator: (value) {
                    if (value!.isEmpty) return null;
                    if (double.tryParse(value) == null || double.parse(value) < 0) return 'Invalid amount';
                    return null;
                  },
                ),
              
              SizedBox(height: 16),
              if(_createNewTransaction)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text("Begin Date for transaction: ${DateFormat.yMd().format(_selectedTransactionDate)}", style: textTheme.bodyLarge),
                  trailing: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                  onTap: _isSaving ? null : () => {_pickDateTransaction(context)},
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

   Future<void> _pickDateTransaction(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedTransactionDate,
      firstDate: DateTime.now().subtract(Duration(days:1)), // Allow today
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedTransactionDate) {
      setState(() {
        _selectedTransactionDate = picked;
      });
    }
  }
}
