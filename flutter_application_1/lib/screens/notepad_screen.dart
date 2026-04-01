import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note_model.dart';
import '../widgets/checklist_item_tile.dart';
import 'package:uuid/uuid.dart';
import '../services/home_widget_service.dart';

class NotepadScreen extends StatefulWidget {
  const NotepadScreen({super.key});

  @override
  State<NotepadScreen> createState() => _NotepadScreenState();
}

class _NotepadScreenState extends State<NotepadScreen> {
  final List<NoteModel> notes = [];
  final uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    loadNotes();
  }

  Future<void> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString("notes");

    if (raw != null) {
      final decoded = jsonDecode(raw) as List;
      setState(() {
        notes.clear();
        notes.addAll(decoded.map((e) => NoteModel.fromJson(e)));
      });
    }
  }

  Future<void> saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      "notes",
      jsonEncode(notes.map((e) => e.toJson()).toList()),
    );
    _updateHomeWidget();
  }

  void _updateHomeWidget() {
    if (notes.isEmpty) {
      HomeWidgetService.updateNotepad("My Notes", "Tap to add a note...", noteCount: 0);
      return;
    }
    final latest = notes.first;
    String content = "";
    String type = "TEXT";
    if (latest.type == NoteType.text) {
      content = latest.text.isNotEmpty ? latest.text : "Empty note...";
      type = "TEXT";
    } else {
      type = "LIST";
      if (latest.checklist.isEmpty) {
        content = "Empty checklist...";
      } else {
        // Format checklist items with check/uncheck symbols for the widget
        content = latest.checklist.take(5).map((e) => "${e.done ? '☑' : '☐'} ${e.text}").join("|||");
      }
    }
    HomeWidgetService.updateNotepad(
      latest.title,
      content,
      type: type,
      noteCount: notes.length,
    );
  }

  void createNote(NoteType type) {
    setState(() {
      notes.add(
        NoteModel(
          id: uuid.v4(),
          title: "New Note",
          type: type,
        ),
      );
    });
    saveNotes();
  }

  void deleteNote(NoteModel note) {
    setState(() => notes.remove(note));
    saveNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notepad"),
        actions: [
          IconButton(
            icon: const Icon(Icons.note_add),
            onPressed: () => createNote(NoteType.text),
          ),
          IconButton(
            icon: const Icon(Icons.checklist),
            onPressed: () => createNote(NoteType.checklist),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: notes.length,
        itemBuilder: (_, i) {
          final note = notes[i];
          return ListTile(
            title: Text(note.title),
            subtitle: Text(
              note.type == NoteType.text
                  ? note.text
                  : "${note.checklist.length} items",
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => deleteNote(note),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NoteEditorScreen(
                    note: note,
                    onUpdate: saveNotes,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class NoteEditorScreen extends StatefulWidget {
  final NoteModel note;
  final VoidCallback onUpdate;

  const NoteEditorScreen({
    super.key,
    required this.note,
    required this.onUpdate,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller.text = widget.note.text;
  }

  void addChecklistItem(String text) {
    setState(() {
      widget.note.checklist.add(ChecklistItem(text: text));
    });
    widget.onUpdate();
  }

  void clearCompleted() {
    setState(() {
      widget.note.checklist.removeWhere((e) => e.done);
    });
    widget.onUpdate();
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.note;

    return Scaffold(
      appBar: AppBar(
        title: Text(note.title),
        actions: note.type == NoteType.checklist
            ? [
                IconButton(
                  icon: const Icon(Icons.cleaning_services),
                  onPressed: clearCompleted,
                )
              ]
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: note.type == NoteType.text
            ? TextField(
                controller: controller,
                maxLines: null,
                decoration: const InputDecoration(border: InputBorder.none),
                onChanged: (v) {
                  note.text = v;
                  widget.onUpdate();
                },
              )
            : Column(
                children: [
                  TextField(
                    decoration:
                        const InputDecoration(hintText: "Add item"),
                    onSubmitted: addChecklistItem,
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ReorderableListView(
                      onReorder: (oldIndex, newIndex) {
                        if (newIndex > oldIndex) newIndex--;
                        setState(() {
                          final item =
                              note.checklist.removeAt(oldIndex);
                          note.checklist.insert(newIndex, item);
                        });
                        widget.onUpdate();
                      },
                      children: [
                        for (final item in note.checklist)
                          ChecklistItemTile(
                            key: ValueKey(item),
                            item: item,
                            onToggle: () {
                              setState(() => item.done = !item.done);
                              widget.onUpdate();
                            },
                            onDelete: () {
                              setState(() =>
                                  note.checklist.remove(item));
                              widget.onUpdate();
                            },
                          )
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
