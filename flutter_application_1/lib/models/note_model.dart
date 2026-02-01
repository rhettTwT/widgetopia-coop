//import 'dart:convert';

enum NoteType { text, checklist }

class ChecklistItem {
  String text;
  bool done;

  ChecklistItem({required this.text, this.done = false});

  Map<String, dynamic> toJson() => {
        "text": text,
        "done": done,
      };

  factory ChecklistItem.fromJson(Map<String, dynamic> json) =>
      ChecklistItem(
        text: json["text"],
        done: json["done"],
      );
}

class NoteModel {
  String id;
  String title;
  NoteType type;
  String text;
  List<ChecklistItem> checklist;

  NoteModel({
    required this.id,
    required this.title,
    required this.type,
    this.text = "",
    List<ChecklistItem>? checklist,
  }) : checklist = checklist ?? [];

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "type": type.index,
        "text": text,
        "checklist": checklist.map((e) => e.toJson()).toList(),
      };

  factory NoteModel.fromJson(Map<String, dynamic> json) => NoteModel(
        id: json["id"],
        title: json["title"],
        type: NoteType.values[json["type"]],
        text: json["text"],
        checklist: (json["checklist"] as List)
            .map((e) => ChecklistItem.fromJson(e))
            .toList(),
      );
}
