import 'package:flutter/material.dart';

class MoodOption {
  final String id;
  final String label;
  final String emoji;
  final String description;
  final Color color;
  final IconData icon;

  const MoodOption({
    required this.id,
    required this.label,
    required this.emoji,
    required this.description,
    required this.color,
    required this.icon,
  });
}

const List<MoodOption> moodOptions = [
  MoodOption(
    id: 'awful',
    label: 'Awful',
    emoji: '😞',
    description: 'A heavy day. Be gentle with yourself.',
    color: Color(0xFF8E7DF2),
    icon: Icons.sentiment_very_dissatisfied_rounded,
  ),
  MoodOption(
    id: 'low',
    label: 'Low',
    emoji: '😕',
    description: 'A little off, but still moving.',
    color: Color(0xFF7CC6FE),
    icon: Icons.sentiment_dissatisfied_rounded,
  ),
  MoodOption(
    id: 'okay',
    label: 'Okay',
    emoji: '😌',
    description: 'Steady, calm, and balanced.',
    color: Color(0xFFFFC75F),
    icon: Icons.sentiment_neutral_rounded,
  ),
  MoodOption(
    id: 'good',
    label: 'Good',
    emoji: '😊',
    description: 'Light, positive, and productive.',
    color: Color(0xFF4ECDC4),
    icon: Icons.sentiment_satisfied_rounded,
  ),
  MoodOption(
    id: 'amazing',
    label: 'Amazing',
    emoji: '🤩',
    description: 'High energy and feeling your best.',
    color: Color(0xFFFF8FAB),
    icon: Icons.mood_rounded,
  ),
];

MoodOption moodById(String? id) {
  return moodOptions.firstWhere(
    (option) => option.id == id,
    orElse: () => moodOptions[2],
  );
}
