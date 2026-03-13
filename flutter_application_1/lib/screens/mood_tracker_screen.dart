import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/mood_data.dart';
import '../models/mood_entry_model.dart';
import '../models/saved_widget_model.dart';
import '../services/mood_service.dart';
import '../services/saved_widgets_service.dart';
import '../utils/theme_provider.dart';
import '../widgets/ambient_background.dart';

class MoodTrackerScreen extends StatefulWidget {
  const MoodTrackerScreen({super.key});

  @override
  State<MoodTrackerScreen> createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen> {
  final TextEditingController _noteController = TextEditingController();
  List<MoodEntryModel> _entries = [];
  String? _selectedMoodId;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final entries = await MoodService.getAll();
    final today = _entryForDate(entries, DateTime.now());
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _selectedMoodId = today?.moodId;
      _noteController.text = today?.note ?? '';
      _loading = false;
    });
  }

  MoodEntryModel? _entryForDate(List<MoodEntryModel> entries, DateTime date) {
    final key = MoodService.dateKey(date);
    for (final entry in entries) {
      if (entry.dateKey == key) return entry;
    }
    return null;
  }

  MoodEntryModel? get _todayEntry => _entryForDate(_entries, DateTime.now());

  Future<void> _saveToday() async {
    if (_selectedMoodId == null || _saving) return;
    setState(() => _saving = true);

    final existing = _todayEntry;
    await MoodService.upsert(
      MoodEntryModel(
        dateKey: MoodService.dateKey(DateTime.now()),
        moodId: _selectedMoodId!,
        note: _noteController.text.trim(),
        createdAt: existing?.createdAt ?? DateTime.now(),
      ),
    );

    await _load();
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Mood saved ✨'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: moodById(_selectedMoodId).color,
      ),
    );
  }

  Future<void> _addWidget() async {
    final widget = SavedWidgetModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'mood',
      title: 'Mood Tracker',
      config: {},
      createdAt: DateTime.now(),
    );
    await SavedWidgetsService.save(widget);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Widget added! ✨'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: moodById(_selectedMoodId).color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeProvider.colorsOf(context);
    final selectedMood = moodById(_selectedMoodId);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: c.primary))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mood Tracker',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: c.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Track how you feel and notice the patterns.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: c.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 52,
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: c.cardBg,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: c.shadow.withValues(alpha: 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.mood_rounded,
                            color: selectedMood.color,
                            size: 26,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _HeroMoodCard(
                      mood: _todayEntry == null ? null : selectedMood,
                      note: _todayEntry?.note ?? '',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _StatCard(
                          title: 'Entries',
                          value: '${_entries.length}',
                          color: c.primary,
                          icon: Icons.event_available_rounded,
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          title: 'Streak',
                          value: '${_currentStreak()}d',
                          color: const Color(0xFF4ECDC4),
                          icon: Icons.local_fire_department_rounded,
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          title: 'Top mood',
                          value: _topMoodLabel(),
                          color: moodById(_topMoodId()).color,
                          icon: Icons.insights_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _SectionTitle(
                      title: 'How do you feel today?',
                      subtitle: 'Choose one mood for today’s check-in.',
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: moodOptions.map((option) {
                        final selected = _selectedMoodId == option.id;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedMoodId = option.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: (MediaQuery.of(context).size.width - 44) / 2,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: selected
                                  ? option.color.withValues(alpha: 0.14)
                                  : c.cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected ? option.color : c.divider,
                                width: selected ? 1.6 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: option.color.withValues(alpha: 0.14),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(option.emoji,
                                      style: const TextStyle(fontSize: 22)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        option.label,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: c.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        option.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: c.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    _SectionTitle(
                      title: 'Add a note',
                      subtitle: 'A short reflection helps you spot trends.',
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: c.cardBg,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: c.divider),
                      ),
                      child: TextField(
                        controller: _noteController,
                        maxLines: 4,
                        style: TextStyle(color: c.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'What influenced your mood today?',
                          hintStyle: TextStyle(color: c.textMuted),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _selectedMoodId == null ? null : _saveToday,
                        icon: _saving
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: c.cardBg,
                                ),
                              )
                            : const Icon(Icons.favorite_rounded),
                        label: Text(_todayEntry == null ? 'Save today\'s mood' : 'Update today\'s mood'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedMood.color,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SectionTitle(
                      title: 'This week',
                      subtitle: 'A quick glance at your recent mood pattern.',
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: c.cardBg,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(7, (index) {
                          final date = DateTime.now().subtract(Duration(days: 6 - index));
                          final entry = _entryForDate(_entries, date);
                          final mood = moodById(entry?.moodId);
                          return _WeekMoodDot(
                            date: date,
                            mood: entry == null ? null : mood,
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SectionTitle(
                      title: 'Recent check-ins',
                      subtitle: 'Your latest mood notes live here.',
                    ),
                    const SizedBox(height: 12),
                    if (_entries.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: c.cardBg,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.auto_awesome_outlined,
                                size: 34, color: c.textSecondary),
                            const SizedBox(height: 12),
                            Text(
                              'No mood entries yet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: c.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Your first check-in will appear here.',
                              style: TextStyle(color: c.textSecondary),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._entries.take(5).map((entry) {
                        final mood = moodById(entry.moodId);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: c.cardBg,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: mood.color.withValues(alpha: 0.14),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(mood.emoji,
                                    style: const TextStyle(fontSize: 22)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          mood.label,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: c.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          DateFormat('MMM d, yyyy').format(
                                            DateTime.parse(entry.dateKey),
                                          ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: c.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (entry.note.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        entry.note,
                                        style: TextStyle(
                                          fontSize: 13,
                                          height: 1.45,
                                          color: c.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _addWidget,
            icon: const Icon(Icons.add_home_rounded),
            label: const Text('Add to Home Screen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: selectedMood.color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _currentStreak() {
    var streak = 0;
    var day = DateTime.now();
    while (_entryForDate(_entries, day) != null) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  String _topMoodId() {
    if (_entries.isEmpty) return 'okay';
    final counts = <String, int>{};
    for (final entry in _entries) {
      counts.update(entry.moodId, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  String _topMoodLabel() {
    return moodById(_topMoodId()).label;
  }
}

class _HeroMoodCard extends StatelessWidget {
  final MoodOption? mood;
  final String note;

  const _HeroMoodCard({required this.mood, required this.note});

  @override
  Widget build(BuildContext context) {
    final c = ThemeProvider.colorsOf(context);
    final displayMood = mood ?? moodById('okay');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            displayMood.color.withValues(alpha: 0.9),
            displayMood.color.withValues(alpha: 0.65),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: displayMood.color.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 74,
            height: 74,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: Text(
              mood?.emoji ?? '🌤️',
              style: const TextStyle(fontSize: 36),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mood == null ? 'No mood logged yet' : 'You feel ${displayMood.label.toLowerCase()}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  mood == null
                      ? 'Choose a mood below and start building your emotional timeline.'
                      : displayMood.description,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.white.withValues(alpha: 0.86),
                  ),
                ),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      note,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: c.isDark ? Colors.white : Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final c = ThemeProvider.colorsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: c.textSecondary),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = ThemeProvider.colorsOf(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 14),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 11, color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekMoodDot extends StatelessWidget {
  final DateTime date;
  final MoodOption? mood;

  const _WeekMoodDot({required this.date, required this.mood});

  @override
  Widget build(BuildContext context) {
    final c = ThemeProvider.colorsOf(context);
    return Column(
      children: [
        Text(
          DateFormat('E').format(date).substring(0, 1),
          style: TextStyle(fontSize: 11, color: c.textSecondary),
        ),
        const SizedBox(height: 8),
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: mood == null
                ? c.chipBg
                : mood!.color.withValues(alpha: 0.14),
            shape: BoxShape.circle,
            border: Border.all(
              color: mood == null ? c.divider : mood!.color.withValues(alpha: 0.4),
            ),
          ),
          child: Text(
            mood?.emoji ?? '·',
            style: TextStyle(
              fontSize: mood == null ? 20 : 16,
              color: mood == null ? c.textMuted : null,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          DateFormat('d').format(date),
          style: TextStyle(fontSize: 11, color: c.textSecondary),
        ),
      ],
    );
  }
}
