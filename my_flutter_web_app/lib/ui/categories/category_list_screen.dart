import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_notifier.dart';
import '../../providers/category_notifier.dart';
import '../../models/category.dart' as model;
import './add_edit_category_dialog.dart';

class CategoryListScreen extends StatelessWidget {
  const CategoryListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authNotifier = Provider.of<AuthNotifier>(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    if (authNotifier.user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Categories')), // Themed by main.dart
        body: Center(child: Text('Please log in to view categories.', style: textTheme.titleMedium)),
      );
    }

    return Scaffold(
      appBar: AppBar( // Themed by main.dart
        title: Text('Manage Categories'),
      ),
      body: Consumer<CategoryNotifier>(
        builder: (context, categoryNotifier, child) {
          if (categoryNotifier.isLoading && categoryNotifier.categories.isEmpty) {
            return Center(child: CircularProgressIndicator());
          }

          if (categoryNotifier.categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined, size: 80, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text('No categories found.', style: textTheme.titleMedium),
                  SizedBox(height: 8),
                  Text('Tap the "+" button to add your first category.', style: textTheme.bodyMedium, textAlign: TextAlign.center),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: categoryNotifier.categories.length,
            itemBuilder: (context, index) {
              final category = categoryNotifier.categories[index];
              // TODO: Use a more meaningful icon based on category.icon string or a default one
              IconData categoryIcon = Icons.label_outline; // Default icon
              // Example: if (category.icon == "work") categoryIcon = Icons.work;
              // This requires a mapping or a more structured way to handle icons.

              return Card( // Themed by main.dart
                child: ListTile( // Themed by main.dart
                  leading: Icon(categoryIcon, size: 30), // Will use ListTileTheme iconColor
                  title: Text(category.name, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  subtitle: Text(category.icon, style: textTheme.bodySmall), // Displaying icon string for now
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit), // Will use ListTileTheme iconColor or fallback
                        tooltip: 'Edit Category',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => AddEditCategoryDialog(category: category),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: colorScheme.error), // Explicit error color
                        tooltip: 'Delete Category',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext ctx) {
                              return AlertDialog(
                                title: Text('Confirm Delete', style: textTheme.titleLarge),
                                content: Text('Are you sure you want to delete "\${category.name}"?', style: textTheme.bodyLarge),
                                actions: <Widget>[
                                  TextButton(
                                    child: Text('Cancel'),
                                    onPressed: () => Navigator.of(ctx).pop(),
                                  ),
                                  TextButton(
                                    child: Text('Delete', style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold)),
                                    onPressed: () {
                                      final scaffoldMessenger = ScaffoldMessenger.of(context); // Capture before async gap
                                      categoryNotifier.deleteCategory(category.id!).then((_){
                                        scaffoldMessenger.showSnackBar(
                                          SnackBar(content: Text('"\${category.name}" deleted successfully'), backgroundColor: Colors.green),
                                        );
                                      }).catchError((error){
                                        scaffoldMessenger.showSnackBar(
                                          SnackBar(content: Text('Error deleting category: \$error'), backgroundColor: Colors.redAccent),
                                        );
                                      });
                                      Navigator.of(ctx).pop();
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton( // Themed by main.dart
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AddEditCategoryDialog(), 
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Add Category',
      ),
    );
  }
}
