import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_widget_model.dart';

class SavedWidgetsService {
  static const _key = 'saved_widgets';

  /// Notifier incremented on every mutation so listeners can refresh.
  static final changeNotifier = ValueNotifier<int>(0);

  static void _notify() => changeNotifier.value++;

  // ─── Read ───

  static Future<List<SavedWidgetModel>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List;
    return decoded.map((e) => SavedWidgetModel.fromJson(e)).toList();
  }

  static Future<List<SavedWidgetModel>> getPinned() async {
    final all = await getAll();
    return all.where((w) => w.isPinned).toList()
      ..sort((a, b) => (a.pinnedAt ?? a.createdAt)
          .compareTo(b.pinnedAt ?? b.createdAt));
  }

  /// Returns true if a widget of this [type] is already saved.
  static Future<bool> isAlreadySaved(String type) async {
    final all = await getAll();
    return all.any((w) => w.type == type);
  }

  // ─── Write ───

  static Future<void> save(SavedWidgetModel widget) async {
    final widgets = await getAll();
    // Avoid duplicates by type
    if (widgets.any((w) => w.type == widget.type)) return;
    widgets.add(widget);
    await _persist(widgets);
    _notify();
  }

  static Future<void> delete(String id) async {
    final widgets = await getAll();
    widgets.removeWhere((w) => w.id == id);
    await _persist(widgets);
    _notify();
  }

  /// Remove widget by type (used when toggling off from detail screen).
  static Future<void> deleteByType(String type) async {
    final widgets = await getAll();
    widgets.removeWhere((w) => w.type == type);
    await _persist(widgets);
    _notify();
  }

  static Future<void> togglePin(String id) async {
    final widgets = await getAll();
    final idx = widgets.indexWhere((w) => w.id == id);
    if (idx == -1) return;
    final w = widgets[idx];
    widgets[idx] = w.copyWith(
      isPinned: !w.isPinned,
      pinnedAt: !w.isPinned ? DateTime.now() : null,
      clearPin: w.isPinned,
    );
    await _persist(widgets);
    _notify();
  }

  static Future<void> rename(String id, String newTitle) async {
    final widgets = await getAll();
    final idx = widgets.indexWhere((w) => w.id == id);
    if (idx == -1) return;
    widgets[idx] = widgets[idx].copyWith(note: newTitle);
    await _persist(widgets);
    _notify();
  }

  static Future<void> saveOrder(List<SavedWidgetModel> widgets) async {
    await _persist(widgets);
    _notify();
  }

  static Future<void> _persist(List<SavedWidgetModel> widgets) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(widgets.map((e) => e.toJson()).toList()));
  }
}
