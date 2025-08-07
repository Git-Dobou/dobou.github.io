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
        var category = model.Category(id: widget.category?.id ?? '', name: name, icon: icon);
        if (_isEditing) {
          await categoryNotifier.updateCategory(category);
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Category "$name" updated successfully!'), backgroundColor: Colors.green),
          );
        } else {
          await categoryNotifier.addCategory(category);
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Category "$name" added successfully!'), backgroundColor: Colors.green),
          );
        }
        navigator.pop(); // Close the dialog on success
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
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
            SelectNewCategoryView()
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

class SelectNewCategoryView extends StatefulWidget {
  const SelectNewCategoryView({super.key});

  @override
  State<SelectNewCategoryView> createState() => _SelectNewCategoryViewState();
}

class _SelectNewCategoryViewState extends State<SelectNewCategoryView> {
  final List<String> _icons = [
    'add',
    'home',
    'wallet',
    'shopping_cart',
    'restaurant',
    'school',
    'fitness_center',
    'flight',
    'directions_car',
    'healing',
    'local_movies',
    'pets',
    'sports_soccer',
  ];

  final Map<String, IconData> iconsMap = {
    'add': Icons.add,
    'home': Icons.home,
    'wallet': Icons.account_balance_wallet,
    'shopping_cart': Icons.shopping_cart,
    'restaurant': Icons.restaurant,
    'school': Icons.school,
    'fitness_center': Icons.fitness_center,
    'flight': Icons.flight,
    'directions_car': Icons.directions_car,
    'healing': Icons.healing,
    'local_movies': Icons.local_movies,
    'pets': Icons.pets,
    'sports_soccer': Icons.sports_soccer,
  };

  String? _selectedIconName;

  void _showIconDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wähle ein Symbol'),
        content: SizedBox(
          height: 200, // 🔥 WICHTIG: Höhe definieren
          width: double.maxFinite,
          child: GridView.builder(
            itemCount: _icons.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final iconName = _icons[index];
              final isSelected = iconName == _selectedIconName;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIconName = iconName;
                  });
                  Navigator.of(context).pop();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.shade100 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    iconsMap[iconName],
                    color: isSelected ? Colors.blue : Colors.black54,
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategorie wählen'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_selectedIconName != null)
              Icon(
                iconsMap[_selectedIconName]!,
                size: 48,
                color: Colors.blue,
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showIconDialog,
              child: const Text('Symbol auswählen'),
            ),
          ],
        ),
      ),
    );
  }
}
