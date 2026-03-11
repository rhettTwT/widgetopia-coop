import 'package:flutter/material.dart';

class WidgetItem {
  final String id;
  final String title;
  final String subtitle;
  final String image;
  final String tag;
  final String type; // quote, pomodoro, notepad, calendar, habit, generic
  final String creator;
  final Color creatorColor;
  final double rating;
  final String downloads;
  final Color cardColor;

  WidgetItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.tag,
    this.type = "generic",
    this.creator = "Widgetopia",
    this.creatorColor = const Color(0xFF6B4F3A),
    this.rating = 4.5,
    this.downloads = "1.0k",
    this.cardColor = const Color(0xFFFFFFFF),
  });
}
