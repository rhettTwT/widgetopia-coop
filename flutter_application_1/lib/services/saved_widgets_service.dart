import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_widget_model.dart';

class SavedWidgetsService {
  static const _key = "saved_widgets";

  /// Get all saved widgets
  static Future<List<SavedWidgetModel>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);

    if (raw == null) return [];

    final decoded = jsonDecode(raw) as List;
    return decoded.map((e) => SavedWidgetModel.fromJson(e)).toList();
  }

  /// Save a widget
  static Future<void> save(SavedWidgetModel widget) async {
    final widgets = await getAll();
    widgets.add(widget);
    await _persist(widgets);
  }

  /// Delete a widget by id
  static Future<void> delete(String id) async {
    final widgets = await getAll();
    widgets.removeWhere((w) => w.id == id);
    await _persist(widgets);
  }

  /// Save order after drag & drop
  static Future<void> saveOrder(List<SavedWidgetModel> widgets) async {
    await _persist(widgets);
  }

  static Future<void> _persist(List<SavedWidgetModel> widgets) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(widgets.map((e) => e.toJson()).toList());
    await prefs.setString(_key, encoded);
  }
}
