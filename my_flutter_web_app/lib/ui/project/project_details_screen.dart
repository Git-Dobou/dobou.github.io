import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_flutter_web_app/models/project.dart';
import 'package:my_flutter_web_app/models/user.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:my_flutter_web_app/providers/project_notifier.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final Project project;

  const ProjectDetailsScreen({super.key, required this.project});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  late Project project;
  bool showAddUser = false;
  DocumentReference? selectedUserRef;
  List<String> selectedRoles = [];
  List<User> allUsers = [];
  bool isLoadingUsers = true;
  String? inviteLink;
  bool joinRequestPending = false;
  DocumentReference? pendingUserRef;

  ProjectNotifier get notifier => Provider.of<ProjectNotifier>(context, listen: false);

  @override
  void initState() {
    super.initState();
    project = widget.project;
    _fetchAllUsers();
    _checkJoinRequest();
  }

  Future<void> _fetchAllUsers() async {
    final snapshot = await FirebaseFirestore.instance.collection('user').get();
    setState(() {
      allUsers = snapshot.docs.map((doc) => User.fromMap(doc.data(), doc.id)).toList();
      isLoadingUsers = false;
    });
  }

  Future<User?> _getUserObj(DocumentReference? userRef) async {
    if (userRef == null) return null;
    final doc = await userRef.get();
    if (!doc.exists) return null;
    return User.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  // Erweiterung: Prüfe, ob ein Join-Request für dieses Projekt existiert
  Future<void> _checkJoinRequest() async {
    // Hier wird angenommen, dass die aktuelle User-ID verfügbar ist
    // Ersetze dies ggf. mit deinem Auth-System!
    final currentUserId = 'CURRENT_USER_ID'; // TODO: ersetzen!
    final userDoc = await FirebaseFirestore.instance.collection('user').doc(currentUserId).get();
    if (userDoc.exists) {
      final userData = userDoc.data() as Map<String, dynamic>;
      final pendingProjects = List<String>.from(userData['pendingProjects'] ?? []);
      if (pendingProjects.contains(project.id)) {
        setState(() {
          joinRequestPending = true;
          pendingUserRef = userDoc.reference;
        });
      }
    }
  }

  Future<void> _confirmJoinRequest() async {
    if (pendingUserRef == null) return;
    // Entferne das Projekt aus pendingProjects und füge den User zum Projekt hinzu
    final userDoc = await pendingUserRef!.get();
    final userData = userDoc.data() as Map<String, dynamic>;
    List<String> pendingProjects = List<String>.from(userData['pendingProjects'] ?? []);
    pendingProjects.remove(project.id);

    await pendingUserRef!.update({'pendingProjects': pendingProjects});
    setState(() {
      joinRequestPending = false;
    });

    // Füge den User zum Projekt hinzu (nur mit Leserechten als Beispiel)
    setState(() {
      project.users.add(UserWithRole(user: pendingUserRef, rolen: ['r']));
    });
    await FirebaseFirestore.instance.collection('project').doc(project.id).update({
      'users': project.users.map((u) => u.toMap()).toList(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Beitritt bestätigt!')),
    );
  }

  Future<void> _addUserToProject() async {
    if (selectedUserRef == null || selectedRoles.isEmpty) return;

    if (project.users.any((u) => u.user?.id == selectedUserRef?.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Benutzer ist bereits im Projekt')),
      );
      return;
    }

    setState(() {
      project.users.add(UserWithRole(user: selectedUserRef, rolen: selectedRoles));
      showAddUser = false;
      selectedUserRef = null;
      selectedRoles = [];
    });

    await FirebaseFirestore.instance.collection('project').doc(project.id).update({
      'users': project.users.map((u) => u.toMap()).toList(),
    });
  }

  Future<void> _removeUser(int index) async {
    setState(() {
      project.users.removeAt(index);
    });
    await FirebaseFirestore.instance.collection('project').doc(project.id).update({
      'users': project.users.map((u) => u.toMap()).toList(),
    });
  }

  Future<void> _editUserRoles(int index) async {
    final userWithRole = project.users[index];
    List<String> editRoles = List<String>.from(userWithRole.rolen);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rechte bearbeiten'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: Text('Lesen'),
              value: editRoles.contains('r'),
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    editRoles.add('r');
                  } else {
                    editRoles.remove('r');
                  }
                });
              },
            ),
            CheckboxListTile(
              title: Text('Schreiben'),
              value: editRoles.contains('w'),
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    editRoles.add('w');
                  } else {
                    editRoles.remove('w');
                  }
                });
              },
            ),
            CheckboxListTile(
              title: Text('Löschen'),
              value: editRoles.contains('d'),
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    editRoles.add('d');
                  } else {
                    editRoles.remove('d');
                  }
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Abbrechen'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: Text('Speichern'),
            onPressed: () {
              setState(() {
                project.users[index] = UserWithRole(user: userWithRole.user, rolen: editRoles);
              });
              FirebaseFirestore.instance.collection('project').doc(project.id).update({
                'users': project.users.map((u) => u.toMap()).toList(),
              });
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _setAsDefault() async {
  await Provider.of<ProjectNotifier>(context, listen: false).setAsDefault(project);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Projekt als Standard gesetzt')),
    );
    setState(() {}); // Aktualisiere die Ansicht
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Projekt als Standard gesetzt')),
    );
  }

  Future<void> _leaveProject() async {
    // TODO: Implement logic to remove current user from project
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Projekt verlassen')),
    );
    Navigator.of(context).pop();
  }

  Future<void> _generateInviteLink() async {
    setState(() {
      inviteLink = 'https://smartfinanz.app/join?project=${project.id}';
    });
    _showShareDialog();
  }

  void _showShareDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Zum Projekt einladen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Teile diesen Link, damit andere dem Projekt beitreten können:'),
            SizedBox(height: 12),
            SelectableText(inviteLink ?? '', style: TextStyle(color: Colors.blue)),
            SizedBox(height: 12),
            ElevatedButton.icon(
              icon: Icon(Icons.share),
              label: Text('Link teilen'),
              onPressed: () {
                if (inviteLink != null) {
                  Share.share(inviteLink!);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Schließen'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(project.name),
      ),
      body: notifier.isLoading // <--- Ladeanzeige wie in ProjectListScreen
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        project.name,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    _buildDetailRow(context, 'Beschreibung', project.description),
                    _buildDetailRow(context, 'Projekt-ID', project.projectIdentification),
                    _buildDetailRow(context, 'Status', project.active ? 'Aktiv' : 'Inaktiv'),
                    SizedBox(height: 16),
                    Divider(),
                    SizedBox(height: 16),
                    Text('Benutzer', style: textTheme.titleMedium),
                    SizedBox(height: 8),
                    ...project.users.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final userWithRole = entry.value;
                      return FutureBuilder<User?>(
                        future: _getUserObj(userWithRole.user),
                        builder: (context, snapshot) {
                          final userObj = snapshot.data;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text(userObj?.name ?? 'Unbekannter Benutzer'),
                              subtitle: Text(_rolesText(userWithRole.rolen)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blue),
                                    tooltip: 'Rechte bearbeiten',
                                    onPressed: () => _editUserRoles(idx),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _removeUser(idx),
                                    tooltip: 'Benutzer entfernen',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }),
                    SizedBox(height: 12),
                    if (showAddUser)
                      Card(
                        color: Colors.grey[100],
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              isLoadingUsers
                                  ? Center(child: CircularProgressIndicator())
                                  : DropdownButtonFormField<DocumentReference>(
                                      value: selectedUserRef,
                                      items: allUsers.map((user) {
                                        return DropdownMenuItem(
                                          value: FirebaseFirestore.instance.collection('user').doc(user.id),
                                          child: Text('${user.name} (${user.identification})'),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          selectedUserRef = val;
                                        });
                                      },
                                      decoration: InputDecoration(labelText: 'Benutzer auswählen'),
                                    ),
                              SizedBox(height: 8),
                              CheckboxListTile(
                                title: Text('Lesen'),
                                value: selectedRoles.contains('r'),
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      selectedRoles.add('r');
                                    } else {
                                      selectedRoles.remove('r');
                                    }
                                  });
                                },
                              ),
                              CheckboxListTile(
                                title: Text('Schreiben'),
                                value: selectedRoles.contains('w'),
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      selectedRoles.add('w');
                                    } else {
                                      selectedRoles.remove('w');
                                    }
                                  });
                                },
                              ),
                              CheckboxListTile(
                                title: Text('Löschen'),
                                value: selectedRoles.contains('d'),
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      selectedRoles.add('d');
                                    } else {
                                      selectedRoles.remove('d');
                                    }
                                  });
                                },
                              ),
                              SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon: Icon(Icons.person_add),
                                      label: Text('Benutzer hinzufügen'),
                                      onPressed: _addUserToProject,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton(
                                      child: Text('Abbrechen'),
                                      onPressed: () {
                                        setState(() {
                                          showAddUser = false;
                                          selectedUserRef = null;
                                          selectedRoles = [];
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (!showAddUser)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.person_add),
                          label: Text('Benutzer hinzufügen'),
                          onPressed: () => setState(() => showAddUser = true),
                        ),
                      ),
                    if (joinRequestPending)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Card(
                          color: Colors.yellow[100],
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              children: [
                                Text(
                                  'Deine Beitrittsanfrage für dieses Projekt ist noch ausstehend.',
                                  style: textTheme.bodyLarge,
                                ),
                                SizedBox(height: 8),
                                ElevatedButton.icon(
                                  icon: Icon(Icons.check),
                                  label: Text('Beitritt bestätigen'),
                                  onPressed: _confirmJoinRequest,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.star),
                    label: Text('Set as default'),
                    onPressed: _setAsDefault,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.exit_to_app),
                    label: Text('Projekt verlassen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: _leaveProject,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ElevatedButton.icon(
              icon: Icon(Icons.link),
              label: Text('Zum Projekt einladen'),
              onPressed: _generateInviteLink,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Text('$label:', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          SizedBox(width: 8),
          Expanded(child: Text(value, style: textTheme.bodyLarge)),
        ],
      ),
    );
  }

  String _rolesText(List<String> roles) {
    final map = {
      'r': 'Lesen',
      'w': 'Schreiben',
      'd': 'Löschen',
    };
    return roles.map((r) => map[r] ?? r).join(', ');
  }
}