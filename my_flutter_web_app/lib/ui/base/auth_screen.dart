import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_flutter_web_app/providers/auth_notifier.dart';
import 'package:my_flutter_web_app/ui/main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  bool _rememberMe = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  void _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('email');
    final savedPassword = prefs.getString('password');
    if (savedEmail != null && savedPassword != null) {
      _emailController.text = savedEmail;
      _passwordController.text = savedPassword;
      setState(() => _rememberMe = true);
    }
  }

  Future<void> _authenticate() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
        await FirebaseAuth.instance.currentUser?.updateDisplayName(_usernameController.text.trim());
      }

      if (_rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('email', email);
        await prefs.setString('password', password);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: ${e.toString()}')));
    }
  }

  void _showPasswordResetDialog() {
    final TextEditingController _resetEmailController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Passwort zurücksetzen'),
        content: TextField(
          controller: _resetEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(labelText: 'E-Mail-Adresse'),
        ),
        actions: [
          TextButton(child: Text('Abbrechen'), onPressed: () => Navigator.of(context).pop()),
          ElevatedButton(
            child: Text('Zurücksetzen'),
            onPressed: () async {
              final email = _resetEmailController.text.trim();
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Reset-Mail gesendet'), backgroundColor: Colors.green),
                );
              } catch (e) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

     if (AuthNotifier.instance.user != null) {
      return MainScreen();
    } else {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Login' : 'Registrieren')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (!_isLogin)
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(labelText: 'Benutzername'),
                ),

                              const SizedBox(height: 8),

              if (!_isLogin)
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: 'Telefonnummer'),
                  keyboardType: TextInputType.phone,
                ),

                              const SizedBox(height: 8),

              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'E-Mail'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.contains('@') ? null : 'Ungültige E-Mail',
              ),

                            const SizedBox(height: 8),

              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Passwort'),
                obscureText: true,
                validator: (value) => value!.length >= 6 ? null : 'Mind. 6 Zeichen',
              ),

                            const SizedBox(height: 8),

              Row(
                children: [
                  Checkbox(value: _rememberMe, onChanged: (val) => setState(() => _rememberMe = val!)),
                  Text('Zugangsdaten merken')
                ],
              ),
              TextButton(
                onPressed: _showPasswordResetDialog,
                child: Text('Passwort vergessen?'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _authenticate,
                child: Text(_isLogin ? 'Einloggen' : 'Registrieren'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(_isLogin ? 'Noch kein Konto? Registrieren' : 'Bereits registriert? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
}