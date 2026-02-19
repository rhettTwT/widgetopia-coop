class SavedWidgetModel {
  final String id;
  final String type; // quote, pomodoro, notepad
  final String title;
  final Map<String, dynamic> config;
  final DateTime createdAt;

  SavedWidgetModel({
    required this.id,
    required this.type,
    required this.title,
    required this.config,
    required this.createdAt,
  });

  factory SavedWidgetModel.fromJson(Map<String, dynamic> json) {
    return SavedWidgetModel(
      id: json['id'],
      type: json['type'],
      title: json['title'],
      config: Map<String, dynamic>.from(json['config']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'config': config,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
