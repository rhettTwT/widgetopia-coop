class HabitModel {
  String id;
  String name;
  String emoji;
  int colorIndex; // index into a predefined palette
  List<bool> targetDays; // 7 bools: Sun-Sat
  Map<String, bool> completions; // "yyyy-MM-dd" -> true
  DateTime createdAt;

  HabitModel({
    required this.id,
    required this.name,
    required this.emoji,
    this.colorIndex = 0,
    List<bool>? targetDays,
    Map<String, bool>? completions,
    DateTime? createdAt,
  })  : targetDays = targetDays ?? List.filled(7, true),
        completions = completions ?? {},
        createdAt = createdAt ?? DateTime.now();

  /// Check if today is completed
  bool get isCompletedToday {
    final key = _dateKey(DateTime.now());
    return completions[key] == true;
  }

  /// Current streak count
  int get currentStreak {
    int streak = 0;
    DateTime day = DateTime.now();
    while (true) {
      final key = _dateKey(day);
      if (completions[key] == true) {
        streak++;
        day = day.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  /// Total completions
  int get totalCompletions => completions.values.where((v) => v).length;

  /// Toggle today
  void toggleToday() {
    final key = _dateKey(DateTime.now());
    completions[key] = !(completions[key] ?? false);
  }

  /// Check in for a specific date
  void checkIn(DateTime date) {
    completions[_dateKey(date)] = true;
  }

  /// Uncheck a specific date
  void uncheck(DateTime date) {
    completions.remove(_dateKey(date));
  }

  bool isCompleted(DateTime date) {
    return completions[_dateKey(date)] == true;
  }

  static String _dateKey(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "emoji": emoji,
        "colorIndex": colorIndex,
        "targetDays": targetDays,
        "completions": completions,
        "createdAt": createdAt.toIso8601String(),
      };

  factory HabitModel.fromJson(Map<String, dynamic> json) => HabitModel(
        id: json["id"],
        name: json["name"],
        emoji: json["emoji"],
        colorIndex: json["colorIndex"] ?? 0,
        targetDays: (json["targetDays"] as List).map((e) => e as bool).toList(),
        completions: (json["completions"] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v as bool)),
        createdAt: DateTime.parse(json["createdAt"]),
      );
}
