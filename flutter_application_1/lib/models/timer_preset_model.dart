import 'dart:convert';
import 'package:flutter/material.dart';

class TimerPreset {
  final String id;
  final String label;
  final int minutes;
  final String icon;

  TimerPreset({
    required this.id,
    required this.label,
    required this.minutes,
    this.icon = '⏱️',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'minutes': minutes,
        'icon': icon,
      };

  factory TimerPreset.fromMap(Map<String, dynamic> map) => TimerPreset(
        id: map['id'] ?? '',
        label: map['label'] ?? '',
        minutes: map['minutes'] ?? 25,
        icon: map['icon'] ?? '⏱️',
      );

  String toJson() => jsonEncode(toMap());

  factory TimerPreset.fromJson(String source) =>
      TimerPreset.fromMap(jsonDecode(source));
}

class TimerTheme {
  final String name;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color background;
  final Color textColor;
  final Color cardColor;

  const TimerTheme({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.textColor,
    required this.cardColor,
  });
}

const List<TimerTheme> timerThemes = [
  TimerTheme(
    name: 'Latte',
    primary: Color(0xFFD4A574),
    secondary: Color(0xFFE8C9A0),
    accent: Color(0xFFC08552),
    background: Color(0xFFFFF8EE),
    textColor: Color(0xFF4A3728),
    cardColor: Color(0xFFFFF0DC),
  ),
  TimerTheme(
    name: 'Berry',
    primary: Color(0xFFD4728C),
    secondary: Color(0xFFE8A0B4),
    accent: Color(0xFFC05272),
    background: Color(0xFFFFF0F3),
    textColor: Color(0xFF4A2838),
    cardColor: Color(0xFFFFE0E8),
  ),
  TimerTheme(
    name: 'Matcha',
    primary: Color(0xFF74B88A),
    secondary: Color(0xFFA0D4B0),
    accent: Color(0xFF52996A),
    background: Color(0xFFF0FFF4),
    textColor: Color(0xFF28472E),
    cardColor: Color(0xFFDCF5E4),
  ),
  TimerTheme(
    name: 'Lavender',
    primary: Color(0xFF9B8EC4),
    secondary: Color(0xFFBDB2D8),
    accent: Color(0xFF7B6EA4),
    background: Color(0xFFF5F0FF),
    textColor: Color(0xFF352E4A),
    cardColor: Color(0xFFEAE0FF),
  ),
];
