import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:widgetopia/models/timer_preset_model.dart';

class TimerPresetService {
  static const _key = 'timer_presets';
  static const _themeKey = 'timer_theme_index';

  static Future<List<TimerPreset>> loadPresets() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key);
    if (raw == null) return _defaultPresets();
    return raw.map((e) => TimerPreset.fromMap(jsonDecode(e))).toList();
  }

  static Future<void> savePresets(List<TimerPreset> presets) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = presets.map((e) => jsonEncode(e.toMap())).toList();
    await prefs.setStringList(_key, raw);
  }

  static Future<int> loadThemeIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_themeKey) ?? 0;
  }

  static Future<void> saveThemeIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, index);
  }

  static List<TimerPreset> _defaultPresets() => [
        TimerPreset(id: 'focus', label: 'Focus', minutes: 25, icon: '🎯'),
        TimerPreset(id: 'short_break', label: 'Short Break', minutes: 5, icon: '☕'),
        TimerPreset(id: 'long_break', label: 'Long Break', minutes: 15, icon: '🌿'),
        TimerPreset(id: 'deep_work', label: 'Deep Work', minutes: 50, icon: '🧠'),
      ];
}
