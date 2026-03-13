import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/mood_entry_model.dart';

class MoodService {
  static const _key = 'mood_entries';

  static Future<List<MoodEntryModel>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    final items = decoded
        .map((entry) => MoodEntryModel.fromJson(entry as Map<String, dynamic>))
        .toList();
    items.sort((a, b) => b.dateKey.compareTo(a.dateKey));
    return items;
  }

  static Future<MoodEntryModel?> getForDate(DateTime date) async {
    final key = dateKey(date);
    final items = await getAll();
    for (final item in items) {
      if (item.dateKey == key) return item;
    }
    return null;
  }

  static Future<void> upsert(MoodEntryModel entry) async {
    final items = await getAll();
    final index = items.indexWhere((item) => item.dateKey == entry.dateKey);
    if (index == -1) {
      items.add(entry);
    } else {
      items[index] = entry;
    }
    items.sort((a, b) => b.dateKey.compareTo(a.dateKey));
    await _saveAll(items);
  }

  static Future<void> deleteForDate(DateTime date) async {
    final items = await getAll();
    items.removeWhere((item) => item.dateKey == dateKey(date));
    await _saveAll(items);
  }

  static Future<void> _saveAll(List<MoodEntryModel> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(items.map((item) => item.toJson()).toList());
    await prefs.setString(_key, raw);
  }

  static String dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
