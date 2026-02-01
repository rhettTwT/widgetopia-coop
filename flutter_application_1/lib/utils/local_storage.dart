import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  // Save quote
  static Future<void> saveQuote(String quote) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('quote_text', quote);
  }

  // Load quote
  static Future<String> loadQuote() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('quote_text') ?? "Small steps every day.";
  }

  // Save note
  static Future<void> saveNote(String note) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('note_text', note);
  }

  // Load note
  static Future<String> loadNote() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('note_text') ?? "";
  }
}
