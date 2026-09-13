import 'package:flutter/material.dart';

class WorkspaceReadyPage extends StatelessWidget {
  final List<String> categories;
  final Map<String, List<String>> workspaces;
  final Future<void> Function(List<String>) onComplete;

  const WorkspaceReadyPage({
    super.key,
    required this.categories,
    required this.workspaces,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workspace Ready')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Your Workspace is Ready!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Categories ke andar unke relevant folders rakhe gaye hain.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Expanded(
                child: ListView.separated(
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final folders = workspaces[category] ?? const <String>[];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: ExpansionTile(
                        initiallyExpanded: index == 0,
                        leading: const Icon(Icons.workspaces_outlined),
                        title: Text(
                          category,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        children: folders
                            .map(
                              (folder) => ListTile(
                                dense: true,
                                contentPadding:
                                    const EdgeInsets.only(left: 58, right: 16),
                                leading: const Icon(Icons.folder_outlined),
                                title: Text(folder),
                              ),
                            )
                            .toList(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: () async {
                await onComplete(categories);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
                  child: const Text(
                    'Continue to My Notepad',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
