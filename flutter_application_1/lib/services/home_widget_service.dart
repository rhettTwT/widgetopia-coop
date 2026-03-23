import 'package:home_widget/home_widget.dart';

class HomeWidgetService {
  static const String quoteWidgetName = 'QuoteWidgetProvider';
  static const String pomodoroWidgetName = 'PomodoroWidgetProvider';
  static const String habitWidgetName = 'HabitWidgetProvider';
  static const String moodWidgetName = 'MoodWidgetProvider';
  static const String notepadWidgetName = 'NotepadWidgetProvider';

  /// Initialize home_widget (must be called early in main())
  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId('com. souvik.widgets');
  }

  /// Update the Quote Widget
  static Future<void> updateQuote(String text, String author) async {
    await HomeWidget.saveWidgetData<String>('quote_text', text);
    await HomeWidget.saveWidgetData<String>('quote_author', author);
    await HomeWidget.updateWidget(name: quoteWidgetName);
  }

  /// Update the Pomodoro Widget
  static Future<void> updatePomodoro(String status, String time) async {
    await HomeWidget.saveWidgetData<String>('pomodoro_status', status);
    await HomeWidget.saveWidgetData<String>('pomodoro_time', time);
    await HomeWidget.updateWidget(name: pomodoroWidgetName);
  }

  /// Update the Habit Tracker Widget
  static Future<void> updateHabitProgress(int completed, int total) async {
    await HomeWidget.saveWidgetData<int>('habit_completed', completed);
    await HomeWidget.saveWidgetData<int>('habit_total', total);
    await HomeWidget.updateWidget(name: habitWidgetName);
  }

  /// Update the Mood Tracker Widget
  static Future<void> updateMood(String emoji, String label) async {
    await HomeWidget.saveWidgetData<String>('mood_emoji', emoji);
    await HomeWidget.saveWidgetData<String>('mood_label', label);
    await HomeWidget.updateWidget(name: moodWidgetName);
  }

  /// Update the Notepad Widget
  static Future<void> updateNotepad(String title, String content) async {
    await HomeWidget.saveWidgetData<String>('notepad_title', title);
    await HomeWidget.saveWidgetData<String>('notepad_content', content);
    await HomeWidget.updateWidget(name: notepadWidgetName);
  }
}
