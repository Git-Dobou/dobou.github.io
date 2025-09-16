import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_notifier.dart';
import '../providers/project_notifier.dart';
import './project/project_list_screen.dart';
import './transactions/transaction_list_screen.dart';
import './debts/debt_list_screen.dart';
import './economize/economize_list_screen.dart';
import './settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static List<Widget> _widgetOptions = <Widget>[
    HomePageWithUserAndProjects(),
    TransactionListScreen(),
    const DebtListScreen(),
    const EconomizeListScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card),
            label: 'Debts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.savings),
            label: 'Savings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class HomePageWithUserAndProjects extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthNotifier>(context).user;
    final projectNotifier = Provider.of<ProjectNotifier>(context);
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      child: Column(
        children: [
          Card(
            margin: EdgeInsets.all(16),
            child: ListTile(
              leading: Icon(Icons.account_circle, size: 40, color: Theme.of(context).colorScheme.primary),
              title: Text(user?.displayName ?? user?.email ?? 'Kein Benutzer', style: textTheme.titleMedium),
              subtitle: Text(user?.email ?? '', style: textTheme.bodyMedium),
              trailing: Icon(Icons.verified_user, color: Colors.green),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Willkommen bei Smart Finanz!\n\nHier findest du alle deine Projekte und kannst deine Finanzen einfach verwalten. Wähle ein Projekt aus oder erstelle ein neues!',
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Deine Projekte',
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 400,
            child: ProjectListScreen(),
          ),
        ],
      ),
    );
  }
}
