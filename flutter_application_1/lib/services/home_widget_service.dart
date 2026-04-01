import 'package:home_widget/home_widget.dart';
import '../models/habit_model.dart';

class HomeWidgetService {
  static const String quoteWidgetName = 'QuoteWidgetProvider';
  static const String pomodoroWidgetName = 'PomodoroWidgetProvider';
  static const String habitWidgetName = 'HabitWidgetProvider';
  static const String moodWidgetName = 'MoodWidgetProvider';
  static const String notepadWidgetName = 'NotepadWidgetProvider';
  static const String habitHeatmapWidgetName = 'HabitHeatmapWidgetProvider';

  /// Initialize home_widget (must be called early in main())
  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId('com.souvik.widgets');
  }

  // ─── Quote Widget ───

  static Future<void> updateQuote(String text, String author, {String category = 'inspiration'}) async {
    await HomeWidget.saveWidgetData<String>('quote_text', text);
    await HomeWidget.saveWidgetData<String>('quote_author', author);
    await HomeWidget.saveWidgetData<String>('quote_category', category);
    await HomeWidget.updateWidget(name: quoteWidgetName);
  }

  // ─── Pomodoro Widget ───

  static Future<void> updatePomodoro(String status, String time, {int session = 1, int totalSessions = 4}) async {
    await HomeWidget.saveWidgetData<String>('pomodoro_status', status);
    await HomeWidget.saveWidgetData<String>('pomodoro_time', time);
    await HomeWidget.saveWidgetData<int>('pomodoro_session', session);
    await HomeWidget.saveWidgetData<int>('pomodoro_total_sessions', totalSessions);
    await HomeWidget.updateWidget(name: pomodoroWidgetName);
  }

  // ─── Habit Widget (list view) ───

  static Future<void> updateHabitProgress(int completed, int total, {required List<HabitModel> habits}) async {
    await HomeWidget.saveWidgetData<int>('habit_completed', completed);
    await HomeWidget.saveWidgetData<int>('habit_total', total);

    // Best streak
    int bestStreak = 0;
    for (final h in habits) {
      if (h.currentStreak > bestStreak) bestStreak = h.currentStreak;
    }
    await HomeWidget.saveWidgetData<int>('habit_streak', bestStreak);

    // Habit details (names, emojis, done) separated by |||
    final names = habits.map((h) => h.name).join('|||');
    final emojis = habits.map((h) => h.emoji).join('|||');
    final done = habits.map((h) => h.isCompletedToday ? '1' : '0').join('|||');
    await HomeWidget.saveWidgetData<String>('habit_names', names);
    await HomeWidget.saveWidgetData<String>('habit_emojis', emojis);
    await HomeWidget.saveWidgetData<String>('habit_done', done);

    await HomeWidget.updateWidget(name: habitWidgetName);
  }

  // ─── Habit Streak Heatmap Widget ───

  static Future<void> updateHabitHeatmap(List<HabitModel> habits) async {
    final today = DateTime.now();
    final currentWeekMonday = today.subtract(Duration(days: today.weekday - 1));
    final heatLevels = List<int>.filled(49, 0);
    final totalHabits = habits.length;

    if (totalHabits > 0) {
      for (int col = 0; col < 7; col++) {
        final weekMonday = currentWeekMonday.subtract(Duration(days: (6 - col) * 7));
        for (int row = 0; row < 7; row++) {
          final date = weekMonday.add(Duration(days: row));
          if (date.isAfter(today)) { heatLevels[col * 7 + row] = 0; continue; }
          int completedCount = 0;
          for (final habit in habits) {
            if (habit.isCompleted(date)) completedCount++;
          }
          final fraction = completedCount / totalHabits;
          int level;
          if (fraction <= 0) { level = 0; }
          else if (fraction <= 0.25) { level = 1; }
          else if (fraction <= 0.50) { level = 2; }
          else if (fraction <= 0.75) { level = 3; }
          else { level = 4; }
          heatLevels[col * 7 + row] = level;
        }
      }
    }

    int bestStreak = 0;
    for (final habit in habits) {
      if (habit.currentStreak > bestStreak) bestStreak = habit.currentStreak;
    }
    final completedToday = habits.where((h) => h.isCompletedToday).length;

    await HomeWidget.saveWidgetData<String>('heatmap_data', heatLevels.join(','));
    await HomeWidget.saveWidgetData<int>('habit_streak', bestStreak);
    await HomeWidget.saveWidgetData<int>('habit_total_count', totalHabits);
    await HomeWidget.saveWidgetData<int>('habit_completed_today', completedToday);
    await HomeWidget.updateWidget(name: habitHeatmapWidgetName);
  }

  // ─── Mood Widget ───

  static Future<void> updateMood(
    String emoji,
    String label, {
    String description = '',
    int checkinCount = 0,
    List<String>? weekColors,
  }) async {
    await HomeWidget.saveWidgetData<String>('mood_emoji', emoji);
    await HomeWidget.saveWidgetData<String>('mood_label', label);
    await HomeWidget.saveWidgetData<String>('mood_description', description);
    await HomeWidget.saveWidgetData<int>('mood_checkin_count', checkinCount);
    if (weekColors != null) {
      await HomeWidget.saveWidgetData<String>('mood_week_colors', weekColors.join(','));
    }
    await HomeWidget.updateWidget(name: moodWidgetName);
  }

  // ─── Notepad Widget ───

  static Future<void> updateNotepad(
    String title,
    String content, {
    String type = 'TEXT',
    String updated = '',
    int noteCount = 0,
  }) async {
    await HomeWidget.saveWidgetData<String>('notepad_title', title);
    await HomeWidget.saveWidgetData<String>('notepad_content', content);
    await HomeWidget.saveWidgetData<String>('notepad_type', type);
    await HomeWidget.saveWidgetData<String>('notepad_updated', updated);
    await HomeWidget.saveWidgetData<int>('notepad_count', noteCount);
    await HomeWidget.updateWidget(name: notepadWidgetName);
  }
}
