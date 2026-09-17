import 'dart:convert';

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'image_editor.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding.dart';

void main() {
  runApp(const NotesApp());
}

// =====================
// MODELS
// =====================

class Note {
  String id;
  String title;
  String content;
  String category;
  String folder;
  bool pinned;
  bool deleted;
  DateTime updatedAt;
  String? imageBase64;
  List<String> images;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.folder,
    this.pinned = false,
    this.deleted = false,
    required this.updatedAt,
    this.imageBase64,
    this.images = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'folder': folder,
      'pinned': pinned,
      'deleted': deleted,
      'updatedAt': updatedAt.toIso8601String(),
      'imageBase64': imageBase64,
      'images': images,
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      category: json['category'] ?? 'Personal',
      folder: json['folder'] ?? 'General',
      pinned: json['pinned'] ?? false,
      deleted: json['deleted'] ?? false,
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ??
          DateTime.now(),
      imageBase64: json['imageBase64'] as String?,
      images: json['images'] != null
          ? List<String>.from(json['images'])
          : (json['imageBase64'] != null &&
                  (json['imageBase64'] as String).isNotEmpty
              ? [json['imageBase64'] as String]
              : []),
    );
  }
}

// =====================
// APP
// =====================

class NotesApp extends StatefulWidget {
  const NotesApp({super.key});

  @override
  State<NotesApp> createState() => _NotesAppState();
}

class _NotesAppState extends State<NotesApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _checkingOnboarding = true;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _loadOnboarding();
  }

  Future<void> _loadOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _showOnboarding = Uri.base.queryParameters["reset"] == "1" || !(prefs.getBool("onboardingCompleted") ?? false);
      _checkingOnboarding = false;
    });
  }

  bool darkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'My Notepad',
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: _checkingOnboarding
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : _showOnboarding
        ? OnboardingPage(
            onComplete: (_) async {
              if (!mounted) return;
              _navigatorKey.currentState?.pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => NotesHome(
                    darkMode: darkMode,
                    onThemeChanged: (value) {
                      setState(() => darkMode = value);
                    },
                  ),
                ),
                (route) => false,
              );
            },
          )
              : NotesHome(
        darkMode: darkMode,
        onThemeChanged: (value) {
          setState(() => darkMode = value);
        },
      ),
    );
  }
}

// =====================
// HOME
// =====================

class NotesHome extends StatefulWidget {
  final bool darkMode;
  final ValueChanged<bool> onThemeChanged;

  const NotesHome({
    super.key,
    required this.darkMode,
    required this.onThemeChanged,
  });

  @override
  State<NotesHome> createState() => _NotesHomeState();
}

class _NotesHomeState extends State<NotesHome> {
  List<Note> notes = [];
  Map<String, List<String>> workspaces = {
    'Personal': ['Daily Notes', 'Ideas', 'Goals'],
  };
  String selectedCategory = 'Personal';
  List<String> get folders => workspaces[selectedCategory] ?? [];
  List<String> get allFolders => workspaces.values.expand((e) => e).toList();

  String selectedFolder = 'All';
  String searchText = '';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // =====================
  // STORAGE
  // =====================

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final notesData = prefs.getStringList('notes') ?? [];
    final workspaceJson = prefs.getString('workspaces');
    final foldersData = prefs.getStringList('folders');

    notes = notesData
        .map((e) => Note.fromJson(jsonDecode(e)))
        .toList();

    if (workspaceJson != null && workspaceJson.isNotEmpty) {
      final decoded = jsonDecode(workspaceJson) as Map<String, dynamic>;
      workspaces = decoded.map(
        (key, value) => MapEntry(key, List<String>.from(value as List)),
      );
    } else if (foldersData != null && foldersData.isNotEmpty) {
      workspaces = {'Personal': List<String>.from(foldersData)};
    }

    if (workspaces.isEmpty) {
      workspaces = {'Personal': ['Daily Notes', 'Ideas', 'Goals']};
    }

    if (!workspaces.containsKey(selectedCategory)) {
      selectedCategory = workspaces.keys.first;
    }

