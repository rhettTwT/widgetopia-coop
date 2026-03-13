class MoodEntryModel {
  final String dateKey;
  final String moodId;
  final String note;
  final DateTime createdAt;

  MoodEntryModel({
    required this.dateKey,
    required this.moodId,
    this.note = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'dateKey': dateKey,
        'moodId': moodId,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  factory MoodEntryModel.fromJson(Map<String, dynamic> json) {
    return MoodEntryModel(
      dateKey: json['dateKey'] as String,
      moodId: json['moodId'] as String,
      note: (json['note'] as String?) ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
