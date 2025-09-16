import 'package:flutter/material.dart';

class JoinProjectScreen extends StatefulWidget {
  const JoinProjectScreen({super.key});

  @override
  State<JoinProjectScreen> createState() => _JoinProjectScreenState();
}

class _JoinProjectScreenState extends State<JoinProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _projectCodeController = TextEditingController();

  void _joinProject() {
    if (_formKey.currentState?.validate() ?? false) {
      // TODO: Implement join logic
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Beitrittsanfrage für Projektcode "${_projectCodeController.text}" gesendet')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Projekt beitreten')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _projectCodeController,
                decoration: InputDecoration(labelText: 'Projektcode'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Bitte Projektcode eingeben' : null,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _joinProject,
                child: Text('Beitreten'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
