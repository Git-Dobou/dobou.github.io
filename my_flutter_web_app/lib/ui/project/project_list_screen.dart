import 'package:provider/provider.dart';
import '../../providers/project_notifier.dart';
import 'package:flutter/material.dart';
import 'add_edit_project_screen.dart';
import 'join_project_screen.dart';
import 'project_details_screen.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
      Provider.of<ProjectNotifier>(context, listen: false).fetchProjects()
    );
  }

  Future<void> _openAddEditProject([project]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditProjectScreen(projectToEdit: project),
      ),
    );
    if (result == true) {
      Provider.of<ProjectNotifier>(context, listen: false).fetchProjects();
    }
  }

  Future<void> _openJoinProject() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JoinProjectScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Consumer<ProjectNotifier>(
      builder: (context, vm, child) {
        return Scaffold(
          // appBar: AppBar(
          //   // title: Text('Projekte'),
          //   actions: [
          //     IconButton(
          //       icon: Icon(Icons.add),
          //       tooltip: 'Projekt hinzufügen',
          //       onPressed: () => _openAddEditProject(),
          //     ),
          //   ],
          // ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Projekt suchen',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: (val) => vm.setSearchText(val),
                      ),
                    ),
                    SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: Icon(Icons.group_add),
                      label: Text('Projekt beitreten'),
                      onPressed: _openJoinProject,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
              if (vm.filteredProjects.any((p) => p.active))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Aktives Projekt: ${vm.filteredProjects.firstWhere((p) => p.active, orElse: () => vm.filteredProjects.first).name}',
                    style: textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Expanded(
                child: vm.isLoading
                    ? Center(child: CircularProgressIndicator())
                    : vm.filteredProjects.isEmpty
                        ? Center(child: Text('Keine Projekte gefunden.', style: textTheme.titleMedium))
                        : ListView.builder(
                            itemCount: vm.filteredProjects.length,
                            itemBuilder: (context, index) {
                              final project = vm.filteredProjects[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: ListTile(
                                  title: Text(project.name, style: textTheme.titleMedium),
                                  subtitle: Text(project.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit),
                                        onPressed: () => _openAddEditProject(project),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete, color: Colors.red),
                                        onPressed: () async {
                                          await Provider.of<ProjectNotifier>(context, listen: false).deleteProject(project);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Projekt "${project.name}" gelöscht')),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProjectDetailsScreen(project: project),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _openAddEditProject(),
            child: Icon(Icons.add),
            tooltip: 'Projekt hinzufügen',
          ),
        );
      },
    );
  }
}
