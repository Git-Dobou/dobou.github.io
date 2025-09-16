import 'package:flutter/material.dart';
import 'package:my_flutter_web_app/ui/categories/category_list_screen.dart';
import 'package:my_flutter_web_app/ui/project/project_list_screen.dart';
import 'package:provider/provider.dart';
import '../providers/settings_notifier.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _appNameController;
  // Key for the ScaffoldMessenger to show SnackBars
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    final settingsNotifier = Provider.of<SettingsNotifier>(context, listen: false);
    _appNameController = TextEditingController(text: settingsNotifier.appName);
    settingsNotifier.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() {
    final settingsNotifier = Provider.of<SettingsNotifier>(context, listen: false);
    if (mounted && _appNameController.text != settingsNotifier.appName) {
      _appNameController.text = settingsNotifier.appName;
    }
    // For theme and currency changes, the UI rebuilds and reflects them automatically.
    // A SnackBar could be shown here too if explicit confirmation is desired for all changes.
    // For example, after settingsNotifier.setTheme() is called and finishes:
    // _scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(content: Text('Theme updated!')));
  }

  @override
  void dispose() {
    Provider.of<SettingsNotifier>(context, listen: false).removeListener(_onSettingsChanged);
    _appNameController.dispose();
    super.dispose();
  }

  void _saveAppName() {
    final settingsNotifier = Provider.of<SettingsNotifier>(context, listen: false);
    if (_appNameController.text.trim().isEmpty) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('App Name cannot be empty'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    settingsNotifier.setAppName(_appNameController.text.trim()).then((_) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('App Name saved successfully!'), backgroundColor: Colors.green),
      );
    }).catchError((error) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Error saving App Name: $error'), backgroundColor: Colors.redAccent),
      );
    });
    FocusScope.of(context).unfocus();
  }

    void _setFont(String? newFont) {
    
  }


  void _setCurrency(String? newCurrency) {
    if (newCurrency != null) {
      final settingsNotifier = Provider.of<SettingsNotifier>(context, listen: false);
      settingsNotifier.setCurrency(newCurrency).then((_) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Currency updated to $newCurrency'), backgroundColor: Colors.green),
        );
      }).catchError((error) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Error updating currency: $error'), backgroundColor: Colors.redAccent),
        );
      });
    }
  }
  
  void _setTheme(ThemeMode newThemeMode) {
      final settingsNotifier = Provider.of<SettingsNotifier>(context, listen: false);
      settingsNotifier.setTheme(newThemeMode).then((_) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Theme updated'), backgroundColor: Colors.green),
        );
      }).catchError((error) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Error updating theme: $error'), backgroundColor: Colors.redAccent),
        );
      });
  }

  @override
  Widget build(BuildContext context) {
    final settingsNotifier = Provider.of<SettingsNotifier>(context);
    final textTheme = Theme.of(context).textTheme;
    // InputDecoratorTheme is applied globally from main.dart

    return Scaffold(
      key: _scaffoldMessengerKey, // Assign key to Scaffold
      appBar: AppBar( // AppBarTheme from main.dart will apply
        title: Text('Settings'),
      ),
      body: settingsNotifier.isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: <Widget>[
                  Text('Theme', style: textTheme.titleLarge),
                  SizedBox(height: 8),
                  SegmentedButton<ThemeMode>( // SegmentedButtonTheme from main.dart will apply
                    segments: const <ButtonSegment<ThemeMode>>[
                      ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode)),
                      ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto)),
                      ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode)),
                    ],
                    selected: <ThemeMode>{settingsNotifier.themeMode},
                    onSelectionChanged: (Set<ThemeMode> newSelection) {
                      _setTheme(newSelection.first);
                    },
                  ),
                  SizedBox(height: 24),
                  Text('App Name', style: textTheme.titleLarge),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _appNameController,
                    decoration: InputDecoration(hintText: 'Enter App Name'),
                    style: textTheme.bodyLarge,
                    // onSubmitted: (value) => _saveAppName(), // Optional: save on submit
                  ),
                  SizedBox(height: 8),
                  ElevatedButton( // ElevatedButtonTheme from main.dart will apply
                    onPressed: _saveAppName,
                    child: Text('Save App Name'),
                  ),
                  SizedBox(height: 24),
                  Text('Currency', style: textTheme.titleLarge),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: settingsNotifier.currency,
                    items: ['EUR', 'USD', 'GBP'].map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value, style: textTheme.bodyLarge));
                    }).toList(),
                    onChanged: _setCurrency,
                    decoration: InputDecoration(), // Will pick up global theme
                  ),
                  
                  SizedBox(height: 24),
                  Text('Font', style: textTheme.titleLarge),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: settingsNotifier.font,
                    items: ['Arial', 'Fortana', 'Verdana'].map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value, style: textTheme.bodyLarge));
                    }).toList(),
                    onChanged: _setFont,
                    decoration: InputDecoration(), // Will pick up global theme
                  ),
                  SizedBox(height: 30),
                  Card(
                    child: ListTile(
                      title: const Text('Manage categories'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CategoryListScreen(),
                          ),
                        );
                      },
                      trailing: Icon(Icons.arrow_right),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      title: const Text('Manage Projects'),
                      onTap: () {
                        // TODO: Replace with your ProjectListScreen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProjectListScreen(),
                          ),
                        );
                      },
                      trailing: Icon(Icons.arrow_right),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