    setState(() {
      loading = false;
    });
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      'notes',
      notes.map((note) => jsonEncode(note.toJson())).toList(),
    );

    await prefs.setString('workspaces', jsonEncode(workspaces));
    await prefs.setStringList('folders', allFolders);
  }

  // =====================
  // FILTER
  // =====================

  List<Note> get visibleNotes {
    return notes.where((note) {
      if (note.deleted) return false;

      final folderMatch =
          (selectedFolder == 'All' || note.folder == selectedFolder) &&
          note.category == selectedCategory;

      final searchMatch =
          note.title.toLowerCase().contains(searchText.toLowerCase()) ||
          note.content.toLowerCase().contains(searchText.toLowerCase());

      return folderMatch && searchMatch;
    }).toList()
      ..sort((a, b) {
        if (a.pinned != b.pinned) {
          return a.pinned ? -1 : 1;
        }

        return b.updatedAt.compareTo(a.updatedAt);
      });
  }

  // =====================
  // NEW NOTE
  // =====================

  Future<void> createNote() async {
    final result = await Navigator.push<Note>(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditor(
          categories: workspaces.keys.toList(),
          foldersByCategory: workspaces,
        ),
      ),
    );

    if (result != null) {
      notes.add(result);
      await saveData();

      setState(() {});
    }
  }

  // =====================
  // EDIT NOTE
  // =====================

  Future<void> editNote(Note note) async {
    final result = await Navigator.push<Note>(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditor(
          note: note,
          categories: workspaces.keys.toList(),
          foldersByCategory: workspaces,
        ),
      ),
    );

    if (result != null) {
      final index = notes.indexWhere((n) => n.id == result.id);

      if (index != -1) {
        notes[index] = result;
        await saveData();
        setState(() {});
      }
    }
  }

  // =====================
  // PIN
  // =====================

  Future<void> togglePin(Note note) async {
    note.pinned = !note.pinned;
    note.updatedAt = DateTime.now();

    await saveData();
    setState(() {});
  }

  // =====================
  // DELETE
  // =====================

  Future<void> deleteNote(Note note) async {
    note.deleted = true;
    note.pinned = false;

    await saveData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Note moved to Trash"),
        ),
      );
  }

  // =====================
  // FOLDER
  // =====================

  Future<void> createFolder() async {
    final controller = TextEditingController();
    final folder = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('New folder in $selectedCategory'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Folder name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) Navigator.pop(context, name);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (folder != null && !(workspaces[selectedCategory] ?? []).contains(folder)) {
      workspaces[selectedCategory] = [
        ...(workspaces[selectedCategory] ?? []),
        folder,
      ];
      await saveData();
      setState(() {});
    }
  }

  // =====================
  // TRASH
  // =====================

  void openTrash() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrashPage(
          notes: notes,
          onChanged: () async {
            await saveData();
            setState(() {});
          },
        ),
      ),
    );
  }

  // =====================
  // UI
  // =====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          selectedCategory,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: NoteSearchDelegate(
                  notes: notes,
                  onOpen: editNote,
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Dark mode',
            icon: Icon(
              widget.darkMode
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              widget.onThemeChanged(!widget.darkMode);
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'trash') {
                openTrash();
              }

              if (value == 'folder') {
                createFolder();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'folder',
                child: ListTile(
                  leading: Icon(Icons.create_new_folder),
                  title: Text('New Folder'),
                ),
              ),
              PopupMenuItem(
                value: 'trash',
                child: ListTile(
                  leading: Icon(Icons.delete_outline),
                  title: Text('Trash'),
                ),
              ),
            ],
          ),
        ],
      ),

      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            children: [
              const DrawerHeader(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.note_alt,
                      size: 50,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'My Notepad',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('Your notes, organized.'),
                  ],
                ),
              ),

              ListTile(
                leading: const Icon(Icons.notes),
                title: const Text('All Notes'),
                selected: selectedFolder == 'All',
                onTap: () {
                  setState(() {
                    selectedFolder = 'All';
                  });
                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading: const Icon(Icons.push_pin),
                title: const Text('Pinned'),
                onTap: () {
                  Navigator.pop(context);

                  setState(() {
                    selectedFolder = 'All';
                  });
                },
              ),

              const Divider(),

              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'WORKSPACES',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

              ...workspaces.entries.map(
                (entry) => ExpansionTile(
                  leading: const Icon(Icons.workspaces_outlined),
                  title: Text(entry.key),
                  initiallyExpanded: entry.key == selectedCategory,
                  onExpansionChanged: (expanded) {
                    if (expanded) {
                      setState(() {
                        selectedCategory = entry.key;
                        selectedFolder = 'All';
                      });
                    }
                  },
                  children: [
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.folder_open_outlined, size: 20),
                      title: const Text('All folders'),
                      selected: selectedCategory == entry.key && selectedFolder == 'All',
                      onTap: () {
                        setState(() {
                          selectedCategory = entry.key;
                          selectedFolder = 'All';
                        });
                        Navigator.pop(context);
                      },
                    ),
                    ...entry.value.map(
                      (folder) => ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.only(left: 32, right: 16),
                        leading: const Icon(Icons.folder_outlined, size: 20),
                        title: Text(folder),
                        selected: selectedCategory == entry.key && selectedFolder == folder,
                        onTap: () {
                          setState(() {
                            selectedCategory = entry.key;
                            selectedFolder = folder;
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Trash'),
                onTap: () {
                  Navigator.pop(context);
                  openTrash();
                },
              ),
            ],
          ),
        ),
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    8,
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        searchText = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search notes...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchText.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  searchText = '';
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Text(
                        selectedFolder == 'All'
                            ? 'All Notes'
                            : selectedFolder,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${visibleNotes.length} notes',
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: visibleNotes.isEmpty
                      ? const EmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: visibleNotes.length,
                          itemBuilder: (context, index) {
                            final note = visibleNotes[index];

                            return NoteCard(
                              note: note,
                              onTap: () => editNote(note),
                              onPin: () => togglePin(note),
                              onDelete: () => deleteNote(note),
                            );
                          },
                        ),
                ),
              ],
            ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: createNote,
        icon: const Icon(Icons.add),
        label: const Text('New Note'),
      ),
    );
  }
}

