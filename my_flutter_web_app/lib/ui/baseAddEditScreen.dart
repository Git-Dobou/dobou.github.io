import 'package:flutter/material.dart';
import 'package:my_flutter_web_app/models/debt.dart' as model_debt;
import 'package:my_flutter_web_app/providers/debt_notifier.dart';

abstract class BaseAddEditScreen<T> extends StatefulWidget {
  final T? itemToEdit;
  final Future<void> Function(T item, BuildContext context) onSave;
  final String titleAdd;
  final String titleEdit;

  const BaseAddEditScreen({
    super.key,
    required this.itemToEdit,
    required this.onSave,
    required this.titleAdd,
    required this.titleEdit,
  });

  /// Muss von der Kindklasse überschrieben werden
  Widget buildForm(BuildContext context, T? itemToEdit);

  /// Muss ein neues Objekt zurückgeben oder die Änderungen enthalten
  T buildItem();
}

class _BaseAddEditScreenState<T> extends State<BaseAddEditScreen<T>> {
  bool isSaving = false;

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.itemToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? widget.titleEdit : widget.titleAdd),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            tooltip: 'Speichern',
            onPressed: isSaving ? null : _handleSave,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: widget.buildForm(context, widget.itemToEdit),
      ),
    );
  }

  Future<void> _handleSave() async {
    try {
      setState(() => isSaving = true);
      final item = widget.buildItem();
      await widget.onSave(item, context);
      Navigator.of(context).pop(); // zurück nach dem Speichern
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Speichern: $e')),
      );
    } finally {
      setState(() => isSaving = false);
    }
  }
}

class AddEditDebtScreen1 extends BaseAddEditScreen<model_debt.Debt> {
  final DebtNotifier notifier;

  AddEditDebtScreen1({super.key, model_debt.Debt? debtToEdit, required this.notifier})
      : super(
          itemToEdit: debtToEdit,
          onSave: (debt, context) => notifier.addDebt(debt),
          titleAdd: 'Neue Schuld hinzufügen',
          titleEdit: 'Schuld bearbeiten',
        );

  final TextEditingController creditorController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  @override
  Widget buildForm(BuildContext context, model_debt.Debt? itemToEdit) {
    if (itemToEdit != null) {
      creditorController.text = itemToEdit.creditor;
      amountController.text = itemToEdit.amount.toString();
    }

    return Column(
      children: [
        TextField(
          controller: creditorController,
          decoration: InputDecoration(labelText: 'Gläubiger'),
        ),
        TextField(
          controller: amountController,
          decoration: InputDecoration(labelText: 'Betrag'),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  @override
  model_debt.Debt buildItem() {
    return model_debt.Debt(
      creditor: creditorController.text,
      amount: double.tryParse(amountController.text) ?? 0.0,
      id: itemToEdit?.id, paymentMode: '', paymentMethod: '', paymentAmount: 0, firstPaymentDate: DateTime.now(), dueDate: DateTime.now(), comment: '', currency: '',
      // weitere Felder ergänzen
    );
  }
  
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    throw UnimplementedError();
  }
}
