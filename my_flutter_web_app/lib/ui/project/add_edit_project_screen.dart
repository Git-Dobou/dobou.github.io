import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_flutter_web_app/models/project.dart';

class AddEditProjectScreen extends StatefulWidget {
  final Project? projectToEdit;

  const AddEditProjectScreen({super.key, this.projectToEdit});

  @override
  State<AddEditProjectScreen> createState() => _AddEditProjectScreenState();
}

class _AddEditProjectScreenState extends State<AddEditProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.projectToEdit?.name ?? '');
    _descriptionController = TextEditingController(text: widget.projectToEdit?.description ?? '');
    _active = widget.projectToEdit?.active ?? true;
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    final data = {
      'name': name,
      'description': description,
      'active': _active,
      'projectIdentification': widget.projectToEdit?.projectIdentification ?? '',
      'debtTabVisible': widget.projectToEdit?.debtTabVisible ?? false,
      'economizeTabVisible': widget.projectToEdit?.economizeTabVisible ?? false,
      'transactionWithMonth': widget.projectToEdit?.transactionWithMonth ?? false,
      'users': widget.projectToEdit?.users.map((u) => u.toMap()).toList() ?? [],
      'owner': widget.projectToEdit?.owner,
      'clientId': widget.projectToEdit?.clientId ?? '',
      'creationTime': widget.projectToEdit?.creationTime ?? DateTime.now(),
      'lastUpdateTime': DateTime.now(),
    };

    final projectsRef = FirebaseFirestore.instance.collection('project');
    if (widget.projectToEdit == null) {
      await projectsRef.add(data);
    } else {
      await projectsRef.doc(widget.projectToEdit!.id).update(data);
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.projectToEdit != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Projekt bearbeiten' : 'Projekt hinzufügen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Projektname'),
                validator: (value) => value == null || value.isEmpty ? 'Bitte Namen eingeben' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Beschreibung'),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              SwitchListTile(
                title: Text('Aktiv'),
                value: _active,
                onChanged: (val) => setState(() => _active = val),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveProject,
                child: Text(isEdit ? 'Speichern' : 'Hinzufügen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}