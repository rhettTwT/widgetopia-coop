import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_widget_model.dart';

class SavedWidgetsService {
  static const _key = "saved_widgets";

  static Future<List<SavedWidgetModel>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];

    final decoded = jsonDecode(raw) as List;
    return decoded
        .map((e) => SavedWidgetModel.fromJson(e))
        .toList();
  }

  static Future<void> save(SavedWidgetModel widget) async {
    final prefs = await SharedPreferences.getInstance();
    final widgets = await getAll();

    widgets.add(widget);

    await prefs.setString(
      _key,
      jsonEncode(widgets.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final widgets = await getAll();

    widgets.removeWhere((w) => w.id == id);

    await prefs.setString(
      _key,
      jsonEncode(widgets.map((e) => e.toJson()).toList()),
    );
  }
}
