import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyNotepadApp());
}

class MyNotepadApp extends StatelessWidget {
  const MyNotepadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Notepad',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class Note {
  String id;
  String title;
  String content;
  bool pinned;
  bool favorite;
  DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    this.pinned = false,
    this.favorite = false,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'pinned': pinned,
      'favorite': favorite,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      pinned: json['pinned'] ?? false,
      favorite: json['favorite'] ?? false,
      updatedAt: DateTime.tryParse(
            json['updatedAt'] ?? '',
          ) ??
          DateTime.now(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Note> notes = [];
  bool loading = true;
  String searchText = '';

  @override
  void initState() {
    super.initState();
    loadNotes();
  }

  Future<void> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('notes');

    if (saved != null) {
      final List decoded = jsonDecode(saved);

      notes = decoded
          .map(
            (item) => Note.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    }

    sortNotes();

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> saveNotes() async {
    final prefs = await SharedPreferences.getInstance();

    final data = notes.map((note) => note.toJson()).toList();

    await prefs.setString(
      'notes',
      jsonEncode(data),
    );
  }

  void sortNotes() {
    notes.sort((a, b) {
      if (a.pinned != b.pinned) {
        return a.pinned ? -1 : 1;
      }

      return b.updatedAt.compareTo(a.updatedAt);
    });
  }

  List<Note> get filteredNotes {
    if (searchText.trim().isEmpty) {
      return notes;
    }

    final query = searchText.toLowerCase();

    return notes.where((note) {
      return note.title.toLowerCase().contains(query) ||
          note.content.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> createNote() async {
    final result = await Navigator.push<Note>(
      context,
      MaterialPageRoute(
        builder: (_) => const NoteEditorPage(),
      ),
    );

    if (result != null) {
      setState(() {
        notes.add(result);
        sortNotes();
      });

      await saveNotes();
    }
  }

  Future<void> editNote(Note note) async {
    final result = await Navigator.push<Note>(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorPage(note: note),
      ),
    );

    if (result != null) {
      setState(() {
        final index =
            notes.indexWhere((item) => item.id == result.id);

        if (index != -1) {
          notes[index] = result;
        }

        sortNotes();
      });

      await saveNotes();
    }
  }

  Future<void> deleteNote(Note note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete note?'),
          content: const Text(
            'This note will be permanently deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() {
        notes.removeWhere(
          (item) => item.id == note.id,
        );
      });

      await saveNotes();
    }
  }

  Future<void> togglePin(Note note) async {
    setState(() {
      note.pinned = !note.pinned;
      sortNotes();
    });

    await saveNotes();
  }

  Future<void> toggleFavorite(Note note) async {
    setState(() {
      note.favorite = !note.favorite;
    });

    await saveNotes();
  }

  String formatDate(DateTime date) {
    final now = DateTime.now();

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final visibleNotes = filteredNotes;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Notepad',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (notes.isNotEmpty)
            IconButton(
              tooltip: 'Favorites',
              onPressed: () {
                setState(() {
                  if (searchText == '#favorites') {
                    searchText = '';
                  } else {
                    searchText = '#favorites';
                  }
                });
              },
              icon: Icon(
                searchText == '#favorites'
                    ? Icons.star
                    : Icons.star_border,
              ),
            ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    8,
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
                              onPressed: () {
                                setState(() {
                                  searchText = '';
                                });
                              },
                              icon: const Icon(Icons.clear),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: searchText == '#favorites'
                      ? _buildFavorites()
                      : visibleNotes.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                8,
                                12,
                                100,
                              ),
                              itemCount: visibleNotes.length,
                              itemBuilder: (context, index) {
                                final note =
                                    visibleNotes[index];

                                return _buildNoteCard(note);
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_alt_outlined,
              size: 80,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),
            const SizedBox(height: 18),
            const Text(
              'No Notes Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap + to create your first note',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavorites() {
    final favorites =
        notes.where((note) => note.favorite).toList();

    if (favorites.isEmpty) {
      return const Center(
        child: Text('No favorite notes yet'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        12,
        8,
        12,
        100,
      ),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        return _buildNoteCard(favorites[index]);
      },
    );
  }

  Widget _buildNoteCard(Note note) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        leading: CircleAvatar(
          child: Icon(
            note.favorite
                ? Icons.star
                : Icons.note_outlined,
          ),
        ),
        title: Text(
          note.title.isEmpty
              ? 'Untitled Note'
              : note.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              note.content.isEmpty
                  ? 'No content'
                  : note.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 5),
            Text(
              formatDate(note.updatedAt),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall,
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              editNote(note);
            }

            if (value == 'pin') {
              togglePin(note);
            }

            if (value == 'favorite') {
              toggleFavorite(note);
            }

            if (value == 'delete') {
              deleteNote(note);
            }
          },
          itemBuilder: (context) {
            return [
              const PopupMenuItem(
                value: 'edit',
                child: Text('Edit'),
              ),
              PopupMenuItem(
                value: 'pin',
                child: Text(
                  note.pinned ? 'Unpin' : 'Pin',
                ),
              ),
              PopupMenuItem(
                value: 'favorite',
                child: Text(
                  note.favorite
                      ? 'Remove Favorite'
                      : 'Favorite',
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete'),
              ),
            ];
          },
        ),
        onTap: () => editNote(note),
      ),
    );
  }
}

class NoteEditorPage extends StatefulWidget {
  final Note? note;

  const NoteEditorPage({
    super.key,
    this.note,
  });

  @override
  State<NoteEditorPage> createState() =>
      _NoteEditorPageState();
}

class _NoteEditorPageState
    extends State<NoteEditorPage> {
  late TextEditingController titleController;
  late TextEditingController contentController;

  bool pinned = false;
  bool favorite = false;

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(
      text: widget.note?.title ?? '',
    );

    contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );

    pinned = widget.note?.pinned ?? false;
    favorite = widget.note?.favorite ?? false;
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  void saveNote() {
    final title = titleController.text.trim();
    final content = contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final note = Note(
      id: widget.note?.id ??
          DateTime.now()
              .microsecondsSinceEpoch
              .toString(),
      title: title,
      content: content,
      pinned: pinned,
      favorite: favorite,
      updatedAt: DateTime.now(),
    );

    Navigator.pop(context, note);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.note != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          editing ? 'Edit Note' : 'New Note',
        ),
        actions: [
          IconButton(
            tooltip: 'Favorite',
            onPressed: () {
              setState(() {
                favorite = !favorite;
              });
            },
            icon: Icon(
              favorite
                  ? Icons.star
                  : Icons.star_border,
            ),
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
              textInputAction:
                  TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'Title',
                border: InputBorder.none,
              ),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            Expanded(
              child: TextField(
                controller: contentController,
                maxLines: null,
                expands: true,
                textAlignVertical:
                    TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'Start writing...',
                  border: InputBorder.none,
                ),
                style: const TextStyle(
                  fontSize: 17,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}