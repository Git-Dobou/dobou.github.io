import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:my_flutter_web_app/ui/base/auth_screen.dart';
import 'package:provider/provider.dart';

import 'package:my_flutter_web_app/providers/auth_notifier.dart';
import 'package:my_flutter_web_app/providers/settings_notifier.dart';
import 'package:my_flutter_web_app/providers/category_notifier.dart';
import 'package:my_flutter_web_app/providers/transaction_notifier.dart';
import 'package:my_flutter_web_app/providers/debt_notifier.dart';
import 'package:my_flutter_web_app/ui/main_screen.dart';
import 'package:my_flutter_web_app/services/notification_service.dart'; // Import NotificationService

const firebaseOptions = FirebaseOptions(
  apiKey: "AIzaSyDEPT13fx0W3T37qA2eHeNc2NEW3lqU-Jc", // Replace with your actual API key
  authDomain: "finanzapp-f00d3.firebaseapp.com",
  databaseURL: "https://finanzapp-f00d3-default-rtdb.europe-west1.firebasedatabase.app",
  projectId: "finanzapp-f00d3",
  storageBucket: "finanzapp-f00d3.appspot.com",
  messagingSenderId: "426971336067",
  appId: "1:426971336067:web:7794a7f9acfa4636d9bab6",
  measurementId: "G-T1RL61V47C",
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseOptions);
  await NotificationService().init(); // Initialize NotificationService

  await FirebaseFirestore.instance.clearPersistence();
  // await FirebaseFirestore.instance.terminate();
  // await FirebaseFirestore.instance.enablePersistence(); // Optional
  
  DebtNotifier debtNotifier = DebtNotifier();
  TransactionNotifier transactionNotifier = TransactionNotifier(debtNotifier: debtNotifier);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthNotifier()),
        ChangeNotifierProvider(create: (_) => SettingsNotifier()),
        ChangeNotifierProvider(create: (_) => CategoryNotifier()),
        ChangeNotifierProvider(create: (_) => debtNotifier),
        ChangeNotifierProvider(create: (_) => transactionNotifier),
      ],
      child: MyApp(),
    ),
  );
}

// Define base ColorSchemes (assuming these are defined as in previous tasks)
const ColorScheme lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Colors.blue, 
  onPrimary: Colors.white, 
  secondary: Colors.amber, 
  onSecondary: Colors.black,
  error: Colors.red,
  onError: Colors.white,
  background: Colors.white, 
  onBackground: Colors.black, 
  surface: Colors.white, 
  onSurface: Colors.black, 
);

const ColorScheme darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Colors.blueGrey, 
  onPrimary: Colors.white,
  secondary: Colors.tealAccent, 
  onSecondary: Colors.black,
  error: Colors.redAccent,
  onError: Colors.white,
  background: Color(0xFF121212), 
  onBackground: Colors.white,
  surface: Color(0xFF1E1E1E), 
  onSurface: Colors.white,
);

ThemeData _buildTheme(ColorScheme colorScheme) {
  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true, 
    fontFamily: 'Verdana',
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary, 
      elevation: 4.0,
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onPrimary),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.secondary,
      foregroundColor: colorScheme.onSecondary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary, 
      ),
    ),
    cardTheme: CardTheme(
      elevation: 10.0,
      shadowColor: Colors.black.withOpacity(0.6), // wichtig für Dark Mode
      margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: colorScheme.primary, 
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
      ),
      labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
      backgroundColor: colorScheme.surface, 
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
          if (states.contains(MaterialState.selected)) {
            return colorScheme.primary.withOpacity(0.2); 
          }
          return null; 
        }),
        foregroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
            return colorScheme.onSurface; 
        }),
        side: MaterialStateProperty.all(BorderSide(color: colorScheme.primary.withOpacity(0.5))),
      ),
    ),
    scaffoldBackgroundColor: colorScheme.background,
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settingsNotifier = Provider.of<SettingsNotifier>(context);

    return MaterialApp(
      title: settingsNotifier.appName,
      themeMode: settingsNotifier.themeMode,
      theme: _buildTheme(lightColorScheme),
      darkTheme: _buildTheme(darkColorScheme),
      home: AuthScreen(),
    );
  }
}

class AuthPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authNotifier = Provider.of<AuthNotifier>(context);
    final settingsNotifier = Provider.of<SettingsNotifier>(context, listen: false);

    if (authNotifier.user != null) {
      return MainScreen();
    } else {
      return Scaffold(
        appBar: AppBar(title: Text('Login to ${settingsNotifier.appName}')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(authNotifier.message),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => authNotifier.signInAnonymously(),
                child: AuthScreen(),
              )
            ],
          ),
        ),
      );
    }
  }
}
