import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/category_notifier.dart';
import '../../models/category.dart' as model;

class AddEditCategoryDialog extends StatefulWidget {
  final model.Category? category; 

  const AddEditCategoryDialog({Key? key, this.category}) : super(key: key);

  @override
  _AddEditCategoryDialogState createState() => _AddEditCategoryDialogState();
}

class _AddEditCategoryDialogState extends State<AddEditCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _iconController; 

  bool get _isEditing => widget.category != null;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _iconController = TextEditingController(text: widget.category?.icon ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isSaving = true; });
      final categoryNotifier = Provider.of<CategoryNotifier>(context, listen: false);
      final scaffoldMessenger = ScaffoldMessenger.of(context); // Capture context
      final navigator = Navigator.of(context); // Capture context for pop

      final name = _nameController.text.trim();
      final icon = _iconController.text.trim();

      try {
        if (_isEditing) {
          await categoryNotifier.updateCategory(widget.category!.id!, name, icon);
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Category "\$name" updated successfully!'), backgroundColor: Colors.green),
          );
        } else {
          await categoryNotifier.addCategory(name, icon);
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Category "\$name" added successfully!'), backgroundColor: Colors.green),
          );
        }
        navigator.pop(); // Close the dialog on success
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error: \$e'), backgroundColor: Colors.redAccent),
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
    // AlertDialog, TextFormField, ElevatedButton will be styled by global themes

    return AlertDialog(
      title: Text(_isEditing ? 'Edit Category' : 'Add Category', style: textTheme.titleLarge),
      contentPadding: const EdgeInsets.all(20.0),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Category Name'),
              style: textTheme.bodyLarge,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a category name';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _iconController,
              decoration: InputDecoration(labelText: 'Icon Name/Code (e.g., work, home)'),
              style: textTheme.bodyLarge,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an icon name/code';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      actions: <Widget>[
        TextButton(
          child: Text('Cancel'),
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submitForm,
          child: _isSaving ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary)) : Text(_isEditing ? 'Save Changes' : 'Add Category'),
        ),
      ],
    );
  }
}
