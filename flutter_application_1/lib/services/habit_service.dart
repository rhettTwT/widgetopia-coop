import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit_model.dart';

class HabitService {
  static const _key = "habits_data";

  static Future<List<HabitModel>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List;
    return decoded.map((e) => HabitModel.fromJson(e)).toList();
  }

  static Future<void> saveAll(List<HabitModel> habits) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(habits.map((e) => e.toJson()).toList());
    await prefs.setString(_key, encoded);
  }

  static Future<void> addHabit(HabitModel habit) async {
    final habits = await getAll();
    habits.add(habit);
    await saveAll(habits);
  }

  static Future<void> updateHabit(HabitModel habit) async {
    final habits = await getAll();
    final idx = habits.indexWhere((h) => h.id == habit.id);
    if (idx != -1) {
      habits[idx] = habit;
      await saveAll(habits);
    }
  }

  static Future<void> deleteHabit(String id) async {
    final habits = await getAll();
    habits.removeWhere((h) => h.id == id);
    await saveAll(habits);
  }
}
