import 'package:flutter/material.dart';

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
