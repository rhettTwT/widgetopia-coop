import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NotepadMode { note, checklist }

class NotepadWidgetPreview extends StatefulWidget {
  const NotepadWidgetPreview({super.key});

  @override
  State<NotepadWidgetPreview> createState() => _NotepadWidgetPreviewState();
}

class _NotepadWidgetPreviewState extends State<NotepadWidgetPreview>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  NotepadMode mode = NotepadMode.note;

  final TextEditingController noteController = TextEditingController();
  final TextEditingController checklistInput = TextEditingController();

  List<String> checklistItems = [];
  List<bool> checklistChecked = [];

  // ---------------- INIT ----------------

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    noteController.dispose();
    checklistInput.dispose();
    super.dispose();
  }

  // ---------------- STORAGE ----------------

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      mode = (prefs.getBool("notepad_is_checklist") ?? false)
          ? NotepadMode.checklist
          : NotepadMode.note;

      noteController.text = prefs.getString("notepad_text") ?? "";

      checklistItems = prefs.getStringList("checklist_items") ?? [];
      checklistChecked =
          prefs.getStringList("checklist_checked")?.map((e) => e == "1").toList()
              ?? List.generate(checklistItems.length, (_) => false);
    });
  }

  Future<void> _saveNote() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("notepad_text", noteController.text);
  }

  Future<void> _saveChecklist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList("checklist_items", checklistItems);
    await prefs.setStringList(
      "checklist_checked",
      checklistChecked.map((e) => e ? "1" : "0").toList(),
    );
  }

  Future<void> _saveMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      "notepad_is_checklist",
      mode == NotepadMode.checklist,
    );
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final offset = sin(_controller.value * pi * 2) * 3;
        return Transform.translate(offset: Offset(0, offset), child: child);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF6E9), Color(0xFFFFEEDB)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD7A8).withOpacity(0.6),
              blurRadius: 40,
              offset: const Offset(0, 18),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header + Mode Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  mode == NotepadMode.note ? "Notes" : "Checklist",
                  style: const TextStyle(
                    fontSize: 14,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8B7A6B),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    mode == NotepadMode.note
                        ? Icons.check_box_outlined
                        : Icons.notes_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      mode = mode == NotepadMode.note
                          ? NotepadMode.checklist
                          : NotepadMode.note;
                    });
                    _saveMode();
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // NOTE MODE
            if (mode == NotepadMode.note)
              TextField(
                controller: noteController,
                maxLines: 6,
                onChanged: (_) => _saveNote(),
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.5,
                  color: Color(0xFF2E241C),
                  fontWeight: FontWeight.w500,
                ),
                decoration: const InputDecoration(
                  hintText: "Write something...",
                  border: InputBorder.none,
                ),
              )

            // CHECKLIST MODE
            else
              Column(
                children: [
                  for (int i = 0; i < checklistItems.length; i++)
                    Row(
                      children: [
                        Checkbox(
                          value: checklistChecked[i],
                          onChanged: (v) {
                            setState(() {
                              checklistChecked[i] = v ?? false;
                            });
                            _saveChecklist();
                          },
                        ),
                        Expanded(
                          child: Text(
                            checklistItems[i],
                            style: TextStyle(
                              color: const Color(0xFF2E241C),
                              decoration: checklistChecked[i]
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            setState(() {
                              checklistItems.removeAt(i);
                              checklistChecked.removeAt(i);
                            });
                            _saveChecklist();
                          },
                        ),
                      ],
                    ),

                  // Add new item
                  TextField(
                    controller: checklistInput,
                    decoration: const InputDecoration(
                      hintText: "Add item...",
                      border: InputBorder.none,
                    ),
                    onSubmitted: (value) {
                      if (value.trim().isEmpty) return;
                      setState(() {
                        checklistItems.add(value.trim());
                        checklistChecked.add(false); // ✅ starts unchecked
                        checklistInput.clear();
                      });
                      _saveChecklist();
                    },
                  ),
                ],
              ),

            const SizedBox(height: 12),

            const Text(
              "Notepad Widget · Cozy Pack",
              style: TextStyle(fontSize: 13, color: Color(0xFF9C8A78)),
            ),
          ],
        ),
      ),
    );
  }
}
