class SavedWidgetModel {
  final String id;
  final String type; // quote, pomodoro, notepad, calendar, habit, mood, etc.
  final String title;
  final Map<String, dynamic> config;
  final DateTime createdAt;
  final bool isPinned;
  final DateTime? pinnedAt;
  final String? note; // user-defined rename / label

  SavedWidgetModel({
    required this.id,
    required this.type,
    required this.title,
    required this.config,
    required this.createdAt,
    this.isPinned = false,
    this.pinnedAt,
    this.note,
  });

  String get displayTitle => (note != null && note!.isNotEmpty) ? note! : title;

  SavedWidgetModel copyWith({
    String? id,
    String? type,
    String? title,
    Map<String, dynamic>? config,
    DateTime? createdAt,
    bool? isPinned,
    DateTime? pinnedAt,
    String? note,
    bool clearPin = false,
    bool clearNote = false,
  }) {
    return SavedWidgetModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      config: config ?? this.config,
      createdAt: createdAt ?? this.createdAt,
      isPinned: isPinned ?? this.isPinned,
      pinnedAt: clearPin ? null : (pinnedAt ?? this.pinnedAt),
      note: clearNote ? null : (note ?? this.note),
    );
  }

  factory SavedWidgetModel.fromJson(Map<String, dynamic> json) {
    return SavedWidgetModel(
      id: json['id'],
      type: json['type'],
      title: json['title'],
      config: Map<String, dynamic>.from(json['config'] ?? {}),
      createdAt: DateTime.parse(json['createdAt']),
      isPinned: json['isPinned'] ?? false,
      pinnedAt: json['pinnedAt'] != null ? DateTime.parse(json['pinnedAt']) : null,
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'config': config,
      'createdAt': createdAt.toIso8601String(),
      'isPinned': isPinned,
      'pinnedAt': pinnedAt?.toIso8601String(),
      'note': note,
    };
  }
}
