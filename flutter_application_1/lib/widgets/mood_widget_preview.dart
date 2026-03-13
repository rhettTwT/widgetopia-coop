import 'package:flutter/material.dart';

import '../data/mood_data.dart';
import '../models/mood_entry_model.dart';
import '../services/mood_service.dart';
import '../utils/theme_provider.dart';

class MoodWidgetPreview extends StatefulWidget {
  final bool interactive;

  const MoodWidgetPreview({super.key, this.interactive = true});

  @override
  State<MoodWidgetPreview> createState() => _MoodWidgetPreviewState();
}

class _MoodWidgetPreviewState extends State<MoodWidgetPreview> {
  List<MoodEntryModel> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await MoodService.getAll();
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  MoodEntryModel? _entryForDate(DateTime date) {
    final key = MoodService.dateKey(date);
    for (final entry in _entries) {
      if (entry.dateKey == key) return entry;
    }
    return null;
  }

  Future<void> _setMood(String moodId) async {
    final today = DateTime.now();
    final existing = _entryForDate(today);
    await MoodService.upsert(
      MoodEntryModel(
        dateKey: MoodService.dateKey(today),
        moodId: moodId,
        note: existing?.note ?? '',
        createdAt: existing?.createdAt ?? DateTime.now(),
      ),
    );
    await _load();
  }

  int get _loggedDays => _entries.length;

  @override
  Widget build(BuildContext context) {
    final c = ThemeProvider.colorsOf(context);
    final todayEntry = _entryForDate(DateTime.now());
    final todayMood = moodById(todayEntry?.moodId);

    if (_loading) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: CircularProgressIndicator(color: c.primary, strokeWidth: 2),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: c.shadow.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text('💛', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                'Mood Tracker',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: todayMood.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  todayEntry == null ? 'Check in' : todayMood.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: todayMood.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.chipBg,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Text(
                  todayEntry == null ? '🙂' : todayMood.emoji,
                  style: const TextStyle(fontSize: 34),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        todayEntry == null
                            ? 'How are you feeling today?'
                            : 'Today feels ${todayMood.label.toLowerCase()}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        todayEntry == null
                            ? 'Tap a mood below to log today.'
                            : todayMood.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _PreviewStat(
                value: '$_loggedDays',
                label: 'Logs',
                color: c.primary,
              ),
              const SizedBox(width: 10),
              _PreviewStat(
                value: '${_weeklyCount()}',
                label: 'This week',
                color: const Color(0xFF4ECDC4),
              ),
              const SizedBox(width: 10),
              _PreviewStat(
                value: _recentMoodLabel(),
                label: 'Latest',
                color: todayMood.color,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final date = DateTime.now().subtract(Duration(days: 6 - index));
              final entry = _entryForDate(date);
              final mood = moodById(entry?.moodId);
              final active = entry != null;
              final dayLabel = ['S', 'M', 'T', 'W', 'T', 'F', 'S'][date.weekday % 7];
              return Column(
                children: [
                  Text(
                    dayLabel,
                    style: TextStyle(fontSize: 11, color: c.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active
                          ? mood.color.withValues(alpha: 0.16)
                          : c.chipBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: active
                            ? mood.color.withValues(alpha: 0.35)
                            : c.divider,
                      ),
                    ),
                    child: Text(
                      active ? mood.emoji : '•',
                      style: TextStyle(
                        fontSize: active ? 12 : 18,
                        color: active ? null : c.textMuted,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
          if (widget.interactive) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: moodOptions.map((option) {
                final selected = todayEntry?.moodId == option.id;
                return GestureDetector(
                  onTap: () => _setMood(option.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? option.color.withValues(alpha: 0.18)
                          : c.chipBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? option.color : c.divider,
                        width: selected ? 1.6 : 1,
                      ),
                    ),
                    child: Text(option.emoji, style: const TextStyle(fontSize: 20)),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  int _weeklyCount() {
    var count = 0;
    for (var i = 0; i < 7; i++) {
      if (_entryForDate(DateTime.now().subtract(Duration(days: i))) != null) {
        count++;
      }
    }
    return count;
  }

  String _recentMoodLabel() {
    if (_entries.isEmpty) return '—';
    return moodById(_entries.first.moodId).label;
  }
}

class _PreviewStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _PreviewStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = ThemeProvider.colorsOf(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: c.chipBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
