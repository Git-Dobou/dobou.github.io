import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_notifier.dart';
import '../../providers/category_notifier.dart';
import '../../models/category.dart' as model;
import './add_edit_category_dialog.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({Key? key}) : super(key: key);

  @override
  _CategoryListScreenState createState() =>
      _CategoryListScreenState();

}

class _CategoryListScreenState extends State<CategoryListScreen> {
  String searchText = '';

  @override
  Widget build(BuildContext context) {
    final authNotifier = Provider.of<AuthNotifier>(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    if (authNotifier.user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Categories')),
        body: Center(child: Text('Please log in to view categories.', style: textTheme.titleMedium)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Manage Categories')),
      body: Consumer<CategoryNotifier>(
        builder: (context, categoryNotifier, child) {
          if (categoryNotifier.isLoading && categoryNotifier.categories.isEmpty) {
            return Center(child: CircularProgressIndicator());
          }

          final filteredCategories = categoryNotifier.categories
              .where((category) =>
                  category.name.toLowerCase().contains(searchText.toLowerCase()) ||
                  category.icon.toLowerCase().contains(searchText.toLowerCase()))
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Search categories',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (val) => setState(() => searchText = val),
                ),
              ),
              if (filteredCategories.isEmpty)
                Expanded(
                  child: Center(
                    child: Text('No matching categories found.', style: textTheme.titleMedium),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredCategories.length,
                    itemBuilder: (context, index) {
                      final category = filteredCategories[index];
                      IconData categoryIcon = Icons.label_outline;

                      return Card(
                        child: ListTile(
                          leading: Icon(categoryIcon, size: 30),
                          title: Text(category.name, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          subtitle: Text(category.icon, style: textTheme.bodySmall),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit),
                                tooltip: 'Edit Category',
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AddEditCategoryDialog(category: category,),
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: colorScheme.error),
                                tooltip: 'Delete Category',
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext ctx) {
                                      return AlertDialog(
                                        title: Text('Confirm Delete', style: textTheme.titleLarge),
                                        content: Text('Are you sure you want to delete "${category.name}"?', style: textTheme.bodyLarge),
                                        actions: <Widget>[
                                          TextButton(
                                            child: Text('Cancel'),
                                            onPressed: () => Navigator.of(ctx).pop(),
                                          ),
                                          TextButton(
                                            child: Text('Delete', style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold)),
                                            onPressed: () {
                                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                                              categoryNotifier.deleteCategory(category.id!).then((_){
                                                scaffoldMessenger.showSnackBar(
                                                  SnackBar(content: Text('"${category.name}" deleted successfully'), backgroundColor: Colors.green),
                                                );
                                              }).catchError((error){
                                                scaffoldMessenger.showSnackBar(
                                                  SnackBar(content: Text('Error deleting category: $error'), backgroundColor: Colors.redAccent),
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
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
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