// =====================
// NOTE CARD
// =====================

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onPin;
  final VoidCallback onDelete;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onPin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.title.isEmpty
                          ? 'Untitled Note'
                          : note.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: onPin,
                    icon: Icon(
                      note.pinned
                          ? Icons.push_pin
                          : Icons.push_pin_outlined,
                    ),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline,
                    ),
                  ),
                ],
              ),

              if (note.content.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  note.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              Row(
                children: [
                  const Icon(
                    Icons.folder_outlined,
                    size: 16,
                  ),
                  const SizedBox(width: 5),
                  Text(note.folder),
                  const Spacer(),
                  Text(
                    '${note.updatedAt.day}/${note.updatedAt.month}/${note.updatedAt.year}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================
// NOTE EDITOR
// =====================

class NoteEditor extends StatefulWidget {
  final Note? note;
  final List<String> categories;
  final Map<String, List<String>> foldersByCategory;

  const NoteEditor({
    super.key,
    this.note,
    required this.categories,
    required this.foldersByCategory,
  });

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  late TextEditingController titleController;
  late TextEditingController contentController;

  late String selectedCategory;
  late String selectedFolder;
  late bool pinned;
  XFile? selectedImage;
  Uint8List? selectedImageBytes;
  final List<Uint8List> selectedImagesBytes = [];

  @override
  void initState() {
    super.initState();

    final note = widget.note;

    titleController = TextEditingController(
      text: note?.title ?? '',
    );

    contentController = TextEditingController(
      text: note?.content ?? '',
    );

    final defaultCategory = widget.categories.isNotEmpty
        ? widget.categories.first
        : 'Personal';
    selectedCategory = note != null && widget.categories.contains(note.category)
        ? note.category
        : defaultCategory;
    final categoryFolders = widget.foldersByCategory[selectedCategory] ?? [];
    selectedFolder = note != null && categoryFolders.contains(note.folder)
        ? note.folder
        : (categoryFolders.isNotEmpty ? categoryFolders.first : 'General');

    pinned = note?.pinned ?? false;

    if (note != null && note.images.isNotEmpty) {
      selectedImagesBytes.addAll(
        note.images.map((image) => base64Decode(image)),
      );
      selectedImageBytes = selectedImagesBytes.last;
    } else if (note?.imageBase64 != null &&
        note!.imageBase64!.isNotEmpty) {
      selectedImageBytes = base64Decode(note.imageBase64!);
      selectedImagesBytes.add(selectedImageBytes!);
    }
  }

  void saveNote() {
    final old = widget.note;

    final note = Note(
      id: old?.id ??
          DateTime.now()
              .millisecondsSinceEpoch
              .toString(),
      title: titleController.text.trim(),
      content: contentController.text,
      category: selectedCategory,
      folder: selectedFolder,
      pinned: pinned,
      deleted: false,
      updatedAt: DateTime.now(),
      imageBase64: selectedImageBytes != null
          ? base64Encode(selectedImageBytes!)
          : widget.note?.imageBase64,
      images: selectedImagesBytes.isNotEmpty
          ? selectedImagesBytes.map(base64Encode).toList()
          : (widget.note?.images ?? const []),
    );

    Navigator.pop(context, note);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.note == null
              ? 'New Note'
              : 'Edit Note',
        ),
        actions: [
            IconButton(
            tooltip: 'Add Image',
            icon: const Icon(Icons.image_outlined),
            onPressed: () async {
              final picker = ImagePicker();

              final remaining = 40 - selectedImagesBytes.length;

              if (remaining <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Maximum 40 images allowed'),
                  ),
                );
                return;
              }

              final images = await picker.pickMultiImage();

              if (images.isEmpty) return;

              for (final image in images.take(remaining)) {
                final bytes = await image.readAsBytes();

                if (!mounted) return;

                final editedBytes = await Navigator.push<Uint8List>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ImageEditor(imageBytes: bytes),
                  ),
                );

                if (editedBytes != null && mounted) {
                  setState(() {
                    selectedImagesBytes.add(editedBytes);
                    selectedImage = image;
                    selectedImageBytes = editedBytes;
                  });
                }
              }

              if (images.length > remaining && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Only 40 images can be added'),
                  ),
                );
              }
            },
          ),
          IconButton(
            tooltip: 'Pin',
            onPressed: () {
              setState(() {
                pinned = !pinned;
              });
            },
            icon: Icon(
              pinned
                  ? Icons.push_pin
                  : Icons.push_pin_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Save',
            onPressed: saveNote,
            icon: const Icon(Icons.check),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                hintText: 'Title',
                border: InputBorder.none,
              ),
            ),

            Row(
              children: [
                const Icon(Icons.workspaces_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedCategory,
                    items: widget.categories
                        .map((category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedCategory = value;
                          final nextFolders = widget.foldersByCategory[value] ?? [];
                          selectedFolder = nextFolders.isNotEmpty ? nextFolders.first : 'General';
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.folder_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedFolder,
                    items: (widget.foldersByCategory[selectedCategory] ?? ['General'])
                        .map((folder) => DropdownMenuItem(
                              value: folder,
                              child: Text(folder),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => selectedFolder = value);
                    },
                  ),
                ),
              ],
            ),

            if (selectedImagesBytes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 12),
                child: SizedBox(
                  height: 250,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: selectedImagesBytes.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return SizedBox(
                        width: 230,
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                selectedImagesBytes[index],
                                height: 220,
                                width: 230,
                                fit: BoxFit.contain,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Row(
                                children: [
                                  Material(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(20),
                                    child: IconButton(
                                      tooltip: "Edit image",
                                      icon: const Icon(Icons.edit, color: Colors.white),
                                      onPressed: () async {
                                        final editedBytes = await Navigator.push<Uint8List>(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ImageEditor(imageBytes: selectedImagesBytes[index]),
                                          ),
                                        );
                                        if (editedBytes != null && mounted) {
                                          setState(() {
                                            selectedImagesBytes[index] = editedBytes;
                                            selectedImageBytes = editedBytes;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Material(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(20),
                                    child: IconButton(
                                      tooltip: "Delete image",
                                      icon: const Icon(Icons.delete_outline, color: Colors.white),
                                      onPressed: () {
                                        setState(() {
                                          selectedImagesBytes.removeAt(index);
                                          selectedImageBytes = selectedImagesBytes.isEmpty ? null : selectedImagesBytes.last;
                                          selectedImage = selectedImagesBytes.isEmpty ? null : selectedImage;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

          const Divider(),

            Expanded(
              child: TextField(
                controller: contentController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'Start writing...',
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================
// EMPTY STATE
// =====================

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_add_outlined,
              size: 80,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),
            const SizedBox(height: 20),
            const Text(
              'No notes yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your first note using the button below.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// =====================
// TRASH
// =====================

class TrashPage extends StatelessWidget {
  final List<Note> notes;
  final VoidCallback onChanged;

  const TrashPage({
    super.key,
    required this.notes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final deleted =
        notes.where((note) => note.deleted).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash'),
      ),
      body: deleted.isEmpty
          ? const Center(
              child: Text('Trash is empty'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: deleted.length,
              itemBuilder: (context, index) {
                final note = deleted[index];

                return Card(
                  child: ListTile(
                    leading:
                        const Icon(Icons.delete),
                    title: Text(
                      note.title.isEmpty
                          ? 'Untitled Note'
                          : note.title,
                    ),
                    subtitle: Text(note.folder),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'restore') {
                          note.deleted = false;
                          onChanged();
                        }

                        if (value == 'delete') {
                          notes.remove(note);
                          onChanged();
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'restore',
                          child: Text('Restore'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Delete permanently',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// =====================
// SEARCH
// =====================

class NoteSearchDelegate extends SearchDelegate<Note?> {
  final List<Note> notes;
  final Future<void> Function(Note) onOpen;

  NoteSearchDelegate({
    required this.notes,
    required this.onOpen,
  });

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = notes.where((note) {
      if (note.deleted) return false;

      return note.title
              .toLowerCase()
              .contains(query.toLowerCase()) ||
          note.content
              .toLowerCase()
              .contains(query.toLowerCase());
    }).toList();

    if (results.isEmpty) {
      return const Center(
        child: Text('No matching notes'),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final note = results[index];

        return ListTile(
          leading: const Icon(Icons.note),
          title: Text(note.title),
          subtitle: Text(
            '${note.category} / ${note.folder}\n${note.content}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () async {
            await onOpen(note);

            if (context.mounted) {
              close(context, note);
            }
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}