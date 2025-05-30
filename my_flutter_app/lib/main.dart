import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Ensure Flutter SDK path is correctly set for the execution environment if needed
// export PATH="/tmp/flutter/bin:/tmp/flutter/bin:/tmp/flutter/bin:/tmp/flutter/bin:/tmp/flutter/bin:/tmp/flutter/bin:/tmp/flutter/bin:/tmp/flutter/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:/app/flutter/bin:/tmp/flutter/bin:/tmp/flutter/bin:/tmp/flutter/bin" 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Note: Firebase.initializeApp() should ideally be configured with FirebaseOptions
  // if you are not using flutterfire_cli to generate a firebase_options.dart file.
  // For this setup, since google-services.json and GoogleService-Info.plist are manually placed,
  // this default initializeApp() should pick them up.
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Firebase Auth Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Firebase Anonymous Auth'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _uid = "Not signed in";
  String _errorMessage = "";

  Future<void> _signInAnonymously() async {
    setState(() {
      _uid = "Signing in...";
      _errorMessage = "";
    });
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInAnonymously();
      setState(() {
        _uid = userCredential.user?.uid ?? "Signed in, but UID is null";
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _uid = "Sign-in failed";
        switch (e.code) {
          case "operation-not-allowed":
            _errorMessage = "Anonymous sign-in not enabled in Firebase console.";
            break;
          default:
            _errorMessage = "Firebase Auth Error: ${e.message} (Code: ${e.code})";
        }
      });
      print("Firebase Auth Error: ${e.message}");
    } catch (e) {
      setState(() {
        _uid = "Sign-in failed";
        _errorMessage = "An unexpected error occurred: ${e.toString()}";
      });
      print("Unexpected Error: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'User ID:',
            ),
            Text(
              _uid,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signInAnonymously,
              child: const Text('Sign In Anonymously'),
            ),
          ],
        ),
      ),
    );
  }
}
